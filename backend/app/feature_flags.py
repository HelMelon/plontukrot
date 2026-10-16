"""Server-resolved feature flags (no client persistence).

Flags are toggled on the server via env JSON, optional per-user env
overrides, and DB per-user overrides written by the admin panel. The Flutter
app only reads `GET /features` into memory.
"""
from __future__ import annotations

import json
import os
import re
from typing import Callable

from fastapi import Depends, HTTPException, status

from .db import get_pool, jsonb
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
FLAG_FERTILIZING_REMINDERS = "fertilizing_reminders"
FLAG_BULK_ACTIONS = "bulk_actions"
FLAG_EXPERIMENTS = "experiments"
FLAG_AI_BOTANICAL_PREFILL = "ai_botanical_prefill"

ALL_FLAGS: tuple[str, ...] = (
    FLAG_FRIENDS,
    FLAG_WISH_LIST,
    FLAG_FINANCES,
    FLAG_PROPAGATIONS,
    FLAG_ARCHIVE,
    FLAG_GENUS_CARE,
    FLAG_SOIL_SENSORS,
    FLAG_TELEGRAM_ALERTS,
    FLAG_FERTILIZING_REMINDERS,
    FLAG_BULK_ACTIONS,
    FLAG_EXPERIMENTS,
    FLAG_AI_BOTANICAL_PREFILL,
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
    FLAG_FERTILIZING_REMINDERS: True,
    FLAG_BULK_ACTIONS: True,
    FLAG_EXPERIMENTS: False,
    FLAG_AI_BOTANICAL_PREFILL: False,
}

_IOT_FLAGS: frozenset[str] = frozenset(
    {FLAG_SOIL_SENSORS, FLAG_TELEGRAM_ALERTS}
)

# One flag per room that has a Yandex device id. Not part of ALL_FLAGS:
# the key and the Russian label exist only while that sensor is stored.
ROOM_SENSOR_FLAG_PREFIX = "room_sensor_"
_ROOM_SENSOR_KEY = re.compile(r"^room_sensor_(balcony|[0-9a-fA-F]{8,64})$")
BALCONY_ROOM_ID = "balcony"
BALCONY_ROOM_LABEL = "Балкон"


def is_room_sensor_flag(key: str) -> bool:
    return _ROOM_SENSOR_KEY.fullmatch(key) is not None


def room_sensor_flag_key(room_id: str) -> str:
    return f"{ROOM_SENSOR_FLAG_PREFIX}{room_id}"


def room_sensor_flag_label(room_name: str) -> str:
    return f"Помещение с датчиком: {room_name}"


def _keep_flag(key: str) -> bool:
    return key in ALL_FLAGS or is_room_sensor_flag(key)


def list_room_sensor_flags(user_id: str) -> list[dict]:
    """Flags for rooms that currently have a sensor device id."""
    try:
        with get_pool().connection() as conn:
            rows = conn.execute(
                "SELECT s.room_id, s.device_id, r.name "
                "FROM room_sensors s "
                "LEFT JOIN rooms r "
                "ON r.id = s.room_id AND r.user_id = s.user_id "
                "WHERE s.user_id = %s "
                "ORDER BY s.created_at",
                (user_id,),
            ).fetchall()
    except Exception:
        return []
    out: list[dict] = []
    for row in rows:
        room_id = row["room_id"]
        name = (row.get("name") or "").strip()
        if room_id == BALCONY_ROOM_ID and not name:
            name = BALCONY_ROOM_LABEL
        if not name:
            continue
        key = room_sensor_flag_key(room_id)
        if not is_room_sensor_flag(key):
            continue
        out.append({
            "key": key,
            "label": room_sensor_flag_label(name),
            "room_name": name,
            "group": "room",
            "default": True,
            "room_id": room_id,
            "device_id": row["device_id"],
        })
    if not any(item["room_id"] == BALCONY_ROOM_ID for item in out):
        balcony_name = _balcony_catalog_name(user_id)
        if balcony_name:
            out.insert(0, {
                "key": room_sensor_flag_key(BALCONY_ROOM_ID),
                "label": room_sensor_flag_label(balcony_name),
                "room_name": balcony_name,
                "group": "room",
                "default": True,
                "room_id": BALCONY_ROOM_ID,
                "device_id": None,
            })
    return out


def _balcony_catalog_name(user_id: str) -> str | None:
    """Current balcony room name, or None once the user has deleted it."""
    try:
        with get_pool().connection() as conn:
            gone = conn.execute(
                "SELECT 1 FROM removed_system_rooms "
                "WHERE user_id = %s AND room_id = %s",
                (user_id, BALCONY_ROOM_ID),
            ).fetchone()
            if gone is not None:
                return None
            row = conn.execute(
                "SELECT name FROM rooms WHERE user_id = %s AND id = %s",
                (user_id, BALCONY_ROOM_ID),
            ).fetchone()
    except Exception:
        return BALCONY_ROOM_LABEL
    if row is None:
        return BALCONY_ROOM_LABEL
    name = (row.get("name") or "").strip()
    return name or BALCONY_ROOM_LABEL


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
        if _keep_flag(key):
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
            if _keep_flag(key)
        }
        if parsed:
            out[user_id] = parsed
    return out


def _normalize_flag_map(data: object) -> dict[str, bool]:
    if not isinstance(data, dict):
        return {}
    out: dict[str, bool] = {}
    for key, value in data.items():
        if _keep_flag(key):
            out[key] = bool(value)
    return out


def get_db_overrides(user_id: str) -> dict[str, bool]:
    """Load persisted per-user flag overrides written by the admin panel.

    Failures are swallowed on purpose: a flags lookup must never take
    authentication or a whole request down.
    """
    try:
        with get_pool().connection() as conn:
            row = conn.execute(
                "SELECT flags FROM user_feature_flag_overrides "
                "WHERE user_id = %s",
                (user_id,),
            ).fetchone()
    except Exception:
        return {}
    if row is None:
        return {}
    flags = row.get("flags")
    if isinstance(flags, str):
        try:
            flags = json.loads(flags)
        except json.JSONDecodeError:
            return {}
    return _normalize_flag_map(flags)


def upsert_db_overrides(user_id: str, patch: dict[str, bool]) -> dict[str, bool]:
    """Merge ``patch`` into the user's DB overrides and return the stored map."""
    normalized = _normalize_flag_map(patch)
    if not normalized:
        return get_db_overrides(user_id)

    current = get_db_overrides(user_id)
    current.update(normalized)

    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO user_feature_flag_overrides (user_id, flags, updated_at) "
            "VALUES (%s, %s::jsonb, now()) "
            "ON CONFLICT (user_id) DO UPDATE SET "
            "flags = EXCLUDED.flags, updated_at = now()",
            (user_id, jsonb(current)),
        )
    return current


def resolve_feature_flags(user_id: str) -> dict[str, bool]:
    """Resolve effective flags for a user.

    Order:
    1. Code defaults
    2. Global ``FEATURE_FLAGS`` JSON env
    3. Legacy owner IoT allowlist for unset IoT flags
    4. Per-user ``FEATURE_FLAG_USER_OVERRIDES`` JSON env
    5. DB per-user overrides written by the admin panel (highest priority)
    """
    global_env = _parse_bool_map(os.environ.get("FEATURE_FLAGS"))
    user_map = _parse_user_overrides(
        os.environ.get("FEATURE_FLAG_USER_OVERRIDES")
    )
    user_env = user_map.get(user_id, {})
    db_overrides = get_db_overrides(user_id)

    result = dict(_DEFAULTS)
    room_sensor_keys = [row["key"] for row in list_room_sensor_flags(user_id)]
    for key in room_sensor_keys:
        result[key] = True
    result.update(global_env)

    explicit = set(global_env) | set(user_env) | set(db_overrides)
    if is_owner_iot_user(user_id):
        for flag in _IOT_FLAGS:
            if flag not in explicit:
                result[flag] = True

    result.update(user_env)
    result.update(db_overrides)
    ordered = list(ALL_FLAGS) + room_sensor_keys
    return {key: bool(result[key]) for key in ordered if key in result}


def is_feature_enabled(user_id: str | None, flag: str) -> bool:
    if user_id is None or not _keep_flag(flag):
        return False
    return resolve_feature_flags(user_id).get(flag, False)


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
    "FLAG_BULK_ACTIONS",
    "FLAG_EXPERIMENTS",
    "FLAG_AI_BOTANICAL_PREFILL",
    "FLAG_FERTILIZING_REMINDERS",
    "FLAG_FINANCES",
    "FLAG_FRIENDS",
    "FLAG_GENUS_CARE",
    "FLAG_PROPAGATIONS",
    "FLAG_SOIL_SENSORS",
    "FLAG_TELEGRAM_ALERTS",
    "FLAG_WISH_LIST",
    "OWNER_IOT_USER_ID",
    "get_db_overrides",
    "is_feature_enabled",
    "require_feature",
    "resolve_feature_flags",
    "upsert_db_overrides",
]
