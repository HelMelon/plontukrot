"""User ban helpers (admin-only mutation; checked on login and JWT)."""
from __future__ import annotations

from fastapi import HTTPException, status

from .db import get_pool


def get_ban_reason(user_id: str | None) -> str | None:
    """Return ban reason if the user is banned, else None."""
    if not user_id:
        return None
    try:
        with get_pool().connection() as conn:
            row = conn.execute(
                "SELECT reason FROM user_bans WHERE user_id = %s",
                (user_id,),
            ).fetchone()
    except Exception:
        return None
    if row is None:
        return None
    reason = (row.get("reason") or "").strip()
    return reason or None


def raise_if_banned(user_id: str | None) -> None:
    """Raise 403 with structured detail when the user is banned."""
    reason = get_ban_reason(user_id)
    if reason is None:
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail={"code": "user_banned", "reason": reason},
    )


def user_exists(user_id: str) -> bool:
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT 1 FROM users WHERE id = %s",
            (user_id,),
        ).fetchone()
    return row is not None


def ban_user(*, user_id: str, reason: str, banned_by: str) -> None:
    # Imported lazily to avoid a circular import: owner_iot imports
    # get_current_user_id from routers.auth, which imports raise_if_banned
    # from this module.
    from .owner_iot import OWNER_IOT_USER_ID, is_owner_iot_user

    cleaned = reason.strip()
    if not cleaned:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Ban reason is required",
        )
    if is_owner_iot_user(user_id) or user_id == OWNER_IOT_USER_ID:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot ban the admin account",
        )
    if user_id == banned_by:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot ban yourself",
        )
    if not user_exists(user_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO user_bans (user_id, reason, banned_by, banned_at) "
            "VALUES (%s, %s, %s, now()) "
            "ON CONFLICT (user_id) DO UPDATE SET "
            "reason = EXCLUDED.reason, "
            "banned_by = EXCLUDED.banned_by, "
            "banned_at = now()",
            (user_id, cleaned, banned_by),
        )


def unban_user(user_id: str) -> None:
    if not user_exists(user_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    with get_pool().connection() as conn:
        conn.execute(
            "DELETE FROM user_bans WHERE user_id = %s",
            (user_id,),
        )
