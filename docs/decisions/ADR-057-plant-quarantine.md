# ADR-057: Plant quarantine status

## Status

Accepted

## Context

New plants from purchase and plants after repotting need a short isolation period that is separate from reanimation (rerooting manipulations). Users need to enable quarantine on create/edit/details, filter quarantined plants on home, see a badge on cards and gallery, get a notification when quarantine ends, and have the first fertilizing delayed until after quarantine.

## Decision

Quarantine is a first-class plant field (not a manipulation type):

- `quarantine_until` — end datetime; plant is active in quarantine while this is in the future
- `quarantine_reason` — `purchase` or `repotting`

Duration is fixed at **14 days** from the start day. Soft expiry: no cron clears the columns; UI and filters use `quarantineUntil.isAfter(now)`. Past `quarantine_until` still drives the first post-quarantine fertilizing until a fertilizing is recorded after that date.

Auto-enable:

- Creating/editing with the quarantine checkbox sets reason + `until = start + 14 days`
- Recording a **new** repotting always starts (or restarts) quarantine with reason `repotting`

Fertilizing:

- First feed after quarantine: `quarantine_until + 14 days` in spring/summer, `+ 21 days` in autumn/winter (season from fertilizing season settings at `quarantine_until`)
- Integrated into `nextFertilizingDate` / reminders so the delay wins over a sooner normal interval

Notifications:

- Local notification at 09:00 on the quarantine end day (`QuarantineNotificationService`)
- Fertilizing reminders continue to use the adjusted next date

UI:

- Checkbox + reason chips on add/update plant sheets
- `QuarantineToggle` on plant details (alongside balcony/sensors)
- Home filter status chip «Карантин»
- Badge on plant card photo and details gallery

## Implementation

- Models: `QuarantineReason`, `quarantine.dart` helpers, `Plant` fields
- Backend: `quarantine_until` / `quarantine_reason` on plants (schema + migrate + API)
- Services: `PlantService.setQuarantine` / create-update params, `RepottingService` auto-start, `QuarantineNotificationService`, fertilizing schedule hooks
- UI: sheets, toggle, badge, home filter
- l10n: ru/en/de/fr

## Behavior

- Create with quarantine «Покупка» → plant shows badge and is filterable for 14 days; notification fires on end day; first fertilizing is scheduled after the seasonal delay from end date
- Add repotting → quarantine restarts for 14 days with reason «Пересадка»
- Toggle off on details → clears quarantine fields (manual cancel, no fertilizing delay from quarantine)
- Reanimation filter/manipulations remain unchanged

## Consequences

- Quarantine is independent of `ManipulationType.rerooting`
- Keeping expired `quarantine_until` until post-quarantine fertilizing is recorded preserves the delay without a separate flag
- Restarting quarantine on every new repotting is intentional

## Verification

- `flutter test test/quarantine_test.dart test/plant_filter_criteria_test.dart`
- `flutter analyze` on touched Dart files
- Device UI not run in this change set
