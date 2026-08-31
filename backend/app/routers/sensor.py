"""Роутер приёма показаний с ESP8266-датчиков влажности горшков.

ESP8266 (в deep-sleep) просыпается, меряет влажность горшков и шлёт
их сюда одним POST. Значения хранятся в таблице `sensor_readings`.
"Умение умного дома" (routers/smart_home.py) затем отдаёт Яндексу
последнее значение по каждому датчику, чтобы Алиса могла озвучить
"датчик сухой".

Защита: простой статический токен датчика (SENSOR_TOKEN в конфиге),
передаётся в заголовке `Authorization: Bearer <token>`. ESP8266 не умеет
OAuth, поэтому лёгкий общий ключ здесь уместен.
"""
import secrets
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Header, HTTPException

from ..config import settings
from ..db import get_pool
from ..routers.telegram import send_telegram_alert

router = APIRouter(prefix="/sensor", tags=["sensor"])

# Pots below this moisture % trigger a "water me" alert.
DRY_MOISTURE_THRESHOLD = 20
# No alerts between 22:00 and 08:00 (UTC+3, Belarus).
NIGHT_START_HOUR = 22
NIGHT_END_HOUR = 8


def _require_token(authorization: str | None = Header(default=None)) -> None:
    """Проверить токен датчика. Простая защита от посторонних записей."""
    expected = settings.sensor_token
    token = ""
    if authorization and authorization.startswith("Bearer "):
        token = authorization[len("Bearer "):].strip()
    if not expected or not token or not secrets.compare_digest(token, expected):
        raise HTTPException(status_code=401, detail="invalid sensor token")


@router.post("/reading")
def record_reading(
    pot: int,
    moisture: float,
    raw: int | None = None,
    name: str | None = None,
    _auth: None = Depends(_require_token),
):
    """Сохранить одно показание горшка. Возвращает 200 OK."""
    if pot < 1:
        raise HTTPException(status_code=422, detail="pot must be >= 1")
    if not (0 <= moisture <= 100):
        raise HTTPException(status_code=422, detail="moisture must be 0..100")
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO sensor_readings (pot, moisture, raw, read_at) "
            "VALUES (%s, %s, %s, now())",
            (pot, moisture, raw),
        )
        if name:
            conn.execute(
                "INSERT INTO sensor_names (pot, name, updated_at) "
                "VALUES (%s, %s, now()) "
                "ON CONFLICT (pot) DO UPDATE SET name = EXCLUDED.name, "
                "updated_at = now()",
                (pot, name),
            )
        # Previous reading for this pot (before the one just inserted).
        prev = conn.execute(
            "SELECT moisture FROM sensor_readings WHERE pot = %s "
            "AND read_at < now() ORDER BY read_at DESC LIMIT 1",
            (pot,),
        ).fetchone()
    _maybe_alert_dry(pot, moisture, name, prev)
    return {"ok": True, "pot": pot}


def _is_night(now: datetime | None = None) -> bool:
    """True between 22:00 and 08:00 (UTC+3, Belarus)."""
    now = now or datetime.now(timezone.utc)
    hour = (now.hour + 3) % 24  # UTC+3
    return hour >= NIGHT_START_HOUR or hour < NIGHT_END_HOUR


def _maybe_alert_dry(pot: int, moisture: float, name: str | None,
                     prev) -> None:
    """Send a "water me" alert when a pot crosses below the dry threshold.

    Alerts only on the transition (previous reading was >= threshold), so a
    dry pot isn't re-alerted every 6 hours. Silent at night.
    """
    if moisture >= DRY_MOISTURE_THRESHOLD:
        return
    if _is_night():
        return
    if prev is not None and prev["moisture"] < DRY_MOISTURE_THRESHOLD:
        return  # already alerted for this dry spell
    pot_name = (name or "").strip() or f"Датчик {pot}"
    text = (
        f"💧 {pot_name} — ПОРА ПОЛИТЬ!\n"
        f"Влажность: {moisture:.0f}%"
    )
    send_telegram_alert(text)


@router.get("/latest")
def latest_readings(_auth: None = Depends(_require_token)):
    """Последнее показание по каждому горшку (для отладки и таблицы)."""
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT DISTINCT ON (pot) pot, moisture, raw, read_at "
            "FROM sensor_readings ORDER BY pot, read_at DESC"
        ).fetchall()
    return rows
