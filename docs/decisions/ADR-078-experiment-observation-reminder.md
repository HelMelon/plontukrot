# ADR-078: Experiment observation reminder

## Status

Accepted

## Context

Active experiments need a local reminder to log observations: every 3 days at
10:00 in the user's local time. Fertilizing and quarantine reminders already
use `flutter_local_notifications`, `timezone`, and `flutter_timezone`. That
plugin can repeat a clock time daily or weekly, or repeat on a raw duration
that is not pinned to 10:00. It cannot express "every 3 days at 10:00".

Care reminders do not open a specific screen when tapped. Permission is
requested from the existing startup path and from the profile notifications
control, both through `FertilizingNotificationService`.

## Decision

Schedule the reminder on the same plugin singleton. Time zone setup and
permission stay on `FertilizingNotificationService` (`initialize`,
`requestPermission`, `isPermissionGranted`). Do not add a notification plugin
or a new permission prompt.

The reminder has its own Android channel, `experiment_observation_reminders`,
the same way quarantine reminders use their own channel. The fertilizing
channel stays labeled for fertilizing. Channel name, description, title, and
body come from l10n for the locale at schedule time (ru, en, de, fr).

### When it fires

Schedule only when `FeatureFlag.experiments` is enabled and at least one
experiment is neither completed nor archived. Otherwise cancel the series.

The clock is local 10:00, built as a local `DateTime` and passed through
`tz.TZDateTime.from`, matching fertilizing (08:00) and quarantine (09:00).

The calendar phase is fixed: a local date is a reminder day when its UTC day
ordinal since 1970-01-01 is divisible by 3. The next fire is the next such
10:00 strictly after now. Refreshing the schedule does not restart the 3-day
count from "now".

Because the plugin cannot repeat that pattern, the app keeps the next 10
fires as exact one-shots (`exactAllowWhileIdle`). That window reaches at most
30 days ahead. Notification ids are stable: `92010` through `92019` (soonest
first), clear of fertilizing ids `91001`–`91003` and quarantine ids. Each
reschedule cancels that id range and any pending payload
`experiment_observation` before writing, so a refresh does not stack a second
series.

### When it is refreshed

There is no single reschedule for every reminder. This one refreshes where
care reminders already refresh, and when an experiment write changes whether
any trial is active:

- authenticated startup (`_syncPreferences`), next to fertilizing and quarantine;
- after the existing permission request succeeds (startup, and the profile
  control);
- after an experiment is created, completed, reopened, or deleted.

Startup also calls the existing `requestPermission` when the experiments flag
is on, so the OS prompt is the same one fertilizing already uses. The
experiment service does not prompt. If permission is missing, the series is
cancelled and nothing is scheduled.

A failed reschedule is logged and does not fail the experiment write.

### Tap

The payload marks the series so it can be cancelled. It is not a route.
Tapping opens the app, which is what fertilizing and quarantine taps already do
(fertilizing only handles its Accept action).

## Implementation

- `lib/models/experiment_observation_reminder.dart` — grid, next fire, horizon,
  active-experiment rule, stable ids.
- `lib/services/experiment_observation_notification_service.dart` — cancel and
  schedule on the shared plugin.
- `ExperimentService` refetches experiments and reschedules after create,
  completion change, and delete. The reschedule is fire-and-forget
  (`unawaited`): it refetches the list and writes ten alarms, so an experiment
  write must not wait on it.
- Startup and the profile permission grant call the same reschedule.
- Copy: `experimentObservationReminderTitle`, `experimentObservationReminderBody`,
  and the channel name and description in ru, en, de, fr.

The client does not write `archived_at`. Archived experiments are skipped when
they are present on the fetched list. The next startup or experiment write
drops the reminder if none remain active.

## Behavior

With the experiments flag on, permission granted, and at least one open
experiment, the user gets a notification at 10:00 local on the 3-day grid
(for example 1 Jan 2026, then 4 Jan, 7 Jan). The title and body ask them to
record observations for their experiments, in the current app locale.

Completing, reopening, creating, or deleting an experiment rebuilds the
series. If every experiment is completed or archived, or the flag is off, the
pending notifications are removed.

Opening the app on 20 Oct does not move a 22 Oct 10:00 reminder to "three days
from today". It replaces the same ids with the same future grid.

If the app stays closed past the tenth scheduled fire, later 10:00 slots are
planned the next time startup or an experiment write runs.

## Consequences

The series continues for about a month without opening the app, then needs a
refresh. A duration-based repeat would not stay on 10:00, and a daily match
would fire every morning.

Notification text is captured when the alarm is scheduled. A locale change
applies on the next refresh, same as fertilizing and quarantine.

The first launch can schedule only after the permission dialog returns. The
startup permission callback reschedules when it is granted.

## Verification

- `flutter test test/experiment_observation_reminder_test.dart` — 8 tests
  passed, including next fire at 10:00 every 3 calendar days across a month
  boundary, and exclusion of completed and archived experiments.
- `flutter analyze` on the touched Dart files — no issues.
- No device or emulator check of the system notification.
