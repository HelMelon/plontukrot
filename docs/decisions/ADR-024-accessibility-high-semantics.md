# ADR-024: Accessibility high-priority semantics pass

## Status

Accepted

## Context

An accessibility-tree audit found no explicit `Semantics` usage and several high-impact unlabeled controls (FABs, icon-only actions, custom chips/cards, consent checkbox, loading indicators).

## Decision

Address all **High** audit gaps:

1. Tooltips / semantic labels for FABs and icon-only controls on primary surfaces (home, wish list, finances, search clear/back, selection exit, auth password visibility, gallery add/delete).
2. Expose `button` + `selected` (or `expanded`) on `PlantCard`, home filter chips, letter-group headers, and composition tags.
3. Consent: labeled checkbox control via `Semantics(checked: …)` on the consent text; privacy policy as a separate `link` semantics node; visual checkbox excluded from the tree.
4. `AccessibleProgressIndicator` (labeled live region) replaces app `CircularProgressIndicator` usages; raw indicator only inside the wrapper.
5. List-row and date-field `InkWell`s outside hubs use `Semantics(button: …, label: …)` from visible text.
6. Do not change fonts or type sizes.

Medium/Low items (image alt text, CustomPaint, empty-state announcements, sheet drag handles) remain deferred.

## Implementation

- `lib/core/widgets/accessible_progress_indicator.dart`
- Consent: `personal_data_consent_checkbox.dart`
- Hub chrome: home FAB / search / selection close / filter chips / group headers; wish list & finances FABs; search delegate back/clear
- Gallery: `plant_image_card.dart` empty-state + action buttons
- Auth: password visibility tooltips on email sign-in/register sheets
- Cards/tags/list rows/history/date pickers as in prior High follow-ups
- l10n: `commonBack`, `commonClear`, `a11yShowPassword`, `a11yHidePassword`, `a11yExitSelection`, `a11yOpenSearch`, `plantPhotoAdd` (+ existing `plantAdd` / `wishListAdd` / `financesAdd` / `plantPhotoDeleteTitle`)

## Behavior

- Screen readers get named FABs, selection exit, search open/clear/back, password show/hide, gallery add/delete.
- Plant cards, filters, tags, and group headers announce role and selection/expansion.
- Consent toggles as one labeled control; privacy policy remains a separate link.
- Loading states announce via `AccessibleProgressIndicator`.
- List rows and date fields announce as buttons with on-screen text.

## Consequences

- Medium/Low audit items remain open.
- Font sizes were not changed.
- Some decorative icons use `ExcludeSemantics` to avoid duplicate announcements.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on touched files — no issues
- Grep: no `CircularProgressIndicator` outside `accessible_progress_indicator.dart`
