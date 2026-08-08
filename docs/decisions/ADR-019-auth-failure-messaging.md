# ADR-019: Auth failure user messaging

## Status

Accepted

## Context

Google Sign-In and Firebase Auth often return technical exceptions that confuse users. Offline attempts may surface as `GoogleSignInExceptionCode.canceled` with “Account reauth failed”, and closing the popup yields `popup-closed-by-user`. The login snackbar previously dumped `e.toString()`.

## Decision

1. Classify auth errors into `AuthFailureKind`: `cancelled`, `network`, `missingIdToken`, `unknown` via `AuthService.classifyFailure`.
2. Map kinds to localized strings; never show raw exception text on login.
3. Treat cancel / popup-closed as silent (no snackbar); do not report them to Crashlytics.
4. Treat offline reauth-failed cancel messages as `network`.
5. Reuse the same classification for account-deletion reauth errors on the profile page.

## Implementation

- `AuthService.classifyFailure` / Crashlytics skip for `cancelled`
- `auth_failure_messages.dart` for login snackbar copy
- l10n: `authSignInNetworkError`, `authSignInFailed`, `profileDeleteAccountFailed`

## Behavior

- No internet / reauth-failed cancel → “Нет соединения с интернетом…”
- User closes popup → no error toast
- Other failures → generic “Не удалось войти…”
- Delete-account reauth cancel → silent; network → same network string; other → delete-failed string

## Consequences

- Pros: clearer UX; less Crashlytics noise from intentional cancels.
- Cons: heuristic mapping of “reauth failed” to network may occasionally mislabel a true cancel that includes that substring.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on auth/profile/service files
