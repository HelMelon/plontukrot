# ADR-050: Fertilizing overdue reminders and card indicator

## Status

Accepted

## Context

Fertilizing local notifications used `fertilizingDayNotificationAt` / `fertilizingEveNotificationAt`
which returned `null` when the computed fire time was already in the past. If a user missed a
cycle (app closed, denied alarms, device off), reopening the app cancelled the stale schedule
and planned nothing — the plant entered a dead zone with no reminder until manual fertilizing.

Users also had no at-a-glance signal on the home grid for overdue plants.

## Decision

### Overdue definition

`isFertilizingOverdue` is true when:

- fertilizing is active (`fertilizingFrequencyDays > 0`);
- plant is not archived;
- `nextFertilizingDate` (from `lastFertilizedAt` or `createdAt`) is on or before today's
  calendar date.

Overdue clears only when a new fertilizing is recorded (`lastFertilizedAt` moves forward).

### Notification scheduling

- **Eve (19:00 day before):** unchanged — still skipped when that time is past.
- **Day (08:00):** when due today or overdue:
  - if before 08:00 local → schedule at 08:00 today;
  - otherwise → schedule ~5 seconds after `now` so reopening the app re-triggers the reminder.
- Overdue day notifications use `fertilizingReminderOverdueBody` l10n copy.
- Android: request exact-alarm permission alongside notification permission.

### UI

- `PlantCard` shows a red circular fertilizer badge on the photo and a red fertilizer stat icon
  while overdue; the stat row shows the **due date** (`nextFertilizingDate`), not
  `lastFertilizedAt`.
- Semantics include `a11yFertilizingOverdue`.

## Implementation

- `lib/models/fertilizing_frequency.dart` — `isFertilizingOverdue`, updated
  `fertilizingDayNotificationAt`.
- `lib/services/fertilizing_notification_service.dart` — overdue body, exact-alarm request.
- `lib/features/plants/widgets/cards/plant_card.dart` — badge + red stat icon.
- l10n keys in all `app_*.arb` files.
- Tests in `test/fertilizing_frequency_test.dart`.

## Behavior

Example: last fertilized 16 Aug, 14-day interval → due 30 Aug. On 2 Sep the plant is overdue;
opening the app schedules a day notification within seconds and shows the red icon until
fertilizing is logged.

## Consequences

- Repeated app opens while overdue reschedule the near-immediate notification (same id,
  cancel + plan) — acceptable nudge until the user acts.
- Eve reminder is not repeated for overdue cycles; only the day/overdue notification fires.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on touched files
- `flutter test test/fertilizing_frequency_test.dart`
