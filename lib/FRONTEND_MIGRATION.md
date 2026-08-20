# Flutter frontend: Firebase → FastAPI REST

Service-layer rewrite so the SKÖRD app talks to the self-hosted FastAPI backend
instead of Firebase Auth / Firestore / Storage. UI pages were left in place;
`StreamBuilder` still works because list methods return polling streams.

## Config

- Base URL: `lib/config/api_config.dart`
- Override: `--dart-define=API_BASE_URL=http://10.0.2.2:8000`
  - Android emulator → host: `http://10.0.2.2:8000`
  - Physical phone: LAN IP of the machine running uvicorn
  - Desktop / Windows: `http://127.0.0.1:8000` (default)

JWT is stored in `SharedPreferences` (`api_access_token`).

## What changed

| Area | Before | After |
|---|---|---|
| Auth | Firebase Auth + Google | `POST /auth/register`, `POST /auth/login`, JWT |
| Data | Cloud Firestore snapshots | REST GET/POST/PATCH/DELETE + 8s poll |
| Photos | Firebase Storage upload | Display existing `image_url`; new upload not available yet |
| Crash reporting | Crashlytics | Local `debugPrint` |
| Models | camelCase + `Timestamp` | camelCase **or** snake_case, ISO-8601 dates |

## New files

- `lib/config/api_config.dart`
- `lib/services/api_client.dart`
- `lib/services/api_exception.dart`
- `lib/services/api_refresh.dart`
- `lib/services/rest_stream.dart`
- `lib/services/token_store.dart`

## Removed

- `lib/firebase_options.dart`
- pubspec: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_crashlytics`, `google_sign_in`
- Google sign-in button on login
- Email verification gate (backend v1 has none)

## Backend gaps (current FastAPI routers)

The app calls ADR-033 paths. Some are not implemented yet and fail softly
(`404` ignored) or show an error:

- `PATCH` / `DELETE` `/plants/{id}` — edit, archive, delete
- `GET` `/plants/{id}/repottings` — history (create `POST` exists)
- `PATCH /auth/me` — locale, currency, consent
- `DELETE /auth/me` — account wipe
- Nested `PATCH`/`DELETE` for waterings, notes, fertilizings, etc.
- `POST /propagations/{id}/notes` — add note (GET exists)
- Photo/receipt **file** upload (Object Storage, Phase 4)
- Friend collection viewing, gift status updates

Core flows that match existing routers: register/login, list/add plants,
notes, watering, fertilizing, catalogs, species, gifts send/list.

## How lists refresh

After each mutating request, `ApiClient` pings `ApiRefresh`. List streams
re-fetch immediately and also every 8 seconds.
