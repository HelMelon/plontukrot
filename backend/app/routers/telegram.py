"""Telegram linking + alert delivery.

Lets a user link their Telegram chat to their plontukrot account via a
one-time deep-link code, and lets the server push alerts (water the pot,
bring the plant inside) to every linked chat.

Flow:
  1. App calls POST /telegram/link  -> server mints a one-time code (TTL).
  2. App opens t.me/<bot>?start=<code>.
  3. Bot receives /start <code> + its own chat_id, calls POST /telegram/confirm.
  4. Server binds user_id <-> chat_id.
  5. Server pushes alerts to all linked chat_ids via the Bot API.
"""
import json
import logging
import secrets
import urllib.request
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from ..config import settings
from ..db import get_pool
from ..feature_flags import (
    FLAG_TELEGRAM_ALERTS,
    is_feature_enabled,
    require_feature,
)
from ..schemas import TelegramConfirmIn, TelegramLinkOut, TelegramStatusOut

log = logging.getLogger(__name__)

router = APIRouter(prefix="/telegram", tags=["telegram"])

# One-time link codes are valid for 10 minutes.
_LINK_CODE_TTL = timedelta(minutes=10)


def _make_code() -> str:
    """A short, human-typable one-time code."""
    return secrets.token_urlsafe(6)


@router.post("/link", response_model=TelegramLinkOut, status_code=201)
def create_link(user_id: str = Depends(require_feature(FLAG_TELEGRAM_ALERTS))):
    """Mint a one-time code the user pastes into the bot (via deep-link)."""
    code = _make_code()
    expires_at = datetime.now(timezone.utc) + _LINK_CODE_TTL
    with get_pool().connection() as conn:
        conn.execute(
            "DELETE FROM telegram_link_codes WHERE user_id = %s",
            (user_id,),
        )
        conn.execute(
            "INSERT INTO telegram_link_codes (code, user_id, expires_at) "
            "VALUES (%s, %s, %s)",
            (code, user_id, expires_at),
        )
    return TelegramLinkOut(
        code=code,
        bot_username=settings.telegram_bot_username,
        expires_at=expires_at,
    )


@router.post("/confirm", status_code=200)
def confirm_link(payload: TelegramConfirmIn):
    """Bind a chat_id to the user who owns the one-time code.

    Called by the bot (server-to-server), so it is NOT user-authenticated.
    The code itself is the bearer of trust.
    """
    code = payload.code.strip()
    chat_id = payload.chat_id.strip()
    if not code or not chat_id:
        raise HTTPException(status_code=422, detail="code and chat_id required")
    now = datetime.now(timezone.utc)
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT user_id, expires_at FROM telegram_link_codes "
            "WHERE code = %s",
            (code,),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Invalid or expired code")
        if row["expires_at"] < now:
            conn.execute("DELETE FROM telegram_link_codes WHERE code = %s", (code,))
            raise HTTPException(status_code=410, detail="Code expired")
        user_id = str(row["user_id"])
        if not is_feature_enabled(user_id, FLAG_TELEGRAM_ALERTS):
            conn.execute("DELETE FROM telegram_link_codes WHERE code = %s", (code,))
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Feature not available",
            )
        conn.execute(
            "INSERT INTO telegram_links (user_id, chat_id) VALUES (%s, %s) "
            "ON CONFLICT (user_id) DO UPDATE SET chat_id = EXCLUDED.chat_id",
            (user_id, chat_id),
        )
        conn.execute("DELETE FROM telegram_link_codes WHERE code = %s", (code,))
    return {"status": "ok", "user_id": user_id}


@router.get("/status", response_model=TelegramStatusOut)
def link_status(user_id: str = Depends(require_feature(FLAG_TELEGRAM_ALERTS))):
    """Whether the current user has linked a Telegram chat."""
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT chat_id FROM telegram_links WHERE user_id = %s",
            (user_id,),
        ).fetchone()
    if row is None:
        return TelegramStatusOut(linked=False, chat_id=None)
    return TelegramStatusOut(linked=True, chat_id=row["chat_id"])


@router.delete("/link", status_code=status.HTTP_204_NO_CONTENT)
def unlink(user_id: str = Depends(require_feature(FLAG_TELEGRAM_ALERTS))):
    """Remove the user's Telegram binding."""
    with get_pool().connection() as conn:
        conn.execute("DELETE FROM telegram_links WHERE user_id = %s", (user_id,))
    return None


# ---- Alert delivery ----

def _all_chat_ids() -> list[str]:
    """Linked Telegram chat_ids for users with telegram_alerts enabled."""
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT user_id, chat_id FROM telegram_links"
        ).fetchall()
    return [
        r["chat_id"]
        for r in rows
        if is_feature_enabled(str(r["user_id"]), FLAG_TELEGRAM_ALERTS)
    ]


def send_telegram_alert(text: str, chat_ids: list[str] | None = None) -> bool:
    """Send a message to one or more Telegram chats via the Bot API.

    If chat_ids is None, sends to every linked chat. Returns True if at
    least one message was delivered.
    """
    if not settings.telegram_token:
        log.warning("TELEGRAM_TOKEN not set; skipping alert")
        return False
    targets = chat_ids if chat_ids is not None else _all_chat_ids()
    if not targets:
        log.info("No linked Telegram chats; skipping alert")
        return False
    url = f"https://api.telegram.org/bot{settings.telegram_token}/sendMessage"
    sent = False
    for chat_id in targets:
        payload = json.dumps({
            "chat_id": chat_id,
            "text": text,
        }).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                body = json.loads(resp.read().decode("utf-8"))
            if body.get("ok"):
                sent = True
        except Exception as exc:
            log.warning("Telegram alert to %s failed: %s", chat_id, exc)
    return sent
