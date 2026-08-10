# ADR-024: Accessibility high-priority semantics pass

## Status

Accepted

## Context

An accessibility-tree audit found no explicit `Semantics` usage and several high-impact unlabeled controls (FABs, icon-only actions, custom chips/cards, consent checkbox, loading indicators).

## Decision

Address **High** gaps first:

1. Add tooltips / semantic labels for FABs and icon-only controls on primary surfaces (home, search, auth password visibility, gallery actions).
2. Expose `button` + `selected` on `PlantCard`, home filter chips, and composition tags.
3. Associate consent checkbox with its label via `MergeSemantics`; keep the privacy policy link as a separate link semantics node.
4. Introduce `AccessibleProgressIndicator` (labeled live region) and use it on key loading hubs (home, wish list, finances, login/consent).

Medium/Low audit items (images, CustomPaint, sheet handles, remaining spinners) are deferred.

## Implementation

- `lib/core/widgets/accessible_progress_indicator.dart`
- Consent: `personal_data_consent_checkbox.dart`
- Home / search / plant card / gallery / tags / wish list / finances / auth sheets
- l10n keys: `a11y*`, `commonBack`, `commonClear`, `plantPhotoAdd`

## Behavior

- Screen readers get named FABs, selection exit, search open, password show/hide, gallery add/delete.
- Plant cards and filters announce selection state.
- Consent toggles as one control; privacy policy remains a separate link.
- Key loading states announce `loading` (or contextual auth strings).

## Consequences

- Not every `CircularProgressIndicator` or list `InkWell` is covered yet.
- Font sizes were not changed.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on touched files
