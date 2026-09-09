"""Feature-flag endpoints + owner admin for other users / bans / deletions."""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from ..feature_flags import (
    ALL_FLAGS,
    require_feature_flags_admin,
    resolve_feature_flags,
    upsert_db_overrides,
)
from ..routers.auth import get_current_user_id
from ..user_bans import ban_user, get_ban_reason, unban_user, user_exists
from ..user_deletions import (
    get_deletion,
    list_archived_users,
    purge_expired,
    restore_user,
    soft_delete_user,
)

router = APIRouter(prefix="/features", tags=["features"])


class BanRequest(BaseModel):
    reason: str = Field(min_length=1)


class DeleteRequest(BaseModel):
    reason: str = Field(min_length=1)


def _validate_flag_patch(body: dict) -> dict[str, bool]:
    if not isinstance(body, dict) or not body:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Expected a non-empty flag map",
        )
    unknown = [key for key in body if key not in ALL_FLAGS]
    if unknown:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Unknown feature flags: {', '.join(sorted(unknown))}",
        )
    return {key: bool(value) for key, value in body.items()}


def _deletion_fields(user_id: str) -> dict:
    row = get_deletion(user_id)
    if row is None:
        return {
            "deleted": False,
            "delete_reason": None,
            "deleted_at": None,
        }
    deleted_at = row.get("deleted_at")
    return {
        "deleted": True,
        "delete_reason": (row.get("reason") or "").strip() or None,
        "deleted_at": (
            deleted_at.isoformat()
            if hasattr(deleted_at, "isoformat")
            else deleted_at
        ),
    }


def _admin_user_payload(user_id: str) -> dict:
    reason = get_ban_reason(user_id)
    return {
        "user_id": user_id,
        "flags": resolve_feature_flags(user_id),
        "banned": reason is not None,
        "ban_reason": reason,
        **_deletion_fields(user_id),
    }


@router.get("")
def get_features(user_id: str = Depends(get_current_user_id)):
    """Return effective feature flags for the authenticated user.

    Source of truth is the server (defaults + env + DB overrides). Clients
    must not persist these values locally.
    """
    return resolve_feature_flags(user_id)


@router.patch("")
def patch_features(
    body: dict[str, bool],
    user_id: str = Depends(require_feature_flags_admin),
):
    """Merge personal flag overrides for the owner account only."""
    patch = _validate_flag_patch(body)
    upsert_db_overrides(user_id, patch)
    return resolve_feature_flags(user_id)


@router.get("/admin/users")
def admin_list_users(_: str = Depends(require_feature_flags_admin)):
    """List active (non-archived) users with ban status (owner admin)."""
    from ..db import get_pool
    from ..user_deletions import deleted_user_ids

    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, email, name, created_at FROM users "
            "ORDER BY created_at ASC"
        ).fetchall()
        try:
            ban_rows = conn.execute(
                "SELECT user_id, reason FROM user_bans"
            ).fetchall()
        except Exception:
            ban_rows = []
        deleted_ids = deleted_user_ids(conn)
    bans = {
        str(r["user_id"]): (r.get("reason") or "").strip() or None
        for r in ban_rows
    }
    return [
        {
            "user_id": str(r["id"]),
            "email": r.get("email"),
            "name": r.get("name"),
            "banned": str(r["id"]) in bans,
            "ban_reason": bans.get(str(r["id"])),
            "deleted": False,
            "delete_reason": None,
            "deleted_at": None,
        }
        for r in rows
        if str(r["id"]) not in deleted_ids
    ]


@router.get("/admin/users/archived")
def admin_list_archived_users(_: str = Depends(require_feature_flags_admin)):
    """List soft-deleted users still within the retention window."""
    purge_expired()
    return list_archived_users()


@router.get("/admin/users/{target_user_id}")
def admin_get_user_features(
    target_user_id: str,
    _: str = Depends(require_feature_flags_admin),
):
    """Effective flags + ban/delete status for any user (owner admin)."""
    target = target_user_id.strip()
    if not user_exists(target):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return _admin_user_payload(target)


@router.patch("/admin/users/{target_user_id}")
def admin_patch_user_features(
    target_user_id: str,
    body: dict[str, bool],
    _: str = Depends(require_feature_flags_admin),
):
    """Merge DB flag overrides for a target user (owner admin)."""
    target = target_user_id.strip()
    if not user_exists(target):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    patch = _validate_flag_patch(body)
    upsert_db_overrides(target, patch)
    return _admin_user_payload(target)


@router.post("/admin/users/{target_user_id}/ban", status_code=200)
def admin_ban_user(
    target_user_id: str,
    payload: BanRequest,
    admin_id: str = Depends(require_feature_flags_admin),
):
    """Ban a user so they cannot log in."""
    target = target_user_id.strip()
    ban_user(user_id=target, reason=payload.reason, banned_by=admin_id)
    return {
        "user_id": target,
        "banned": True,
        "ban_reason": payload.reason.strip(),
    }


@router.delete("/admin/users/{target_user_id}/ban", status_code=200)
def admin_unban_user(
    target_user_id: str,
    _: str = Depends(require_feature_flags_admin),
):
    """Remove a user ban."""
    target = target_user_id.strip()
    unban_user(target)
    return {"user_id": target, "banned": False, "ban_reason": None}


@router.post("/admin/users/{target_user_id}/delete", status_code=200)
def admin_soft_delete_user(
    target_user_id: str,
    payload: DeleteRequest,
    admin_id: str = Depends(require_feature_flags_admin),
):
    """Soft-delete a user into the 90-day archive."""
    purge_expired()
    target = target_user_id.strip()
    soft_delete_user(
        user_id=target,
        reason=payload.reason,
        deleted_by=admin_id,
    )
    return _admin_user_payload(target)


@router.delete("/admin/users/{target_user_id}/delete", status_code=200)
def admin_restore_user(
    target_user_id: str,
    _: str = Depends(require_feature_flags_admin),
):
    """Restore a soft-deleted user from the archive."""
    purge_expired()
    target = target_user_id.strip()
    restore_user(target)
    return _admin_user_payload(target)
