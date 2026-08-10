# ADR-024: Accessibility high-priority semantics pass

## Status

Accepted

## Context

An accessibility-tree audit found no explicit `Semantics` usage and several high-impact unlabeled controls (FABs, icon-only actions, custom chips/cards, consent checkbox, loading indicators), plus Medium/Low decorative and content gaps.

## Decision

### High

1. Tooltips / semantic labels for FABs and icon-only controls on primary surfaces (home, wish list, finances, search clear/back, selection exit, auth password visibility, gallery add/delete).
2. Expose `button` + `selected` (or `expanded`) on `PlantCard`, home filter chips, letter-group headers, and composition tags.
3. Consent: labeled checkbox control via `Semantics(checked: …)` on the consent text; privacy policy as a separate `link` semantics node; visual checkbox excluded from the tree.
4. `AccessibleProgressIndicator` (labeled live region) replaces app `CircularProgressIndicator` usages; raw indicator only inside the wrapper.
5. List-row and date-field `InkWell`s outside hubs use `Semantics(button: …, label: …)` from visible text.
6. Do not change fonts or type sizes.

### Low

7. Decorative noise is excluded from the semantics tree:
   - shared `SheetDragHandle` (`ExcludeSemantics`) for bottom-sheet drag indicators;
   - decorative icons next to already-labeled text (chevrons, calendar adornments, auth prefix icons, profile leading/trailing icons);
   - fake home search field contents under the outer labeled button;
   - gallery page-indicator dots.

### Deferred (Medium)

Image `semanticLabel` / decorative images, CustomPaint vine semantics, color-only selection cues beyond dots, `update_note_sheet` title, friends/gift hint-only field names.

## Implementation

- `lib/core/widgets/accessible_progress_indicator.dart`
- `lib/core/widgets/sheet_drag_handle.dart`
- Consent, hub chrome, gallery actions, auth password tooltips, cards/tags/list rows as in High passes
- Sheet files use `SheetDragHandle`; decorative `ExcludeSemantics` on listed adornments
- l10n: `commonBack`, `commonClear`, `a11yShowPassword`, `a11yHidePassword`, `a11yExitSelection`, `a11yOpenSearch`, `plantPhotoAdd`

## Behavior

- Screen readers get named FABs, selection exit, search open/clear/back, password show/hide, gallery add/delete.
- Plant cards, filters, tags, and group headers announce role and selection/expansion.
- Consent toggles as one labeled control; privacy policy remains a separate link.
- Loading states announce via `AccessibleProgressIndicator`.
- List rows and date fields announce as buttons with on-screen text.
- Sheet handles and redundant decorative icons are not announced.

## Consequences

- Medium audit items remain open.
- Font sizes were not changed.

## Verification

- `flutter analyze` on touched areas
- Grep: no `CircularProgressIndicator` outside `accessible_progress_indicator.dart`
- Grep: sheet handles go through `SheetDragHandle`
