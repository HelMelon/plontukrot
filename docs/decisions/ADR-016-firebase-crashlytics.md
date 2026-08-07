# ADR-016: Firebase Crashlytics

## Status

Accepted

## Context

Production failures on user devices were invisible: Flutter/web console logs do not surface mobile crashes or caught errors. We need crash and non-fatal visibility for Android and iOS without changing architecture layers or adding a second analytics stack. Web Crashlytics support is limited; web can stay deferred.

## Decision

Add `firebase_crashlytics` behind a thin service wrapper `AppCrashReporting`:

- **Platforms:** Android and iOS only; all methods no-op on web.
- **Collection:** enabled when `!kDebugMode` (profile/release).
- **Install:** once after `Firebase.initializeApp` in app bootstrap.
- **Fatals:** hook `FlutterError.onError` and `PlatformDispatcher.onError`.
- **Non-fatals:** record selected caught failures with a stable `reason` string; rethrow so UI handling is unchanged.
- **User identifier:** Auth UID when signed in; cleared on sign-out / account deletion.
- **Noise filter:** do not report user-cancelled Google sign-in / popup closes.

Do not introduce a DI container or parallel telemetry SDK. UI must not import Crashlytics directly.

## Implementation

- Dependency: `firebase_crashlytics`
- Android: Gradle plugin `com.google.firebase.crashlytics` on the app module
- Service: `lib/services/app_crash_reporting.dart`
- Bootstrap / AuthGate: `lib/main.dart`
- Hotspots: `AuthService` (sign-in, delete account), `StorageService` (photo uploads), splash Home-ready timeout
- Docs: this ADR; section in `docs/architecture/firebase.md`

## Behavior

- Uncaught Flutter and platform errors on mobile profile/release builds appear in Firebase Console → Crashlytics.
- Caught startup, auth (non-cancel), storage upload, and splash timeout failures appear as non-fatals with reasons such as `app_bootstrap_failed`, `auth_sign_in_failed`, `storage_upload_plant_photo_failed`, `splash_home_ready_timeout`.
- Debug builds do not send reports (collection disabled).
- Web builds continue without Crashlytics SDK behavior.

## Consequences

- Operators can triage mobile crashes and key non-fatals without user reports.
- Web and debug remain blind to Crashlytics until a future decision.
- Expanding coverage means more `recordError` call sites in services, not UI.
- Console must have Crashlytics enabled; first reports may take minutes after a real device session.

## Verification

- `flutter analyze` (after implementation)
- Gradle Crashlytics plugin present in Android app module
- Device/emulator profile or release crash verification left to manual check (debug collection off)
