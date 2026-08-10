# ADR-024: Accessibility semantics passes (High / Low / Medium)

## Status

Accepted

## Context

An accessibility-tree audit found missing `Semantics`, unlabeled controls, decorative noise, and Medium content gaps (images, CustomPaint, weak field labels, date pickers, sheet titles).

## Decision

### High

1. Tooltips / labels for FABs and icon-only controls.
2. `button` + `selected` / `expanded` on cards, filters, tags, group headers.
3. Consent labeled control + separate privacy link.
4. `AccessibleProgressIndicator` for loading; raw spinner only inside the wrapper.
5. List-row / date-field taps use `Semantics(button, label)` from visible text.
6. No font / type-size changes.

### Low

7. Decorative noise excluded: `SheetDragHandle`, redundant icons, fake home-search contents, gallery dots.

### Medium

8. Images: `PlantNetworkImage` supports `semanticLabel` / `excludeFromSemantics`; gallery photos announce index (+ date); thumbnails inside labeled rows are excluded; logos/background/placeholders handled (label or exclude).
9. Vine `CustomPaint`: announce leaf count via `a11yLeafCount`; paint rows excluded so counter UI remains reachable.
10. Color-only cues: rely on `selected` / gallery photo index labels (dots stay decorative).
11. `update_note_sheet`: title + drag handle.
12. Friends/gift fields: `labelText` in addition to hint.
13. Date pickers: `a11ySelectDate` on date controls.

## Implementation

- Core: `accessible_progress_indicator.dart`, `sheet_drag_handle.dart`, consent checkbox
- Images: `plant_network_image.dart`, cards, archive/search/friend gallery, login/splash/`main` background, profile/home avatars
- Growth: `plant_vine_painter.dart`
- Sheets: note update title; date Semantics across finance/propagation/care sheets
- Friends/gift InputDecoration labels
- l10n: `a11y*` keys including gallery/leaf/date/profile

## Behavior

- Screen readers get named actions, selection state, labeled loading, list rows, and date choosers.
- Plant photos in galleries announce position; card thumbs do not duplicate card labels.
- Vine announces leaf count without exposing raw paint nodes.
- Sheet handles and decorative adornments stay silent.

## Consequences

- Remaining a11y polish may still appear as product iterates new screens.
- Font sizes were not changed.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on touched areas (no errors; existing `unnecessary_const` infos in `add_repotting_sheet` unrelated)
