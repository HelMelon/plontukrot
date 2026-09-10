# ADR-055: Server-driven feature flags

## Status

Accepted

## Context

The app needs to enable or disable product hubs and IoT surfaces without
client-side persistence or app releases. IoT (sensors, Telegram, balcony)
was previously gated by a hardcoded owner allowlist (`OwnerIotFeatures` /
ADR-054). That allowlist remains as a server-side default for IoT flags,
but the client must only consume a server response.

## Decision

Feature flags are resolved exclusively on the FastAPI backend and exposed
via authenticated `GET /features`. The Flutter client keeps the result in
memory only (`FeatureFlagsController`) — no SharedPreferences / disk cache.

Flag keys:

- `friends`
- `wish_list`
- `finances`
- `propagations`
- `archive`
- `genus_care`
- `soil_sensors`
- `telegram_alerts`
- `balcony`
- `fertilizing_reminders`
- `bulk_actions`

Resolution order on the server:

1. Code defaults (hubs on; IoT off)
2. Global env `FEATURE_FLAGS` JSON
3. Legacy owner IoT allowlist for unset IoT flags
4. Per-user env `FEATURE_FLAG_USER_OVERRIDES` JSON (highest priority)

Routers for gated domains return 403 when the flag is off for the caller.
Shared balcony hardware monitoring still attributes readings to the owner
account when the `balcony` flag is enabled for that account.

## Implementation

- Backend: `feature_flags.py`, `routers/features.py`, env docs in `.env.example`
- Flutter: `lib/core/features/feature_flags.dart`
- UI gates: home hubs, plant details/info, profile, genus care
- Replaces client `OwnerIotFeatures`; `owner_iot.py` remains for allowlist helpers
- Refresh on authenticated shell sync; clear on logout

## Behavior

- Signed-in user receives their effective flag map from the server
- Disabled hubs disappear from UI; matching APIs reject with 403
- IoT flags stay on for the owner unless explicitly overridden
- Turning `fertilizing_reminders` off cancels scheduled local notifications

## Consequences

- Changing flags requires a server env update (or a later admin API)
- Clients that skip `GET /features` fall back to enum defaults (IoT off)
- ADR-054 allowlist behavior is preserved inside flag resolution unless
  a higher-priority env override sets the IoT flag explicitly

## Verification

- `flutter analyze` on touched Dart files
- Python AST parse of touched backend modules
- Manual multi-account UI check not run in this session
