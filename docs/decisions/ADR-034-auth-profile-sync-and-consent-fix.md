# ADR-034: Auth Profile Sync and Personal Data Consent Fix

## Status

Accepted

## Context

Following the migration to the self-hosted FastAPI backend (ADR-033), users were unable to sign in or access the application. The login and registration flows failed due to multiple interrelated issues:

1. `PATCH /auth/me` and `DELETE /auth/me` endpoints were missing from the FastAPI backend router (`backend/app/routers/auth.py`).
2. After successful authentication (`POST /auth/login` or `POST /auth/register`), `AuthService` invoked `UserProfileService().createUserDocument()`. This method checked for camelCase `personalDataConsentAt`, while the backend returns snake_case `personal_data_consent_at`.
3. Because consent was parsed as null, the client attempted to record consent via `PATCH /auth/me`. The server returned HTTP 405 Method Not Allowed, causing `signInWithEmail` and `registerWithEmail` to fail with an error snackbar.
4. `PersonalDataConsentGatePage` became stuck in an infinite placeholder loop when device consent was already accepted (`_consentRememberedOnDevice == true`), because `UserProfileDoc.fromMap` never recognized `personal_data_consent_at`, perpetually waiting for a cloud state that could not be read.
5. User preference controllers (`AppLocaleController` and `AppCurrencyController`) checked legacy camelCase keys (`localeCode`, `currencyCode`) instead of `locale_code` and `currency_code`.

## Decision

1. **Backend Endpoints:**
   - Implement `PATCH /auth/me` on `backend/app/routers/auth.py` accepting `UserUpdate` schema (`name`, `locale_code`, `currency_code`, `collection_visibility`, `personal_data_consent_at`), supporting both snake_case and camelCase aliases and ignoring unknown extra fields.
   - Implement `DELETE /auth/me` on `backend/app/routers/auth.py` to support user account deletion with database cascade.
2. **Profile & Consent Synchronization:**
   - Update `UserProfileDoc.fromMap` to read `personal_data_consent_at` (with fallbacks to `personalDataConsentAt` and `kPersonalDataConsentAtField`) and `collection_visibility` (fallback to `collectionVisibility`).
   - Make `UserProfileService.createUserDocument`, `recordPersonalDataConsent`, and `patchProfile` resilient to non-fatal network or metadata errors so auth is never blocked by auxiliary profile requests.
   - Update `PersonalDataConsentGatePage` to immediately admit users who have already accepted consent on their device (`_consentRememberedOnDevice == true` or `snapshot.data == true`) while synchronizing consent to the backend in the background.
3. **Locale & Currency Preference Controllers:**
   - Read `locale_code` and `currency_code` directly from profile JSON with backwards-compatible fallbacks.

## Implementation

- `backend/app/schemas.py`: Added `UserUpdate` model with field aliases and `extra="ignore"`, and added `personal_data_consent_at` to `RegisterRequest`.
- `backend/app/routers/auth.py`: Added `PATCH /auth/me` and `DELETE /auth/me` handlers, and stored `personal_data_consent_at` on `POST /auth/register`.
- `lib/services/user_profile_service.dart`: Added snake_case and camelCase field parsing, `DeviceConsentStore` integration, and non-fatal error handling for profile updates.
- `lib/features/auth/pages/personal_data_consent_gate_page.dart`: Resolved infinite waiting placeholder loop and stream recreation; admitted users with remembered device consent and updated consent state on submit.
- `lib/core/currency/app_currency_controller.dart`: Updated `syncWithCloud` to read `currency_code`.
- `lib/core/locale/app_locale_controller.dart`: Updated `syncWithCloud` to read `locale_code`.
- `lib/services/auth_service.dart`: Enhanced network failure classification and ensured device and backend consent recording on sign-in and registration.
- `lib/services/friends_service.dart`: Added dual snake_case / camelCase reading for user IDs in friendships.

## Behavior

- Users can log in and register without errors.
- If consent was already accepted on the device, the user enters the home screen directly without getting stuck on a loading screen.
- Consent and preferences (locale, currency) are saved and synced with the backend without throwing unhandled exceptions.

## Consequences

- Smooth authentication and onboarding experience.
- Backend and frontend data contracts are fully aligned on snake_case and camelCase.

## Verification

- `flutter analyze lib/` passed with 0 issues.
- Code flow and field mappings inspected.
