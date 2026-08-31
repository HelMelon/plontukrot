"""Умение «Умного дома Яндекса» для plontukrot.

Позволяет Алисе видеть влажность датчиков (сенсоры, которые ESP8266
шлёт в /sensor/reading) и строить сценарии вида «когда датчик сухой →
Алиса скажет "полей растение"».

Протокол УДЯ (сторона провайдера):
  1. Пользователь жмёт «Подключить устройство» в приложении Яндекса
     -> Яндес открывает наш /oauth/authorize (логин + подтверждение).
  2. После подтверждения мы выдаём code и перенаправляем на redirect_uri
     Яндекса.
  3. Яндес в фоне шлёт POST /oauth/token (grant_type=authorization_code)
     и получает access_token.
  4. Яндес дергает наши /v1.0/user/devices, /query, /action с
     Authorization: Bearer <access_token>.

Для домашнего одно-пользовательского сценария токены храним в памяти.
Устройство (датчик) моделируем как devices.types.humidity_sensor
(влажность 0..100%) — Яндес умеет строить по нему сценарии.

Важно: Яндес требует HTTPS с доменом, поэтому этот роутер заработает
полноценно только после настройки туннеля/домена (шаг 2 в плане).
"""
import secrets
import uuid

from fastapi import APIRouter, Depends, Form, Header, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse

from ..config import settings
from ..db import get_pool

router = APIRouter(prefix="", tags=["smart-home"])

# ---------------------------------------------------------------------------
# OAuth2 (упрощённый, для одного пользователя)
# ---------------------------------------------------------------------------

# В реальном УДЯ от Яндекса приходят клиентские id/secret, выданные при
# регистрации умения. Вставляем из конфига (см. YANDEX_CLIENT_ID/SECRET).
# Access-токен фиксированный (YANDEX_ACCESS_TOKEN) и переживает рестарты,
# иначе Яндекс получал бы 401 после каждого перезапуска сервиса.
_pending_codes: dict[str, str] = {}   # code -> user_id

CLIENT_ID = settings.yandex_client_id
CLIENT_SECRET = settings.yandex_client_secret


def _issue_token(user_id: str) -> str:
    """Выдаёт фиксированный access_token (или создаёт, если пустой)."""
    token = settings.yandex_access_token
    if not token:
        token = secrets.token_urlsafe(32)
    return token


@router.get("/oauth/authorize")
def authorize(
    response_type: str = Query(...),
    client_id: str = Query(...),
    redirect_uri: str = Query(...),
    state: str = Query(""),
):
    """Страница авторизации: логин уже не нужен, т.к. вход происходит в
    основном приложении. Для простоты сразу выдаём code после «согласия»."""
    if response_type != "code":
        raise HTTPException(400, "unsupported response_type")
    if client_id != CLIENT_ID:
        raise HTTPException(400, "unknown client")
    code = secrets.token_urlsafe(24)
    # Связываем код с владельцем. В single-user схеме берём первого
    # пользователя из базы (хозяин коллекции). Заменить на id текущего
    # пользователя, когда добавится полноценная сессия.
    owner_id = _primary_user_id()
    _pending_codes[code] = owner_id
    url = redirect_uri + (
        ("&" if "?" in redirect_uri else "?")
        + f"code={code}&state={state}"
    )
    return RedirectResponse(url)


@router.post("/oauth/token")
def oauth_token(
    grant_type: str = Form(...),
    code: str = Form(""),
    refresh_token: str = Form(""),
    client_id: str = Form(...),
    client_secret: str = Form(...),
):
    """Обмен кода на access_token (и refresh_token)."""
    if client_id != CLIENT_ID or client_secret != CLIENT_SECRET:
        raise HTTPException(401, "invalid client")
    if grant_type == "authorization_code":
        user_id = _pending_codes.pop(code, None)
        if not user_id:
            raise HTTPException(400, "invalid code")
        token = _issue_token(user_id)
        return {
            "access_token": token,
            "token_type": "bearer",
            "expires_in": 31536000,  # год
            "refresh_token": secrets.token_urlsafe(24),
        }
    if grant_type == "refresh_token":
        token = _issue_token(_primary_user_id())
        return {
            "access_token": token,
            "token_type": "bearer",
            "expires_in": 31536000,
            "refresh_token": secrets.token_urlsafe(24),
        }
    raise HTTPException(400, "unsupported grant_type")


def _require_user(authorization: str | None = Header(default=None)) -> str:
    token = ""
    if authorization and authorization.startswith("Bearer "):
        token = authorization[len("Bearer "):].strip()
    if not token or not secrets.compare_digest(token, _issue_token("")):
        raise HTTPException(401, "unauthorized")
    return _primary_user_id()


def _primary_user_id() -> str:
    """Возвращает ID главного пользователя (первого в БД)."""
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT id FROM users ORDER BY created_at ASC LIMIT 1"
        ).fetchone()
    return row["id"] if row else ""


# ---------------------------------------------------------------------------
# Устройства
# ---------------------------------------------------------------------------

@router.get("/v1.0")
@router.head("/v1.0")
def smart_home_root():
    """Проверка доступности бэкенда (Яндекс шлёт HEAD/GET на /v1.0)."""
    return {"status": "ok"}


@router.post("/v1.0/user/unlink")
def user_unlink(user_id: str = Depends(_require_user)):
    """Отвязка аккаунта. Просто подтверждаем успех."""
    return {"request_id": str(uuid.uuid4()), "payload": {}}


# Горшки -> устройства УДЯ. Имена берутся из БД (sensor_names), куда их
# присылает ESP8266 вместе с влажностью. Переименовал в Telegram -> и в Алисе.
_POT_IDS = [
    {"pot": 1, "id": "pot-1"},
    {"pot": 2, "id": "pot-2"},
    {"pot": 3, "id": "pot-3"},
]


def _pot_name(pot: int) -> str:
    """Имя датчика из БД (или дефолт, если датчик ещё не присылал)."""
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT name FROM sensor_names WHERE pot=%s", (pot,)
        ).fetchone()
    return row["name"] if row else f"Датчик влажности горшка {pot}"


def _device_out(dev: dict) -> dict:
    return {
        "id": dev["id"],
        "name": _pot_name(dev["pot"]),
        "type": "devices.types.sensor",
        "capabilities": [],
        "properties": [
            {
                "type": "devices.properties.float",
                "retrievable": True,
                "reportable": False,
                "parameters": {
                    "instance": "humidity",
                    "unit": "unit.percent",
                },
            }
        ],
        "device_info": {
            "manufacturer": "plontukrot",
            "model": "ESP8266 moisture sensor",
            "hw_version": "1.0",
            "sw_version": "1.0",
        },
    }


@router.get("/v1.0/user/devices")
def get_devices(user_id: str = Depends(_require_user)):
    return {
        "request_id": str(uuid.uuid4()),
        "payload": {
            "user_id": user_id,
            "devices": [_device_out(_) for _ in _POT_IDS],
        },
    }


def _latest_moisture(pot: int) -> float | None:
    """Последняя влажность горшка (None, если ещё нет показаний)."""
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT moisture FROM sensor_readings WHERE pot=%s "
            "ORDER BY read_at DESC LIMIT 1",
            (pot,),
        ).fetchone()
    return row["moisture"] if row else None


@router.post("/v1.0/user/devices/query")
def query_devices(payload: dict, user_id: str = Depends(_require_user)):
    devices = payload.get("devices", [])
    items = []
    for d in devices:
        dev_id = d.get("id")
        dev = next((p for p in _POT_IDS if p["id"] == dev_id), None)
        if not dev:
            items.append({"id": dev_id, "error_code": "DEVICE_NOT_FOUND"})
            continue
        m = _latest_moisture(dev["pot"])
        props = []
        if m is not None:
            props.append({
                "type": "devices.properties.float",
                "state": {"instance": "humidity", "value": int(round(m))},
            })
        items.append({"id": dev_id, "capabilities": [], "properties": props})
    return {"request_id": str(uuid.uuid4()), "payload": {"devices": items}}


@router.post("/v1.0/user/devices/action")
def action_devices(payload: dict, user_id: str = Depends(_require_user)):
    # Сенсоры влажности не имеют исполняемых команд; отвечаем успешно.
    devices = payload.get("devices", [])
    items = [
        {"id": d.get("id"), "capabilities": [], "status": "DONE"}
        for d in devices
    ]
    return {"request_id": str(uuid.uuid4()), "payload": {"devices": items}}
