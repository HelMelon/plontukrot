"""Balcony wintering monitor.

Reads the user's Yandex Smart Home climate sensor (balcony temperature),
compares it against each plant's cold-tolerance band, and reports which
plants marked "on the balcony" need to be brought inside.

Active window: 1 August .. 30 April. In summer the balcony is a death trap
(full sun, no shade) so the feature is intentionally disabled.

Temperature bands (min °C the plant survives):
  0 = frost-hardy   (-20°C)  e.g. Hedera helix
  1 = cold-hardy    ( -5°C)  e.g. Cycas revoluta, Oxalis triangularis
  2 = cool          ( +4°C)  e.g. Dichondra argentea
  3 = moderate      (+10°C)  most tropical houseplants
  4 = warm          (+15°C)  e.g. Anthurium
"""
import json
import logging
import urllib.request
from datetime import datetime, timezone

from fastapi import APIRouter, Depends

from ..config import settings
from ..db import get_pool
from ..feature_flags import (
    OWNER_IOT_USER_ID,
    is_feature_enabled,
    room_sensor_flag_key,
)
from ..routers.auth import get_current_user_id
from ..routers.telegram import send_telegram_alert

log = logging.getLogger(__name__)

router = APIRouter(prefix="/balcony", tags=["balcony"])

# Minimum survivable temperature per band (°C).
BAND_MIN_TEMP = {
    0: -20.0,
    1: -5.0,
    2: 4.0,
    3: 10.0,
    4: 15.0,
}

# Season window: active 1 Aug .. 30 Apr (inclusive).
SEASON_START_MONTH = 8   # August
SEASON_END_MONTH = 4     # April


def _in_season(now: datetime | None = None) -> bool:
    """True when the balcony monitor is active (Aug..Apr)."""
    now = now or datetime.now(timezone.utc)
    m = now.month
    return m >= SEASON_START_MONTH or m <= SEASON_END_MONTH


def device_id_matches(stored: str, actual: str) -> bool:
    """True when both ids are the same Yandex device.

    A stored UUID matches a device id that also carries a ``:suffix``.
    """
    stored = (stored or "").strip()
    actual = (actual or "").strip()
    if not stored or not actual:
        return False
    if stored == actual:
        return True
    return stored.split(":", 1)[0] == actual.split(":", 1)[0]


def read_device_properties(device_id: str) -> list[dict] | None:
    """Climate properties of one Yandex device.

    None when the token is missing or the request fails. An empty list
    means the device was not found.
    """
    token = settings.yandex_iot_token
    if not token:
        log.warning("YANDEX_IOT_TOKEN not set; cannot read room sensor")
        return None
    url = "https://api.iot.yandex.net/v1.0/user/info"
    req = urllib.request.Request(
        url, headers={"Authorization": f"OAuth {token}"}
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except Exception as exc:
        log.warning("Failed to read Yandex IOT: %s", exc)
        return None
    device = None
    for dev in data.get("devices", []):
        if device_id_matches(device_id, str(dev.get("id") or "")):
            device = dev
            break
    if device is None:
        return []
    properties = []
    for prop in device.get("properties") or []:
        params = prop.get("parameters") or {}
        state = prop.get("state") or {}
        instance = params.get("instance") or state.get("instance")
        value = state.get("value")
        if not instance or value is None:
            continue
        properties.append({
            "instance": instance,
            "value": value,
            "unit": params.get("unit"),
        })
    return properties


def read_device_temperature(device_id: str) -> float | None:
    properties = read_device_properties(device_id)
    if not properties:
        return None
    for prop in properties:
        if prop.get("instance") == "temperature" and isinstance(
            prop.get("value"), (int, float)
        ):
            return float(prop["value"])
    return None


def _sensor_targets(user_id: str) -> list[dict]:
    """Rooms that have a device id, plus the env balcony sensor as a fallback."""
    try:
        with get_pool().connection() as conn:
            rows = conn.execute(
                "SELECT s.room_id, s.device_id, COALESCE(r.name, '') AS name "
                "FROM room_sensors s "
                "LEFT JOIN rooms r "
                "ON r.user_id = s.user_id AND r.id = s.room_id "
                "WHERE s.user_id = %s",
                (user_id,),
            ).fetchall()
    except Exception as exc:
        log.warning("Failed to list room sensors: %s", exc)
        rows = []
    targets = []
    for row in rows:
        device_id = (row["device_id"] or "").strip()
        if not device_id:
            continue
        if not is_feature_enabled(user_id, room_sensor_flag_key(row["room_id"])):
            continue
        name = (row["name"] or "").strip() or row["room_id"]
        targets.append({
            "room_id": row["room_id"],
            "device_id": device_id,
            "name": name,
        })
    if (
        settings.balcony_sensor_id
        and not any(item["room_id"] == "balcony" for item in targets)
        and is_feature_enabled(user_id, room_sensor_flag_key("balcony"))
    ):
        targets.append({
            "room_id": "balcony",
            "device_id": settings.balcony_sensor_id,
            "name": "Балкон",
        })
    return targets


def _plants_in_room(user_id: str, room_id: str):
    with get_pool().connection() as conn:
        if room_id == "balcony":
            rows = conn.execute(
                "SELECT id, nickname, species, balcony_band FROM plants "
                "WHERE archived_at IS NULL AND user_id = %s "
                "AND (room_id = %s OR on_balcony = true)",
                (user_id, room_id),
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT id, nickname, species, balcony_band FROM plants "
                "WHERE archived_at IS NULL AND user_id = %s AND room_id = %s",
                (user_id, room_id),
            ).fetchall()
    return rows


def _display_name(row) -> str:
    nick = (row["nickname"] or "").strip()
    if nick:
        return nick
    return (row["species"] or "").strip() or "Растение"


def _needs_inside(rows, temp: float) -> list[dict]:
    """Which balcony plants are below their band's minimum temp."""
    result = []
    for row in rows:
        band = row["balcony_band"]
        if band is None:
            continue
        min_temp = BAND_MIN_TEMP.get(band)
        if min_temp is None:
            continue
        if temp < min_temp:
            result.append({
                "plant_id": row["id"],
                "name": _display_name(row),
                "band": band,
                "min_temp": min_temp,
            })
    return result


def climate_scan(user_id: str, *, record: bool) -> dict:
    """Read every enabled room sensor and list plants below their cold band."""
    if not _in_season():
        return {
            "active": False,
            "reason": "season",
            "temperature": None,
            "needs_inside": [],
        }
    targets = _sensor_targets(user_id)
    if not targets:
        return {
            "active": False,
            "reason": "no_sensor",
            "temperature": None,
            "needs_inside": [],
        }
    needs = []
    temps = []
    for target in targets:
        temp = read_device_temperature(target["device_id"])
        if temp is None:
            continue
        temps.append(temp)
        if record and target["room_id"] == "balcony":
            _record_temp(user_id, temp)
        for item in _needs_inside(_plants_in_room(user_id, target["room_id"]), temp):
            item["room_name"] = target["name"]
            item["temperature"] = temp
            needs.append(item)
    if not temps:
        return {
            "active": True,
            "reason": "sensor_unavailable",
            "temperature": None,
            "needs_inside": [],
        }
    alert_temps = [
        item["temperature"] for item in needs
        if isinstance(item.get("temperature"), (int, float))
    ]
    return {
        "active": True,
        "reason": "ok",
        "temperature": min(alert_temps) if alert_temps else temps[0],
        "needs_inside": needs,
    }


@router.get("/status")
def balcony_status(user_id: str = Depends(get_current_user_id)):
    """Which plants are colder than their band, across rooms with a sensor."""
    return climate_scan(user_id, record=True)


def _record_temp(user_id: str, temp: float) -> None:
    """Persist a balcony temperature reading for the user's history."""
    try:
        with get_pool().connection() as conn:
            conn.execute(
                "INSERT INTO balcony_temp_readings (user_id, temp_c, read_at) "
                "VALUES (%s, %s, now())",
                (user_id, temp),
            )
    except Exception as exc:
        log.warning("Failed to record balcony temp: %s", exc)


@router.get("/history")
def balcony_history(user_id: str = Depends(get_current_user_id)):
    """Per-day balcony temperature summary for the last 3 days.

    Day average: 08:00–21:00 (local, Europe/Minsk) on that calendar day.
    Night average: 21:00 previous day – 08:00 on that day (the night that
    ended that morning). Omitted until 08:00 on that day has passed so an
    in-progress night is never shown.
    """
    with get_pool().connection() as conn:
        rows = conn.execute(
            """
            WITH local_now AS (
              SELECT (now() AT TIME ZONE 'Europe/Minsk') AS ts
            ),
            days AS (
              SELECT (date_trunc('day', ts)::date - offs) AS day
              FROM local_now, generate_series(0, 2) AS offs
            ),
            readings AS (
              SELECT
                temp_c,
                read_at AT TIME ZONE 'Europe/Minsk' AS local_ts
              FROM balcony_temp_readings, local_now
              WHERE user_id = %s
                AND read_at >= (SELECT ts FROM local_now) - interval '4 days'
            )
            SELECT
              d.day,
              (
                SELECT AVG(r.temp_c)
                FROM readings r
                WHERE r.local_ts::date = d.day
                  AND EXTRACT(HOUR FROM r.local_ts) >= 8
                  AND EXTRACT(HOUR FROM r.local_ts) < 21
              ) AS day_avg,
              CASE
                WHEN (SELECT ts FROM local_now)
                     < (d.day + time '08:00')::timestamp
                THEN NULL
                ELSE (
                  SELECT AVG(r.temp_c)
                  FROM readings r
                  WHERE (
                    (r.local_ts::date = d.day - 1
                     AND EXTRACT(HOUR FROM r.local_ts) >= 21)
                    OR (r.local_ts::date = d.day
                        AND EXTRACT(HOUR FROM r.local_ts) < 8)
                  )
                )
              END AS night_avg,
              (
                SELECT AVG(r.temp_c)
                FROM readings r
                WHERE (
                  (r.local_ts::date = d.day
                   AND EXTRACT(HOUR FROM r.local_ts) >= 8
                   AND EXTRACT(HOUR FROM r.local_ts) < 21)
                  OR (
                    (r.local_ts::date = d.day - 1
                     AND EXTRACT(HOUR FROM r.local_ts) >= 21)
                    OR (r.local_ts::date = d.day
                        AND EXTRACT(HOUR FROM r.local_ts) < 8)
                  )
                )
              ) AS overall_avg,
              (
                SELECT r.temp_c
                FROM readings r
                WHERE (
                  (r.local_ts::date = d.day
                   AND EXTRACT(HOUR FROM r.local_ts) >= 8
                   AND EXTRACT(HOUR FROM r.local_ts) < 21)
                  OR (
                    (r.local_ts::date = d.day - 1
                     AND EXTRACT(HOUR FROM r.local_ts) >= 21)
                    OR (r.local_ts::date = d.day
                        AND EXTRACT(HOUR FROM r.local_ts) < 8)
                  )
                )
                ORDER BY r.local_ts DESC
                LIMIT 1
              ) AS latest
            FROM days d
            ORDER BY d.day DESC
            """,
            (user_id,),
        ).fetchall()
    return [
        {
            "day": r["day"].date().isoformat(),
            "day_avg": round(r["day_avg"], 1) if r["day_avg"] is not None else None,
            "night_avg": round(r["night_avg"], 1) if r["night_avg"] is not None else None,
            "overall_avg": round(r["overall_avg"], 1) if r["overall_avg"] is not None else None,
            "latest": round(r["latest"], 1) if r["latest"] is not None else None,
        }
        for r in rows
    ]


def check_and_alert() -> dict:
    """Run one monitor pass. Returns a summary dict (for tests/logging).

    Called by the background scheduler. Sends a Telegram alert when a plant
    that was previously fine drops below its threshold. Also records the
    temperature into the history for the primary user so the day/night
    averages accumulate automatically.
    """
    scan = climate_scan(OWNER_IOT_USER_ID, record=True)
    if not scan.get("active"):
        return {"active": False, "alerted": False, "needs_inside": [],
                "reason": scan.get("reason")}
    needs = scan["needs_inside"]
    alerted = _maybe_alert(needs)
    return {"active": True, "alerted": alerted, "needs_inside": needs,
            "temperature": scan.get("temperature"),
            "reason": scan.get("reason")}


def _maybe_alert(needs: list[dict]) -> bool:
    """Send a Telegram alert listing plants that are below their cold band."""
    if not needs:
        return False
    if not settings.telegram_token:
        log.warning("Telegram not configured; skipping climate alert")
        return False
    lines = []
    for item in needs:
        room = (item.get("room_name") or "").strip()
        temp = item.get("temperature")
        temp_bit = (
            f" {temp:.1f}°C" if isinstance(temp, (int, float)) else ""
        )
        prefix = f"{room}{temp_bit}: " if room else ""
        lines.append(f"{prefix}{item['name']}")
    text = "❄️ Пора занести:\n" + "\n".join(lines) + "\n\nПроверь plontukrot."
    return send_telegram_alert(text)
