# ADR-059: Batch fertilizing notifications

## Status

Accepted

## Context

Per-plant fertilizing reminders produced a tray full of near-identical alerts
(often titled by growth stage, e.g. «Подкормка старта»), used unstable
`hashCode`-based notification IDs (so Accept could not cancel the right entry),
and scheduled with `ongoing` + `fullScreenIntent`. Accept often left the
notification visible. Seasonal STOP for Start plants could still fire because
frequency recalculation and reschedule ran in parallel on login. Users typically
fertilize plants in batches, so one reminder per plant was the wrong UX.

## Decision

### Batch schedule

Rebuild a **global** fertilizing schedule (not one pair of alarms per plant):

- Include only non-archived plants with active frequency (`> 0`). Quarantine may
  shift the next date when fertilizing is active; STOP plants get no fertilizing
  reminder (quarantine end stays on `QuarantineNotificationService`).
- Group by next due date:
  - due today or overdue → one day notification;
  - due tomorrow → eve (19:00) + day (08:00);
  - otherwise the earliest later due date → eve + day for that cohort.
- Fixed small notification IDs (`91001`–`91003`) to avoid Android
  `id * 16` PendingIntent overflow and cross-run hash collisions.
- On every reschedule: cancel those IDs, any pending payload with
  `fertilizing:`, and active notifications on the fertilizing channel (clears
  legacy per-plant leftovers).

### Copy

- Batch: title «Завтра подкормка» / «Подкормка сегодня», body = plant **count**
  (pluralized); overdue batch adds a short overdue note.
- Single plant: title «Подкормка: {name}» (nickname, else species), Accept
  button records fertilizing for that plant.
- No name lists in the tray. No stage wording. No full-screen / ongoing flags;
  notifications are dismissible (`autoCancel`).

### Accept

- Accept action only on single-plant day notifications.
- Opens the app (`showsUserInterface: true`) so auth/API are available; also
  handles cold start via `getNotificationAppLaunchDetails` after initialize.
- Explicitly cancels the notification id in Dart after Accept.
- Batch day notification has no Accept — tap opens the app only.

### Bootstrap order

On authenticated shell sync: await `recalculateAutoFertilizingFrequencies()`,
**then** `rescheduleAllActivePlants()` (or `cancelAll` when the feature flag is
off), so autumn STOP for Start is applied before scheduling.

## Implementation

- `lib/models/fertilizing_frequency.dart` — `groupFertilizingReminderTargets`,
  `fertilizingBatchDayFireAt`, `fertilizingBatchEveFireAt`
- `lib/services/fertilizing_notification_service.dart` — batch scheduler
- `lib/services/plant_service.dart` / `fertilize_service.dart` / `lib/main.dart`
  — always rebuild global schedule after changes
- l10n: count / single-plant reminder strings (ru/en/de/fr)

## Behavior

- Ten plants due the same day → one «Подкормка сегодня · 10 растений».
- One plant due after quarantine while others are on a shared cycle →
  «Подкормка: Монстера» with Accept.
- Start plants in northern autumn (STOP) → no fertilizing notification after
  login recalculation.
- Swiping away a batch reminder dismisses it without marking fertilizing done.

## Consequences

- Only the nearest future cohort (beyond tomorrow) is pre-scheduled; further
  dates wait until the next app open or fertilizing event rebuilds the plan.
- Accept-all for a batch is intentionally unsupported.
- Quarantine-only feeds without an active frequency no longer create fertilizing
  reminders (aligns with STOP).

## Verification

- `flutter gen-l10n`
- `flutter test test/fertilizing_frequency_test.dart`
- `flutter analyze` on touched Dart files
- Device tray / Accept not run in this change set
