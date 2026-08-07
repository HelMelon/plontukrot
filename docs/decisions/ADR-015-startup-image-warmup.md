# ADR-015: Startup splash covers real Home load and first paint

## Status

Accepted

## Context

Cold start showed a decorative splash carousel, then AuthGate/Home spinners while Firestore and `CachedNetworkImage` still loaded. Precaching alone before building Home was not enough: Home mounted later, showed spinners, and thumbs still flashed placeholders.

## Decision

1. After Firebase bootstrap, build the real app (`AuthGate` → consent → `HomePage` / `LoginPage`) **under** a full-screen `SplashCarouselPage` overlay.
2. Dismiss splash only when **both** are true:
   - carousel has shown all slides (longer per-slide duration ~1.6s);
   - content signals ready (`onContentReady` / `onFirstContentReady`).
3. Home ready means: user doc + plants stream resolved, list thumbs (+ avatar) precached via `StartupWarmupService`, and at least two frames painted so cards can resolve from cache.
4. While splash is up, Auth/consent/Home waiting states render empty (no spinner).
5. If ready never fires, splash still leaves after a 20s timeout.
6. Do not precache plant-details gallery full-size images.

## Implementation

- `lib/main.dart` — `Stack(AuthGate, SplashCarouselPage)`; `Completer` for content ready
- `lib/features/home/pages/home_page.dart` — `onFirstContentReady` + precache + endOfFrame
- `lib/features/auth/pages/personal_data_consent_gate_page.dart` — `onContentReady` for consent UI
- `lib/services/startup_warmup_service.dart` — `precacheHomeContent`
- Splash default `secondsPerImage`: 1600ms

## Behavior

- Signed-in with consent: splash stays until Home grid (or empty state) is loaded and painted; then Home appears ready.
- Consent required: splash leaves after consent UI’s first frames.
- Signed out: splash leaves after Login’s first frames.
- Slow network: timeout may reveal Home with some remaining downloads.

## Consequences

- Slightly longer minimum splash (~4.8s for three slides).
- Extra memory/CPU while Home builds under an opaque overlay.
- Post-login from LoginPage is outside this cold-start path.

## Verification

- `flutter analyze` on touched Dart files
- Manual cold start (signed in): no spinner between splash and Home; thumbs should not flash placeholders when network is OK
