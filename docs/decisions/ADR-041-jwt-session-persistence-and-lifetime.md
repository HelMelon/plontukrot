# ADR-041: JWT Session Persistence, Cached User Profile and Token Lifetime

## Status

Accepted

## Context

Users experienced frequent unexpected sign-outs while using the app:
1. The FastAPI backend configuration defaulted `ACCESS_TOKEN_EXPIRE_MINUTES` to `60` minutes (1 hour). Without a refresh-token rotation mechanism, any request or background polling stream (`restPollStream`) sent after 60 minutes received an HTTP 401 Unauthorized response ("Invalid token" due to JWT expiration), triggering `ApiClient.onUnauthorized` and clearing the user session.
2. `AuthService.restoreSession()` called `_emit(null)` upon catching network connectivity exceptions (e.g. `SocketException`, `TimeoutException`) during cold starts. Consequently, opening the app offline or on an unstable network immediately routed the user to `LoginPage` despite having a saved token.
3. `TokenStore` only persisted the raw `api_access_token` string, omitting the user profile (`AppUser`: `uid`, `email`, `name`, `photoUrl`). If `/auth/me` could not be fetched on launch, no user identity existed in memory.

## Decision

1. **Backend Token Lifetime:**
   - Increase default `ACCESS_TOKEN_EXPIRE_MINUTES` in `backend/app/config.py` from 60 minutes to `525600` minutes (1 year) to ensure long-lived sessions appropriate for a personal mobile journal without separate refresh tokens.
2. **Local Profile Persistence in TokenStore:**
   - Extend `TokenStore` to persist `AppUser` fields (`uid`, `email`, `name`, `photoUrl`) into `SharedPreferences` upon login, registration, and `/auth/me` profile synchronization.
   - Clear all cached profile keys alongside the access token upon sign-out or account deletion.
3. **Resilient Session Restoration:**
   - In `AuthService.restoreSession()`, load and immediately emit `TokenStore.instance.cachedUser` if available.
   - Retain the active session on network or timeout errors during `/auth/me` background verification, emitting `null` only when no cached session exists or when the server explicitly returns HTTP 401 Unauthorized or HTTP 404 Not Found.

## Implementation

- `backend/app/config.py`: Changed `ACCESS_TOKEN_EXPIRE_MINUTES` default to `525600` (1 year).
- `backend/README.md`: Updated environment variable documentation.
- `lib/services/token_store.dart`: Added caching for `AppUser` in `SharedPreferences` (`saveUser`, `cachedUser`, and cleanup in `clear()`).
- `lib/services/auth_service.dart`: Immediate emission of `cachedUser` on `restoreSession()`, update of cached user upon `_loadMe()`, and avoidance of `_emit(null)` on non-fatal network exceptions.

## Behavior

- Users remain signed in across app restarts, background idle periods, and offline usage.
- Starting the app without internet connectivity no longer kicks the user to the login screen.
- Explicit logouts (`signOut`, `deleteAccount`) and genuine server 401/404 responses cleanly terminate the session.

## Consequences

- Consistent and uninterrupted user experience on mobile devices.
- Seamless offline startup into `HomePage`.

## Verification

- `flutter analyze lib/` passed with 0 issues.
- Verified `TokenStore` serialization and `AuthService.restoreSession()` fallback logic.
