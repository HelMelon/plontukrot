"""Allowlist for hardware IoT features (sensors, Telegram, balcony).

These features depend on shared physical hardware and a single Yandex /
Telegram setup. Until per-user hardware is ready, only the collection
owner may use the related API and UI.
"""
from fastapi import Depends, HTTPException, status

from .routers.auth import get_current_user_id

OWNER_IOT_USER_ID = "6c5e9eaf-d146-451f-8936-2e02d8d720bd"


def is_owner_iot_user(user_id: str | None) -> bool:
    return user_id is not None and user_id == OWNER_IOT_USER_ID


def require_owner_iot_user(
    user_id: str = Depends(get_current_user_id),
) -> str:
    """FastAPI dependency: allow only the owner IoT account."""
    if not is_owner_iot_user(user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Feature not available",
        )
    return user_id
