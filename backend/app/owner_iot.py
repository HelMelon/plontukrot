"""Allowlist for hardware IoT owner account.

Used by [feature_flags.resolve_feature_flags] so soil/telegram/balcony stay
on for the collection owner until multi-tenant hardware is ready. Prefer
`require_feature(...)` / `is_feature_enabled(...)` in routers.
"""
from fastapi import Depends, HTTPException, status

from .routers.auth import get_current_user_id

OWNER_IOT_USER_ID = "6c5e9eaf-d146-451f-8936-2e02d8d720bd"


def is_owner_iot_user(user_id: str | None) -> bool:
    return user_id is not None and user_id == OWNER_IOT_USER_ID


def require_owner_iot_user(
    user_id: str = Depends(get_current_user_id),
) -> str:
    """Deprecated: use feature_flags.require_feature instead."""
    if not is_owner_iot_user(user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Feature not available",
        )
    return user_id
