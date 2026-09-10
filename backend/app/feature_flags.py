"""Server-resolved feature flags (no client persistence).

Flags are toggled on the server via env JSON and optional per-user env
overrides. The Flutter app only reads `GET /features` into memory.
"""
from __future__ import annotations

import json
import os
from typing import Callable

from fastapi import Depends, HTTPException, status

from .owner_iot import OWNER_IOT_USER_ID, is_owner_iot_user
from .routers.auth import get_current_user_id

# Canonical flag keys (snake_case). Keep in sync with Flutter FeatureFlag.
FLAG_FRIENDS = "friends"
FLAG_WISH_LIST = "wish_list"
FLAG_FINANCES = "finances"
FLAG_PROPAGATIONS = "propagations"
FLAG_ARCHIVE = "archive"
FLAG_GENUS_CARE = "genus_care"
FLAG_SOIL_SENSORS = "soil_sensors"
FLAG_TELEGRAM_ALERTS = "telegram_alerts"
FLAG_BALCONY = "balcony"
FLAG_FERTILIZING_REMINDERS = "fertilizing_reminders"
FLAG_BULK_ACTIONS = "bulk_actions"

ALL_FLAGS: tuple[str, ...] = (
    FLAG_FRIENDS,
    FLAG_WISH_LIST,
    FLAG_FINANCES,
    FLAG_PROPAGATIONS,
    FLAG_ARCHIVE,
    FLAG_GENUS_CARE,
    FLAG_SOIL_SENSORS,
    FLAG_TELEGRAM_ALERTS,
    FLAG_BALCONY,
    FLAG_FERTILIZING_REMINDERS,
    FLAG_BULK_ACTIONS,
)

# Product hubs on by default; IoT off until allowlisted / overridden.
_DEFAULTS: dict[str, bool] = {
    FLAG_FRIENDS: True,
    FLAG_WISH_LIST: True,
    FLAG_FINANCES: True,
    FLAG_PROPAGATIONS: True,
    FLAG_ARCHIVE: True,
    FLAG_GENUS_CARE: True,
    FLAG_SOIL_SENSORS: False,
    FLAG_TELEGRAM_ALERTS: False,
    FLAG_BALCONY: False,
    FLAG_FERTILIZING_REMINDERS: True,
    FLAG_BULK_ACTIONS: True,
}

_IOT_FLAGS: frozenset[str] = frozenset(
    {FLAG_SOIL_SENSORS, FLAG_TELEGRAM_ALERTS, FLAG_BALCONY}
)


def _parse_bool_map(raw: str | None) -> dict[str, bool]:
    if not raw or not raw.strip():
        return {}
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return {}
    if not isinstance(data, dict):
        return {}
    out: dict[str, bool] = {}
    for key, value in data.items():
        if key in ALL_FLAGS:
            out[key] = bool(value)
    return out


def _parse_user_overrides(raw: str | None) -> dict[str, dict[str, bool]]:
    if not raw or not raw.strip():
        return {}
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return {}
    if not isinstance(data, dict):
        return {}
    out: dict[str, dict[str, bool]] = {}
    for user_id, flags in data.items():
        if not isinstance(user_id, str) or not isinstance(flags, dict):
            continue
        parsed = {
            key: bool(value)
            for key, value in flags.items()
            if key in ALL_FLAGS
        }
        if parsed:
            out[user_id] = parsed
    return out


def resolve_feature_flags(user_id: str) -> dict[str, bool]:
    """Resolve effective flags for a user.

    Order:
    1. Code defaults
    2. Global ``FEATURE_FLAGS`` JSON env
    3. Legacy owner IoT allowlist for unset IoT flags
    4. Per-user ``FEATURE_FLAG_USER_OVERRIDES`` JSON env
    """
    global_env = _parse_bool_map(os.environ.get("FEATURE_FLAGS"))
    user_map = _parse_user_overrides(
        os.environ.get("FEATURE_FLAG_USER_OVERRIDES")
    )
    user_env = user_map.get(user_id, {})

    result = dict(_DEFAULTS)
    result.update(global_env)

    explicit = set(global_env) | set(user_env)
    if is_owner_iot_user(user_id):
        for flag in _IOT_FLAGS:
            if flag not in explicit:
                result[flag] = True

    result.update(user_env)
    return {key: bool(result[key]) for key in ALL_FLAGS}


def is_feature_enabled(user_id: str | None, flag: str) -> bool:
    if user_id is None or flag not in ALL_FLAGS:
        return False
    return resolve_feature_flags(user_id)[flag]


def require_feature(flag: str) -> Callable:
    """FastAPI dependency factory: 403 unless the flag is on for the user."""

    def _dependency(user_id: str = Depends(get_current_user_id)) -> str:
        if not is_feature_enabled(user_id, flag):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Feature not available",
            )
        return user_id

    return _dependency


# Re-export owner id for background jobs that still attribute shared hardware.
__all__ = [
    "ALL_FLAGS",
    "FLAG_ARCHIVE",
    "FLAG_BALCONY",
    "FLAG_BULK_ACTIONS",
    "FLAG_FERTILIZING_REMINDERS",
    "FLAG_FINANCES",
    "FLAG_FRIENDS",
    "FLAG_GENUS_CARE",
    "FLAG_PROPAGATIONS",
    "FLAG_SOIL_SENSORS",
    "FLAG_TELEGRAM_ALERTS",
    "FLAG_WISH_LIST",
    "OWNER_IOT_USER_ID",
    "is_feature_enabled",
    "require_feature",
    "resolve_feature_flags",
]
