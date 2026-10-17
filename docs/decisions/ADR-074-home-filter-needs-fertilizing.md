# ADR-074: Home filter for plants that need fertilizing

## Status

Accepted

## Context

The home collection can be filtered by status (propagation, groups, rescue, quarantine), room, and botanical fields. Fertilizing due dates are already shown on the plant card, but there was no way to list only the plants that need feeding.

## Decision

Add a status chip «Требуют подкормки» (`fertilizingDueOnly`) to the home filter sheet. It uses the same rule as the red fertilizing date on the card: the next feed is today or earlier.

Plants with fertilizing stopped (`frequency` null or `0`, including balcony STOP) are excluded. Archived plants are excluded. A plant still in quarantine is included only when the post-quarantine first feed is already due, using the current season settings.

The flag is stored with filter presets.

## Implementation

- `PlantFilterCriteria.fertilizingDueOnly` and `plantNeedsFertilizing`.
- Status chip in `plant_filter_sheet.dart` and a removable chip on the home page.
- Label `homeNeedsFertilizing` in ru/en/de/fr.

## Behavior

Selecting the chip keeps plants whose next fertilizing day is today or in the past. Combining it with other filters narrows the list further. Clearing the chip or «Сбросить всё» removes it.

## Consequences

The filter stays aligned with the card badge. It does not include plants that are due tomorrow.

## Verification

- `flutter test test/plant_filter_criteria_test.dart test/quarantine_test.dart` — passed.
- `flutter analyze` on the filter model, home page, and filter sheet — no issues.
- The filter sheet was not opened on a device in this session.
