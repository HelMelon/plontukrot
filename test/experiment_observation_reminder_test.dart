import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/experiment.dart';
import 'package:plontukrot/models/experiment_observation_reminder.dart';

int _calendarDaysBetween(DateTime earlier, DateTime later) {
  final from = DateTime.utc(earlier.year, earlier.month, earlier.day);
  final to = DateTime.utc(later.year, later.month, later.day);
  return to.difference(from).inDays;
}

void main() {
  group('nextExperimentObservationReminderAt', () {
    test('before 10:00 on a grid day fires that morning', () {
      // 2026-01-01 is a grid day: its UTC ordinal since 1970-01-01 % 3 == 0.
      final day = DateTime.utc(2026, 1, 1);
      expect(
        day.difference(DateTime.utc(1970, 1, 1)).inDays % 3,
        0,
      );

      final next = nextExperimentObservationReminderAt(
        DateTime(2026, 1, 1, 9, 15),
      );
      expect(next, DateTime(2026, 1, 1, 10));
    });

    test('at or after 10:00 waits three calendar days', () {
      expect(
        nextExperimentObservationReminderAt(DateTime(2026, 1, 1, 10)),
        DateTime(2026, 1, 4, 10),
      );
      expect(
        nextExperimentObservationReminderAt(DateTime(2026, 1, 1, 18, 40)),
        DateTime(2026, 1, 4, 10),
      );
    });

    test('a non-grid day lands on the next 10:00 grid morning', () {
      // 2026-10-18 is not a grid day; 2026-10-19 is.
      final next = nextExperimentObservationReminderAt(
        DateTime(2026, 10, 18, 23, 50),
      );
      expect(next, DateTime(2026, 10, 19, 10));
    });

    test('crosses a month boundary at 10:00 every 3 days', () {
      final times = upcomingExperimentObservationReminders(
        DateTime(2026, 1, 31, 11),
        count: 4,
      );
      expect(times, [
        DateTime(2026, 2, 3, 10),
        DateTime(2026, 2, 6, 10),
        DateTime(2026, 2, 9, 10),
        DateTime(2026, 2, 12, 10),
      ]);
      for (final time in times) {
        expect(time.hour, 10);
        expect(time.minute, 0);
        expect(time.second, 0);
        expect(isExperimentObservationReminderDay(time), isTrue);
      }
      for (var i = 1; i < times.length; i++) {
        expect(_calendarDaysBetween(times[i - 1], times[i]), 3);
      }
    });

    test('refreshing from a later clock does not shift the phase', () {
      final first = nextExperimentObservationReminderAt(
        DateTime(2026, 10, 19, 8),
      );
      final again = nextExperimentObservationReminderAt(
        DateTime(2026, 10, 20, 15),
      );
      expect(first, DateTime(2026, 10, 19, 10));
      expect(again, DateTime(2026, 10, 22, 10));
      expect(_calendarDaysBetween(first, again), 3);
    });
  });

  group('experimentWantsObservationReminder', () {
    const active = Experiment(id: 'a', title: 'Кокос');

    test('open experiments qualify', () {
      expect(experimentWantsObservationReminder(active), isTrue);
    });

    test('completed and archived experiments do not', () {
      expect(
        experimentWantsObservationReminder(
          Experiment(
            id: 'a',
            title: 'Кокос',
            completedAt: DateTime(2026, 10, 1),
          ),
        ),
        isFalse,
      );
      expect(
        experimentWantsObservationReminder(
          Experiment(
            id: 'a',
            title: 'Кокос',
            archivedAt: DateTime(2026, 10, 1),
          ),
        ),
        isFalse,
      );
    });
  });

  test('horizon ids stay in a stable range', () {
    expect(experimentObservationReminderId(0), 92010);
    expect(
      experimentObservationReminderId(experimentObservationReminderHorizon - 1),
      92019,
    );
    expect(experimentObservationReminderHorizon, 10);
  });
}
