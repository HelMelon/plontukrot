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

    test('past notifications are not returned', () {
      final now = DateTime(2026, 4, 25, 9);
      final last = DateTime(2026, 4, 10);
      expect(
        fertilizingDayNotificationAt(
          frequencyDays: frequency,
          lastFertilizedAt: last,
          createdAt: created,
          now: now,
        ),
        isNull,
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
