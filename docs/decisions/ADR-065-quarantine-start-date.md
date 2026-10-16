# ADR-065: Quarantine start date is chosen

## Status

Accepted

## Context

Manual quarantine always began on the current day (`quarantineEndDate(DateTime.now())`). A plant bought a few days earlier still needed the 14-day window to count from the purchase day, not from the day it was entered.

## Decision

Manual quarantine keeps a fixed length of 14 days. The user picks the start calendar day. `quarantine_until` remains the only stored bound (`start + 14 days`).

The picker allows today and earlier days that are still inside an open window: the earliest start is today minus 13 days, so the end instant is still in the future. A future start is not offered. Only `quarantine_until` is stored, and a start after today would make the plant look quarantined before that day.

Cancelling the picker does not enable quarantine. Changing the start of an active quarantine restarts the 14-day window. Changing only the reason does not.

Repotting still starts quarantine from the repotting date, including a date outside this picker range.

## Implementation

- `quarantine.dart`: calendar-day helpers and the allowed start window
- `PlantService.addPlant` / `updatePlant`: optional `quarantineStartedAt`; an active quarantine updates `quarantine_until` only when a start is passed
- UI: date row on add/update plant sheets; details toggle opens the picker when quarantine is turned on and when the start row is tapped
- l10n: `plantQuarantineStartDate` (ru/en/de/fr)

## Behavior

- Turn quarantine on from plant details → date picker, default today. Confirming 5 days ago ends quarantine 9 days from today.
- Add or edit a plant with the quarantine checkbox → same picker; the row shows the start and «До {date}».
- Dismiss the picker on details → the plant stays out of quarantine.
- New repotting → quarantine starts on the repotting day, as before.

## Consequences

- Backdating is limited to the still-open 14-day window.
- A start in the future would need its own stored field; this change does not add one.

## Verification

- `flutter test test/quarantine_test.dart`
- `flutter analyze` on the touched Dart files
- Device UI was not run
