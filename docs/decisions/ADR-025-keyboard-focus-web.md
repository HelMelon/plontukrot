# ADR-025: Keyboard focus and dismiss for web/desktop

## Status

Accepted

## Context

The Flutter web (and Windows) builds needed keyboard operation: Tab focus movement, Enter/Space activation, and Escape to close sheets/dialogs. An audit found no Shortcuts/FocusTraversal layer, many non-focusable `GestureDetector` taps, and focus leaking under modals.

## Decision

1. Target keyboard UX on **web and desktop** (`kIsWeb` / Windows / macOS / Linux); phone touch UX unchanged aside from a shared focus ring when focused.
2. Add shared helpers:
   - `AppKeyboardScope` + `ModalFocusTrap` in `lib/core/keyboard/app_keyboard.dart`
   - `showAppModalBottomSheet` / `showAppDialog` in `lib/core/widgets/app_modal.dart` (focus trap; Esc via Flutter `DismissIntent` when dismissible)
   - `FocusableTap` for custom taps (Enter/Space + visible focus ring from theme tokens)
3. Theme: `focusColor` / `highlightColor` from primary; `dimensions.focusRingWidth` for the ring.
4. Migrate modal call sites to the app helpers.
5. Replace critical `GestureDetector` taps (`PlantCard`, home search, tags, consent, empty gallery) with `FocusableTap`.
6. Destructive dialogs with `barrierDismissible: false` remain non-Esc-dismissible.
7. No arrow-key plant-grid navigation in this pass. No font changes.

## Implementation

- Core keyboard/widgets as above; `MaterialApp.builder` wraps `AppKeyboardScope`
- Feature sheets/dialogs use `showAppModal*`
- Hub/custom controls use `FocusableTap` where listed

## Behavior

- Tab / Shift+Tab moves among focusable controls; focus ring visible on keyboard platforms.
- Enter/Space activates `FocusableTap` and Material buttons.
- Esc closes the top dismissible modal/dialog/search; nested sheets pop one level.
- Non-dismissible confirms require Cancel/Delete buttons.

## Consequences

- Remaining GestureDetectors (if any) may still be mouse-only until migrated.
- Focus ring adds a 2px border inset on `FocusableTap` (transparent when unfocused).

## Verification

- `flutter analyze` on touched areas
- Manual Chrome checklist: login Tab/Esc sheet; Home search Enter/Esc; plant card Enter; nested history Esc; destructive Esc does not delete
