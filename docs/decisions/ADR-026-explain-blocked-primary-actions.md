# ADR-026: Explain blocked primary actions

## Status

Accepted

## Context

Primary actions (login, consent continue, form submit) were sometimes disabled with no visible reason — especially when personal-data consent was unchecked. Users on web could not tell why buttons did nothing.

## Decision

1. Do **not** silently disable primary buttons solely because a required precondition (consent, empty required field) is unmet.
2. Keep the button pressable; on press, show a **red** explanation next to the missing requirement:
   - `TextFormField` / `InputDecoration.errorText` via theme `errorStyle` / `errorBorder` (`colors.error`);
   - non-input requirements (consent checkbox) via `FieldErrorText` / `PersonalDataConsentCheckbox.errorText`.
3. After the first failed submit, auth email forms use `AutovalidateMode.onUserInteraction` so field errors stay visible while editing.
4. Disabling for **in-flight work** (`isLoading` / `_saving`) remains allowed when the control shows a progress indicator.
5. Future forms should follow the same pattern rather than greyed-out buttons without copy.

## Implementation

- Theme: `InputDecorationTheme` + `AppInputComponentTheme` error styles/borders from `colors.error`.
- `FieldErrorText`, consent `errorText` on login and consent gate.
- Login / consent gate: consent no longer disables the button; failed attempt shows `authConsentRequired`.
- Email sign-in / register sheets: validate on submit, then autovalidate.

## Behavior

- Login without consent → tap email/Google → red line under consent; buttons stay enabled.
- Consent gate without checkbox → tap Continue → same red line.
- Empty register/sign-in fields → red labels under those fields after submit.

## Consequences

- Pros: blocked actions are understandable; matches expected form UX on web.
- Cons: other feature sheets still disable only while saving (OK); migrating every form to autovalidate-after-submit is incremental, not required for this ADR.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on touched theme/auth/core widget files
- Manual: login without consent; register with empty name
