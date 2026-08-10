# ADR-024: Accessibility high-priority semantics pass

## Status

Accepted

## Context

An accessibility-tree audit found no explicit `Semantics` usage and several high-impact unlabeled controls (FABs, icon-only actions, custom chips/cards, consent checkbox, loading indicators).

## Decision

1. Introduce `AccessibleProgressIndicator` (labeled live region) and replace app `CircularProgressIndicator` usages with it; keep the raw indicator only inside that wrapper.
2. Wrap list-row and related tap targets with `Semantics(button: …, label: …)` using visible on-screen text; use `selected` where selection applies; `ExcludeSemantics` on decorative chevrons/icons.
3. Cover composition tags and `PlantCard` with `button` + `selected`.
4. Cover date-field `InkWell`s in finance/propagation sheets the same way as list rows.
5. Defer Medium/Low items (image alt text, CustomPaint, sheet handles) and remaining unlabeled hub chrome (e.g. home letter-group headers, gallery add without a dedicated string) until a follow-up pass.
6. Do not change fonts or type sizes.

## Implementation

- `lib/core/widgets/accessible_progress_indicator.dart` — sole remaining raw `CircularProgressIndicator`
- List/selection: `PlantCard`, soil/fertilizer tags, archive rows, propagations list, plant propagations section, care history sheets, wish-list select sheet, `InfoCard`
- Detail links / controls: botanical / genus links on plant info card, leaf-counter scroll link and ± controls
- Date pickers: add finance entry, add/change/sell-lose propagation sheets
- Labels reuse existing visible / l10n strings (no new `a11y*` keys in this pass)

## Behavior

- Loading states announce via `AccessibleProgressIndicator`.
- List rows, cards, tags, and date fields announce as buttons with the on-screen title/date/selection text.
- Decorative chevrons and calendar icons do not duplicate announcements.

## Consequences

- Consent checkbox / privacy link merge, hub FAB tooltips, password visibility labels, and gallery add label may still be incomplete if not restored from earlier work.
- Medium/Low audit items remain open.
- Font sizes were not changed.

## Verification

- `flutter analyze` on touched files — no issues
- Grep: no `CircularProgressIndicator` outside `accessible_progress_indicator.dart`
