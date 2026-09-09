# ADR-058: Soft-delete users and 90-day admin archive

## Status

Accepted

## Context

Admin moderation (ADR-057) could ban accounts but not remove them. Owners need
to delete a user by id, keep a recoverable archive for a limited time, then
permanently purge unused accounts.

## Decision

- Soft-delete stores a row in `user_deletions (user_id, reason, deleted_by,
  deleted_at)` while the `users` row and cascaded domain data remain.
- Soft-deleted users cannot log in or use JWTs: HTTP 403 with
  `{ "code": "user_deleted", "reason": "..." }` (parallel to `user_banned`).
- Active admin list excludes soft-deleted users.
- Archive list returns soft-deleted users still within retention.
- Retention is **90 days**. After that, lazy `purge_expired` hard-deletes the
  user (`DELETE FROM users` → CASCADE). Purge runs when opening the archive or
  on soft-delete / restore — no cron.
- Restore removes the `user_deletions` row; login works again.
- Admin UID and self cannot be soft-deleted (same guards as ban).
- Delete requires a non-empty reason.

## Implementation

- Backend: `user_deletions.py`, migration in `db.auto_migrate`, auth login /
  `get_current_user_id`, admin routes in `routers/features.py`:
  - `GET /features/admin/users/archived`
  - `POST /features/admin/users/{id}/delete` `{ "reason": "..." }`
  - `DELETE /features/admin/users/{id}/delete` (restore)
  - `GET/PATCH .../users/{id}` include `deleted`, `delete_reason`, `deleted_at`
- Flutter: admin tab «Показать архив», delete/restore beside ban; sign-in
  dialog for `user_deleted`; `ApiException.isUserDeleted` clears session like
  bans.
- Self-service `DELETE /auth/me` remains an immediate hard delete and is
  unchanged.

## Behavior

- Admin loads a user → **Удалить** with reason → user leaves the active list
  and appears in the archive; cannot sign in.
- **Восстановить** returns the account to the active list.
- After 90 days without restore, opening the archive (or delete/restore) purges
  the account and all cascaded data permanently.

## Consequences

- Extra DB check on every authenticated request (like bans).
- Disk photos under `PHOTOS_DIR` are not cleaned on hard purge (possible
  orphans).
- Soft-deleted users keep feature-flag overrides and plants until purge.

## Verification

- `flutter analyze` on touched Dart files — clean
- Python AST parse of touched backend modules — ok
- Manual soft-delete / restore / login dialog not run in this session
