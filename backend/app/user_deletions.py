"""Soft-delete / archive helpers (admin-only; checked on login and JWT)."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status

from .db import get_pool

# Soft-deleted accounts are hard-purged after this retention window.
ARCHIVE_RETENTION_DAYS = 90


def get_deletion(user_id: str | None) -> dict | None:
    """Return deletion row dict if soft-deleted, else None."""
    if not user_id:
        return None
    try:
        with get_pool().connection() as conn:
            row = conn.execute(
                "SELECT user_id, reason, deleted_by, deleted_at "
                "FROM user_deletions WHERE user_id = %s",
                (user_id,),
            ).fetchone()
    except Exception:
        return None
    if row is None:
        return None
    return dict(row)


def get_delete_reason(user_id: str | None) -> str | None:
    row = get_deletion(user_id)
    if row is None:
        return None
    reason = (row.get("reason") or "").strip()
    return reason or None


def raise_if_deleted(user_id: str | None) -> None:
    """Raise 403 with structured detail when the user is soft-deleted."""
    reason = get_delete_reason(user_id)
    if reason is None:
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail={"code": "user_deleted", "reason": reason},
    )


def _user_exists(user_id: str) -> bool:
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT 1 FROM users WHERE id = %s",
            (user_id,),
        ).fetchone()
    return row is not None


def soft_delete_user(*, user_id: str, reason: str, deleted_by: str) -> None:
    from .owner_iot import OWNER_IOT_USER_ID, is_owner_iot_user

    cleaned = reason.strip()
    if not cleaned:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Delete reason is required",
        )
    if is_owner_iot_user(user_id) or user_id == OWNER_IOT_USER_ID:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete the admin account",
        )
    if user_id == deleted_by:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete yourself",
        )
    if not _user_exists(user_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO user_deletions (user_id, reason, deleted_by, deleted_at) "
            "VALUES (%s, %s, %s, now()) "
            "ON CONFLICT (user_id) DO UPDATE SET "
            "reason = EXCLUDED.reason, "
            "deleted_by = EXCLUDED.deleted_by, "
            "deleted_at = now()",
            (user_id, cleaned, deleted_by),
        )


def restore_user(user_id: str) -> None:
    if not _user_exists(user_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    with get_pool().connection() as conn:
        deleted = conn.execute(
            "DELETE FROM user_deletions WHERE user_id = %s RETURNING user_id",
            (user_id,),
        ).fetchone()
    if deleted is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User is not in the archive",
        )


def list_archived_users() -> list[dict]:
    """Soft-deleted users still within the retention window."""
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT u.id, u.email, u.name, d.reason, d.deleted_at "
            "FROM user_deletions d "
            "JOIN users u ON u.id = d.user_id "
            "ORDER BY d.deleted_at DESC"
        ).fetchall()
    result: list[dict] = []
    for r in rows:
        deleted_at = r.get("deleted_at")
        result.append(
            {
                "user_id": str(r["id"]),
                "email": r.get("email"),
                "name": r.get("name"),
                "deleted": True,
                "delete_reason": (r.get("reason") or "").strip() or None,
                "deleted_at": (
                    deleted_at.isoformat()
                    if hasattr(deleted_at, "isoformat")
                    else deleted_at
                ),
            }
        )
    return result


def purge_expired() -> int:
    """Hard-delete users soft-deleted longer than ARCHIVE_RETENTION_DAYS.

    Returns the number of users removed.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(days=ARCHIVE_RETENTION_DAYS)
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT user_id FROM user_deletions WHERE deleted_at <= %s",
            (cutoff,),
        ).fetchall()
        ids = [str(r["user_id"]) for r in rows]
        for uid in ids:
            # CASCADE removes plants, bans, deletions, overrides, etc.
            conn.execute("DELETE FROM users WHERE id = %s", (uid,))
    return len(ids)


def deleted_user_ids(conn) -> set[str]:
    """Helper for admin list filtering (caller may pass an open connection)."""
    try:
        rows = conn.execute("SELECT user_id FROM user_deletions").fetchall()
    except Exception:
        return set()
    return {str(r["user_id"]) for r in rows}
