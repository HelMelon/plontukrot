import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/fertilizing_frequency.dart';
import 'package:plontukrot/models/fertilizing_growth_season.dart';

void main() {
  group('fertilizingPeriodDays', () {
    test('spring/summer intervals by stage', () {
      expect(
        fertilizingPeriodDays(
          stage: 1,
          season: FertilizingGrowthSeason.springSummer,
        ),
        21,
      );
      expect(
        fertilizingPeriodDays(
          stage: 2,
          season: FertilizingGrowthSeason.springSummer,
        ),
        14,
      );
      expect(
        fertilizingPeriodDays(
          stage: 3,
          season: FertilizingGrowthSeason.springSummer,
        ),
        14,
      );
      expect(
        fertilizingPeriodDays(
          stage: 4,
          season: FertilizingGrowthSeason.springSummer,
        ),
        18,
      );
    });

    test('autumn/winter intervals by stage', () {
      expect(
        fertilizingPeriodDays(
          stage: 1,
          season: FertilizingGrowthSeason.autumnWinter,
        ),
        isNull,
      );
      expect(
        fertilizingPeriodDays(
          stage: 2,
          season: FertilizingGrowthSeason.autumnWinter,
        ),
        28,
      );
      expect(
        fertilizingPeriodDays(
          stage: 3,
          season: FertilizingGrowthSeason.autumnWinter,
        ),
        24,
      );
      expect(
        fertilizingPeriodDays(
          stage: 4,
          season: FertilizingGrowthSeason.autumnWinter,
        ),
        28,
      );
    });

    test('stage 0 normalizes to start', () {
      expect(
        fertilizingPeriodDays(
          stage: 0,
          season: FertilizingGrowthSeason.springSummer,
        ),
        21,
      );
    });
  });

  group('FertilizingSeasonSettings', () {
    const northern = FertilizingSeasonSettings(
      mode: FertilizingSeasonMode.northern,
    );

    test('northern hemisphere defaults', () {
      expect(northern.growthSeasonForMonth(4),
          FertilizingGrowthSeason.springSummer);
      expect(northern.growthSeasonForMonth(9),
          FertilizingGrowthSeason.springSummer);
      expect(northern.growthSeasonForMonth(10),
          FertilizingGrowthSeason.autumnWinter);
      expect(northern.growthSeasonForMonth(1),
          FertilizingGrowthSeason.autumnWinter);
    });

    test('southern hemisphere swaps seasons', () {
      const southern = FertilizingSeasonSettings(
        mode: FertilizingSeasonMode.southern,
      );
      expect(southern.growthSeasonForMonth(4),
          FertilizingGrowthSeason.autumnWinter);
      expect(southern.growthSeasonForMonth(10),
          FertilizingGrowthSeason.springSummer);
    });
  });

  group('notification schedule dates', () {
    final created = DateTime(2026, 4, 1);
    const frequency = 14;

    test('next date from last fertilized', () {
      final last = DateTime(2026, 4, 10);
      expect(
        nextFertilizingDate(
          frequencyDays: frequency,
          lastFertilizedAt: last,
          createdAt: created,
        ),
        DateTime(2026, 4, 24),
      );
    });

    test('eve notification at 19:00 day before', () {
      final now = DateTime(2026, 4, 20, 12);
      final last = DateTime(2026, 4, 10);
      expect(
        fertilizingEveNotificationAt(
          frequencyDays: frequency,
          lastFertilizedAt: last,
          createdAt: created,
          now: now,
        ),
        DateTime(2026, 4, 23, 19),
      );
    });

    test('day notification at 08:00 on feeding day', () {
      final now = DateTime(2026, 4, 20, 12);
      final last = DateTime(2026, 4, 10);
      expect(
        fertilizingDayNotificationAt(
          frequencyDays: frequency,
          lastFertilizedAt: last,
          createdAt: created,
          now: now,
        ),
        DateTime(2026, 4, 24, 8),
      );
    });

    test('null frequency yields no schedule', () {
      expect(
        nextFertilizingDate(
          frequencyDays: null,
          lastFertilizedAt: DateTime(2026, 4, 10),
        ),
        isNull,
      );
      expect(
        fertilizingEveNotificationAt(
          frequencyDays: null,
          lastFertilizedAt: DateTime(2026, 4, 10),
        ),
        isNull,
      );
    });

    test('missed due date schedules soon after now', () {
      final now = DateTime(2026, 4, 25, 9);
      final last = DateTime(2026, 4, 10);
      final scheduled = fertilizingDayNotificationAt(
        frequencyDays: frequency,
        lastFertilizedAt: last,
        createdAt: created,
        now: now,
      );
      expect(scheduled, isNotNull);
      expect(scheduled!.isAfter(now), isTrue);
    });

    test('overdue day notification schedules soon after now', () {
      final now = DateTime(2026, 9, 2, 11, 18);
      final last = DateTime(2026, 8, 16);
      final scheduled = fertilizingDayNotificationAt(
        frequencyDays: 14,
        lastFertilizedAt: last,
        now: now,
      );
      expect(scheduled, isNotNull);
      expect(scheduled!.isAfter(now), isTrue);
      expect(
        scheduled.difference(now).inSeconds,
        lessThanOrEqualTo(5),
      );
    });

    test('due today before 08:00 schedules at 08:00', () {
      final now = DateTime(2026, 8, 30, 6);
      final last = DateTime(2026, 8, 16);
      expect(
        fertilizingDayNotificationAt(
          frequencyDays: 14,
          lastFertilizedAt: last,
          now: now,
        ),
        DateTime(2026, 8, 30, 8),
      );
    });
  });

  group('isFertilizingOverdue', () {
    test('true when due date is before today', () {
      expect(
        isFertilizingOverdue(
          frequencyDays: 14,
          lastFertilizedAt: DateTime(2026, 8, 16),
          now: DateTime(2026, 9, 2),
        ),
        isTrue,
      );
    });

    test('true on due day', () {
      expect(
        isFertilizingOverdue(
          frequencyDays: 14,
          lastFertilizedAt: DateTime(2026, 8, 16),
          now: DateTime(2026, 8, 30, 6),
        ),
        isTrue,
      );
    });

    test('false before due day', () {
      expect(
        isFertilizingOverdue(
          frequencyDays: 14,
          lastFertilizedAt: DateTime(2026, 8, 16),
          now: DateTime(2026, 8, 29),
        ),
        isFalse,
      );
    });

    test('false when fertilizing is stopped', () {
      expect(
        isFertilizingOverdue(
          frequencyDays: fertilizingFrequencyStop,
          lastFertilizedAt: DateTime(2026, 8, 16),
          now: DateTime(2026, 9, 2),
        ),
        isFalse,
      );
    });

    test('false when archived', () {
      expect(
        isFertilizingOverdue(
          frequencyDays: 14,
          lastFertilizedAt: DateTime(2026, 8, 16),
          now: DateTime(2026, 9, 2),
          isArchived: true,
        ),
        isFalse,
      );
    });
  });

  group('resolveFertilizingFrequencyDays', () {
    test('custom override preserves user value', () {
      expect(
        resolveFertilizingFrequencyDays(
          stage: 2,
          seasonSettings: const FertilizingSeasonSettings(),
          isCustom: true,
          currentFrequencyDays: 99,
          when: DateTime(2026, 5, 1),
        ),
        99,
      );
    });

    test('auto uses season table', () {
      expect(
        resolveFertilizingFrequencyDays(
          stage: 1,
          seasonSettings: const FertilizingSeasonSettings(),
          isCustom: false,
          currentFrequencyDays: 99,
          when: DateTime(2026, 11, 1),
        ),
        fertilizingFrequencyStop,
      );
    });

    test('zero means stop for scheduling', () {
      expect(isFertilizingActive(0), isFalse);
      expect(isFertilizingActive(14), isTrue);
      expect(
        nextFertilizingDate(
          frequencyDays: fertilizingFrequencyStop,
          lastFertilizedAt: DateTime(2026, 4, 10),
        ),
        isNull,
      );
    });
  });
}
