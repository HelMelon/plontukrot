# ADR-014: User profile, consent, and account deletion

## Status

Accepted

## Context

Language and currency lived on a dedicated Settings page reached from a Home gear icon; sign-out was also on Home. Users need a profile hub with account stats, prefs, Privacy Policy access, sign-out, and full account deletion. Personal-data consent must be explicit before using the app and stored in Firestore.

## Decision

1. **Profile hub** (`ProfilePage`) opens from the Home avatar. Settings gear and Home logout are removed. Language and currency are dropdowns on the profile page (same controllers as before).
2. **Stats** (client-side): active plant count, mode of `plantFamily` and `genus`, count of active propagation batches.
3. **Consent:** First visit on a device requires a checked consent box linking to `https://helmelon.github.io/plontukrot/privacy.html`. Successful sign-in writes `users/{uid}.personalDataConsentAt` (server timestamp). Existing sessions without the field see a blocking gate before Home. Acceptance is cached on the device (`SharedPreferences` via `DeviceConsentStore`). When the device flag is already set, login **hides** the checkbox; the post-auth gate **auto-syncs** consent to Firestore (no second consent screen) — this also covers the race where Auth opens the shell before `createUserDocument(recordConsent: true)` finishes. Clearing the device flag happens on account deletion. Firestore remains the account source of truth.
4. **Delete profile:** Google reauth, wipe all `users/{uid}` data (plants and care subtrees, catalogs, wish list, finances, remaining propagations), delete Storage under `plants/{uid}/`, delete the user document, then delete the Firebase Auth user. Shared `plantSpecies` is not deleted.

## Implementation

- Feature: `lib/features/profile/pages/profile_page.dart`
- Auth UI: login consent checkbox; `PersonalDataConsentGatePage` in `main.dart` shell
- Services: `FirestoreService` (consent, profile watch, full wipe), `AuthService.deleteAccount`, `PlantService.deleteAllUserPlants`, `StorageService.deleteAllUserPlantImages`
- Theme: `ProfileScreenTheme` replaces `SettingsScreenTheme`
- Removed: `features/settings/pages/settings_page.dart`

## Behavior

- Without consent on a fresh device, sign-in is blocked until the user accepts (red hint on press).
- If the device already remembered consent, the checkbox is not shown on login; after sign-in the gate syncs Firestore quietly (no second consent UI).
- Profile shows name/email from Firestore, stats, prefs, Privacy Policy link, Sign out, Delete profile (confirm dialog).
- Delete may prompt Google again for reauthentication; long-running wipe shows a blocking overlay.

## Consequences

- Client-side recursive delete can be slow or partially fail on large accounts; Auth delete requires recent login.
- Consent is not revocable in-app except by deleting the account.
- Preference sync behavior (SharedPreferences ↔ Firestore) unchanged (ADR-013).

## Verification

- `flutter pub get`, `flutter gen-l10n`, `flutter analyze` on touched files
- Device UI / full delete not fully exercised in implementation session — use a throwaway account for delete testing
