# ADR-023: Email/password registration with email verification

## Status

Accepted

## Context

Sign-in was Google-only. Users need registration with email, password, and a site display name, plus mandatory email confirmation before using the app.

## Decision

1. Keep Google Sign-In; add Firebase Email/Password as a second provider.
2. Registration collects display name, email, password, and personal-data consent.
3. On register: create Auth user → `updateDisplayName` → `sendEmailVerification` → seed Firestore `users/{uid}` with explicit `name`/`email`.
4. Password-provider users with `emailVerified == false` are blocked by `AuthGate` on `EmailVerificationPage` (resend / check / sign out). Google users are not subject to this gate.
5. Auth session stream uses `userChanges()` so `User.reload()` after verification rebuilds the gate.
6. Account deletion reauthenticates with password for password accounts (prompt on profile) and with Google otherwise.
7. Extend `AuthFailureKind` for common email/password Firebase codes; map to localized messages (no raw exception text).

## Implementation

- Service: `AuthService` register/sign-in/verify/reload/password reauth; `FirestoreService.createUserDocument(displayName:)`
- UI: email form on `LoginPage`, `RegisterPage`, `EmailVerificationPage`; `AuthGate` verification branch
- Profile: password prompt before delete when `requiresPasswordToDelete`
- Shared: `showPromptTextDialog(obscureText:)`
- l10n: ru/en/de/fr auth + verification strings

## Behavior

- Login shows consent + two actions: email sheet and Google.
- Email sign-in / register open as bottom sheets (not inline on the login screen).
- Register → verification screen until the email link is confirmed and the user taps “I’ve confirmed”.
- Email sign-in with unverified address → same verification screen.
- Google sign-in unchanged (no email-verification gate).
- Consent checkbox on the login page is required before either sign-in path.

## Consequences

- Pros: standard Firebase email auth; clear unverified state; delete works for password users.
- Cons: no password-reset UI yet; Auth `displayName` and Firestore `name` are still written once at create (no ongoing sync UI).
- Requires Email/Password enabled in Firebase Console (done by operator).

## Verification

- `flutter gen-l10n`
- `flutter analyze` on changed auth/profile/main/service files — no issues
- Device UI flows not run in this session (manual check recommended on web)
