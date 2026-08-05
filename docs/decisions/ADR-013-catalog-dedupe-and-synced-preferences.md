# ADR-013: Catalog dedupe and synced locale/currency

## Status

Accepted

## Context

1. Adding a finance expense linked to a soil component (or fertilizer ingredient / purchased fertilizer / ready-made soil) always created a new catalog document, even when an entry with the same name already existed. Manual catalog management had the same gap. Only repotting/fertilizing custom-add paths checked names locally.

2. Language and currency lived only in SharedPreferences. On Flutter web, each new `localhost` port is a separate origin, so preferences reset to system locale and USD on every cold start. Preferences also did not follow the signed-in account across devices.

## Decision

### Catalog uniqueness

Catalog services expose case-insensitive `find*ByName` and `ensure*` (find-or-create) helpers:

- `ComponentService.ensureComponent`
- `FertilizeService.ensureIngredient` / `ensureFertilizer`
- `SoilService.ensureSoil`

Finance “also add to catalog” uses `ensure*` so repeat purchases reuse the existing entry. Manage sheets reject add/rename when a duplicate name exists and show `catalogItemAlreadyExists`. Matching is case-insensitive; existing documents are not overwritten.

### Locale and currency sync

Preferences remain cached in SharedPreferences for fast startup, and are also stored on `users/{uid}`:

- `localeCode` (same values as local: `system` | `en` | `ru` | `de` | `fr`)
- `currencyCode` (`USD` | `EUR` | `RUB` | `BYN`)

On change in Settings, both local cache and Firestore are updated (merge write). After sign-in, `syncWithCloud` prefers the Firestore value when present; if the cloud field is missing, local is pushed only when an explicit SharedPreferences key exists (so an empty web origin does not wipe cloud defaults). New user documents seed both fields from the current controllers.

## Implementation

- Services: `component_service.dart`, `fertilize_service.dart`, `soil_service.dart`
- Finance / manage / care sheets updated to use ensure or duplicate guards
- Controllers: `app_locale_controller.dart`, `app_currency_controller.dart`
- Bootstrap: `_AuthenticatedShell` in `main.dart` calls `syncWithCloud` after auth
- `FirestoreService.createUserDocument` seeds preference fields for new users
- l10n: `catalogItemAlreadyExists` (en/ru/de/fr)

## Behavior

- Recording an expense titled “Перлит” with “Компонент грунта” twice creates one catalog component and two finance entries.
- Adding “Перлит” again from Manage components shows a snackbar and does not create a duplicate.
- Choosing Russian + RUB in Settings persists across web ports and devices after login, once values are written to Firestore.
- Sign-out does not clear SharedPreferences; the next signed-in session still reconciles from Firestore for that account.

## Consequences

- Catalog lookups load the small per-user collection and compare names client-side (no `nameLower` field / composite index yet).
- Amounts remain bare numbers; changing currency still only changes the display symbol (unchanged from ADR-009).
- Users who only ever used SharedPreferences must open the app once while signed in (or re-select settings) so values are written to Firestore.

## Verification

- Code review of service ensure paths and auth sync flow
- `flutter analyze` / `flutter gen-l10n`: terminal unavailable in this environment; run locally before commit
- Manual checks recommended: duplicate expense → single catalog entry; change language/currency → restart on another web port → values restored after login
