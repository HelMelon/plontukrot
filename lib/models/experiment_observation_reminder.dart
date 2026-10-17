import 'experiment.dart';

/// Days between experiment-observation reminders.
const experimentObservationReminderIntervalDays = 3;

/// Local wall-clock hour for the reminder (10:00).
const experimentObservationReminderHour = 10;

/// How many future fires to keep pending.
///
/// `flutter_local_notifications` can repeat a clock time daily or weekly, or
/// repeat on a raw duration that is not pinned to 10:00. It cannot express
/// "every 3 days at 10:00". Each fire is its own one-shot on this calendar
/// grid. Ten fires cover 30 days; the next app launch refreshes the window.
const experimentObservationReminderHorizon = 10;

/// Stable notification ids for the horizon, soonest fire first.
///
/// Kept away from fertilizing batch ids (`91001`–`91003`) and quarantine ids
/// (`hash + 0x30000000`).
const experimentObservationReminderIdBase = 92010;

int experimentObservationReminderId(int slot) =>
    experimentObservationReminderIdBase + slot;

/// An open trial still needs observation reminders. Finished and archived
/// trials do not.
bool experimentWantsObservationReminder(Experiment experiment) =>
    !experiment.isCompleted && !experiment.isArchived;

/// UTC day ordinal of the local calendar date, so DST does not shift the phase.
int experimentObservationReminderDayIndex(DateTime localDay) {
  final utcDay = DateTime.utc(localDay.year, localDay.month, localDay.day);
  return utcDay.difference(DateTime.utc(1970, 1, 1)).inDays;
}

/// Reminder days are those whose ordinal since 1970-01-01 is divisible by 3.
bool isExperimentObservationReminderDay(DateTime localDay) {
  return experimentObservationReminderDayIndex(localDay) %
          experimentObservationReminderIntervalDays ==
      0;
}

/// Next local 10:00 on the every-3-days grid, strictly after [now].
///
/// The phase is fixed (not "3 days from the last app open"), so refreshing the
/// schedule does not push the reminder forward.
DateTime nextExperimentObservationReminderAt(DateTime now) {
  var day = DateTime(now.year, now.month, now.day);
  for (var step = 0;
      step <= experimentObservationReminderIntervalDays;
      step++) {
    if (isExperimentObservationReminderDay(day)) {
      final candidate = DateTime(
        day.year,
        day.month,
        day.day,
        experimentObservationReminderHour,
      );
      if (candidate.isAfter(now)) return candidate;
    }
    day = DateTime(day.year, day.month, day.day + 1);
  }
  throw StateError('No experiment observation reminder within the interval');
}

/// Upcoming local fire times, soonest first. Each is 3 calendar days after the
/// previous, at 10:00.
List<DateTime> upcomingExperimentObservationReminders(
  DateTime now, {
  int count = experimentObservationReminderHorizon,
}) {
  if (count <= 0) return const [];
  final times = <DateTime>[];
  var cursor = now;
  for (var i = 0; i < count; i++) {
    final next = nextExperimentObservationReminderAt(cursor);
    times.add(next);
    cursor = next;
  }
  return times;
}
