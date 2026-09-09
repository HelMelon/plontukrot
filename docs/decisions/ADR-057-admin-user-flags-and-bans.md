# ADR-057: Admin flag management for other users and account bans

## Status

Accepted

## Context

The owner admin page (ADR-056) only toggled flags for the signed-in owner.
Moderation needs: load another user by id, override their feature flags, and
fully ban an account with a required reason so they cannot sign in.

## Decision

- Admin APIs (owner UID only):
  - `GET/PATCH /features/admin/users/{user_id}` — effective flags for target
  - `POST /features/admin/users/{user_id}/ban` with `{ "reason": "..." }`
  - `DELETE /features/admin/users/{user_id}/ban`
- Persist bans in `user_bans (user_id, reason, banned_by, banned_at)`
- Login and JWT dependency (`get_current_user_id`) reject banned users with
  HTTP 403 and detail `{ "code": "user_banned", "reason": "..." }`
- Admin account cannot be banned; self-ban is rejected
- Flutter `FeatureFlagsPage` / admin tab: user list table with copy-id,
  load by id, per-user switches, ban / unban with reason dialog
- Profile for admin UID: tabs **Профиль** / **Админ**; admin content lives
  in the Admin tab (not a separate route)
- Sign-in sheet shows an `AlertDialog` with
  `authBannedMessage(reason)` when login returns `user_banned`
- Existing sessions: non-auth API 403 with `user_banned` clears the token

## Implementation

- Backend: `user_bans.py`, migration in `db.auto_migrate`, auth login /
  `get_current_user_id`, admin routes in `routers/features.py`
- Flutter: `AdminUserFeatures`, admin methods on `FeatureFlagsController`,
  `ApiException.isUserBanned` / `banReason`, updated FeatureFlagsPage +
  email sign-in error dialog
- l10n: `authBannedMessage`, `featureFlags*` admin copy

## Behavior

- Admin enters a user id → loads flags → toggles apply only to that user
- Ban requires a non-empty reason; banned user sees a popup on login with
  that reason and does not receive a JWT
- Unban restores login

## Consequences

- Ban check adds a DB lookup on every authenticated request
- Global feature rollout remains env-based; this is per-user only

## Verification

- `flutter analyze` on touched Dart files
- Python AST parse of touched backend modules
- Manual ban/login popup not run in this session
