# ADR-056: Personal feature-flag admin in profile

## Status

Accepted

## Context

Feature flags were server-resolved via env only (ADR-055). The collection
owner needs to toggle personal overrides from the Profile screen without
redeploying or editing env JSON. Changes must apply only to that account
and must not be stored on the device.

## Decision

Persist per-user overrides in PostgreSQL and expose them through the
existing features API:

- Table `user_feature_flag_overrides (user_id, flags JSONB, updated_at)`
- Resolution order ends with DB overrides (highest priority)
- `PATCH /features` merges a partial flag map into the caller's row
- Only `OWNER_IOT_USER_ID` (`6c5e9eaf-d146-451f-8936-2e02d8d720bd`) may
  call `PATCH` and see the Profile switches UI
- Flutter keeps effective flags in memory via `FeatureFlagsController`
  (`setFlag` → PATCH → update map); no local persistence

## Implementation

- Backend: `feature_flags.get_db_overrides` / `upsert_db_overrides`,
  migration in `db.auto_migrate`, `PATCH` on `routers/features.py`
- Flutter: `FeatureFlagsController.canManageFlags` / `setFlag`
- Profile: owner-only list tile opens `FeatureFlagsPage` with
  `SwitchListTile` per `FeatureFlag`
- l10n keys: `profileFeatureFlagsTitle`, `profileFeatureFlagsSubtitle`,
  `featureFlag*`

## Behavior

- Owner toggles a flag in Profile → server stores override → UI updates
  immediately; other accounts unchanged
- Owner can turn IoT flags off despite the legacy allowlist, because DB
  overrides win
- Non-owner users never see the section; `PATCH` returns 403

## Consequences

- Global rollout for everyone still requires env `FEATURE_FLAGS` (or a
  future global admin API)
- Owner-only admin is intentional for this personal-override scope
- Extended in ADR-057: admin can load another user id, override their
  flags, and ban/unban with a reason

## Verification

- `flutter analyze` on touched Dart files
- Python AST parse of touched backend modules
- Manual device check of owner vs non-owner profile not run in this session
