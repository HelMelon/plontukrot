"""Роутер приёма показаний с ESP8266-датчиков влажности горшков.

ESP8266 (в deep-sleep) просыпается, меряет влажность горшков и шлёт
их сюда одним POST. Значения хранятся в таблице `sensor_readings`.
"Умение умного дома" (routers/smart_home.py) затем отдаёт Яндексу
последнее значение по каждому горшку, чтобы Алиса могла озвучить
"горшок сухой".

Защита: простой статический токен датчика (SENSOR_TOKEN в конфиге),
передаётся в заголовке `Authorization: Bearer <token>`. ESP8266 не умеет
OAuth, поэтому лёгкий общий ключ здесь уместен.
"""
import secrets

from fastapi import APIRouter, Depends, Header, HTTPException

from ..config import settings
from ..db import get_pool

router = APIRouter(prefix="/sensor", tags=["sensor"])


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
    return {"ok": True, "pot": pot}


@router.get("/latest")
def latest_readings(_auth: None = Depends(_require_token)):
    """Последнее показание по каждому горшку (для отладки и таблицы)."""
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT DISTINCT ON (pot) pot, moisture, raw, read_at "
            "FROM sensor_readings ORDER BY pot, read_at DESC"
        ).fetchall()
    return rows
