# ADR-054: Owner-only IoT features (sensors, Telegram, balcony)

## Status

Accepted

## Context

Soil-moisture sensors, Telegram alert delivery, and balcony wintering depend on
shared physical hardware and a single Yandex Smart Home / Telegram bot setup.
The product is multi-tenant for plant journals, but those IoT surfaces are not
ready for every account. They must remain usable only for the collection owner
(`6c5e9eaf-d146-451f-8936-2e02d8d720bd`) until per-user hardware and OAuth are
available.

## Decision

Gate sensors, Telegram linking, and balcony features behind a single allowlisted
user id on both the Flutter client and the FastAPI backend.

- Flutter: `OwnerIotFeatures` hides UI (balcony toggle, sensor binding, home
  moisture stream / balcony banner, profile Telegram tile) for other users.
- Backend: JWT endpoints for `/telegram/*` (except bot confirm), `/balcony/*`,
  and plant sensor bindings return 403 for non-owner accounts.
- Plant create/update silently ignores `on_balcony` / `balcony_band` for
  non-owner callers.
- Background balcony monitor and Telegram alert fan-out only use the owner
  account's plants and linked chat.
- ESP8266 `POST /sensor/reading` stays token-based (device auth); UI binding and
  Telegram delivery remain owner-gated.

## Implementation

- `lib/core/features/owner_iot_features.dart` — allowlist helper.
- UI gates in `plant_info_card.dart`, `home_page.dart`, `profile_page.dart`.
- `backend/app/owner_iot.py` — `OWNER_IOT_USER_ID`, `require_owner_iot_user`.
- Routers: `telegram.py`, `balcony.py`, `sensor_bindings.py`, `plants.py`.

## Behavior

- Owner account: full sensor binding, Telegram link, balcony toggle/history/alerts.
- Any other signed-in user: those controls are absent; related APIs reject with 403.
- Moisture device posts and Smart Home skill endpoints are unchanged.

## Consequences

- Adding more allowed users later means updating the same constant on client and
  server (or replacing it with a proper feature flag).
- Existing non-owner Telegram links, if any, no longer receive alerts.
- Superseded for client gating by ADR-055 (server `GET /features`); the owner
  allowlist remains as the server default for IoT flags.

## Verification

- `flutter analyze` on touched Dart files.
- Manual device UI check for non-owner accounts was not run in this session.
