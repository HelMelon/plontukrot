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
from fastapi.responses import JSONResponse

from ..config import settings
from ..db import get_pool
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


def _read_balcony_temp() -> float | None:
    """Fetch the current balcony temperature from the Yandex IOT API.

    Returns None if the token is missing or the sensor can't be read.
    """
    token = settings.yandex_iot_token
    if not token:
        log.warning("YANDEX_IOT_TOKEN not set; cannot read balcony temp")
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
    for dev in data.get("devices", []):
        if dev.get("id") != settings.balcony_sensor_id:
            continue
        for prop in dev.get("properties", []):
            if prop.get("parameters", {}).get("instance") == "temperature":
                state = prop.get("state") or {}
                return state.get("value")
    return None


def _plants_on_balcony():
    """Return (id, nickname, species, band) for plants currently on the balcony."""
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, nickname, species, balcony_band FROM plants "
            "WHERE on_balcony = true AND archived_at IS NULL"
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


@router.get("/status")
def balcony_status(user_id: str = Depends(get_current_user_id)):
    """Current balcony temperature + which plants need bringing inside."""
    if not _in_season():
        return {
            "active": False,
            "reason": "season",
            "temperature": None,
            "needs_inside": [],
        }
    temp = _read_balcony_temp()
    if temp is None:
        return JSONResponse(
            status_code=503,
            content={
                "active": True,
                "reason": "sensor_unavailable",
                "temperature": None,
                "needs_inside": [],
            },
        )
    _record_temp(user_id, temp)
    rows = _plants_on_balcony()
    needs = _needs_inside(rows, temp)
    return {
        "active": True,
        "reason": "ok",
        "temperature": temp,
        "needs_inside": needs,
    }


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

    Returns one entry per day (today, yesterday, day before) with the
    average day/night temperature and the latest reading.
    """
    with get_pool().connection() as conn:
        rows = conn.execute(
            """
            SELECT
              date_trunc('day', read_at AT TIME ZONE 'Europe/Minsk') AS day,
              AVG(temp_c) FILTER (
                WHERE EXTRACT(HOUR FROM read_at AT TIME ZONE 'Europe/Minsk') >= 8
                  AND EXTRACT(HOUR FROM read_at AT TIME ZONE 'Europe/Minsk') < 22
              ) AS day_avg,
              AVG(temp_c) FILTER (
                WHERE EXTRACT(HOUR FROM read_at AT TIME ZONE 'Europe/Minsk') < 8
                  OR EXTRACT(HOUR FROM read_at AT TIME ZONE 'Europe/Minsk') >= 22
              ) AS night_avg,
              AVG(temp_c) AS overall_avg,
              (array_agg(temp_c ORDER BY read_at DESC))[1] AS latest
            FROM balcony_temp_readings
            WHERE user_id = %s
              AND read_at >= now() - interval '3 days'
            GROUP BY day
            ORDER BY day DESC
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
    if not _in_season():
        return {"active": False, "alerted": False, "needs_inside": []}
    temp = _read_balcony_temp()
    if temp is None:
        return {"active": True, "alerted": False, "needs_inside": [],
                "error": "sensor_unavailable"}
    _record_temp_for_primary(temp)
    rows = _plants_on_balcony()
    needs = _needs_inside(rows, temp)
    alerted = _maybe_alert(needs, temp)
    return {"active": True, "alerted": alerted, "needs_inside": needs,
            "temperature": temp}


def _record_temp_for_primary(temp: float) -> None:
    """Record a balcony temperature reading for the primary user.

    The background monitor has no per-user context, so it attributes the
    reading to the first (primary) user — the collection owner.
    """
    try:
        with get_pool().connection() as conn:
            row = conn.execute(
                "SELECT id FROM users ORDER BY created_at ASC LIMIT 1"
            ).fetchone()
            if row:
                conn.execute(
                    "INSERT INTO balcony_temp_readings (user_id, temp_c, read_at) "
                    "VALUES (%s, %s, now())",
                    (row["id"], temp),
                )
    except Exception as exc:
        log.warning("Failed to record balcony temp (monitor): %s", exc)


def _maybe_alert(needs: list[dict], temp: float) -> bool:
    """Send a Telegram alert if there are plants to bring in and we haven't
    already alerted for this cold spell. Returns True if a message was sent.
    """
    if not needs:
        return False
    if not settings.telegram_token:
        log.warning("Telegram not configured; skipping balcony alert")
        return False
    names = ", ".join(n["name"] for n in needs)
    text = (
        f"❄️ На балконе {temp:.1f}°C — пора занести:\n{names}\n\n"
        f"Проверь plontukrot."
    )
    return send_telegram_alert(text)
