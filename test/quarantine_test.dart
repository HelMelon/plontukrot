import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/fertilizing_frequency.dart';
import 'package:plontukrot/models/fertilizing_growth_season.dart';
import 'package:plontukrot/models/plant.dart';
import 'package:plontukrot/models/plant_filter_criteria.dart';
import 'package:plontukrot/models/quarantine.dart';
import 'package:plontukrot/models/quarantine_reason.dart';

void main() {
  group('quarantine helpers', () {
    test('quarantineEndDate is 14 days after start day', () {
      final start = DateTime(2026, 3, 1, 15, 30);
      expect(quarantineEndDate(start), DateTime(2026, 3, 15));
    });

    test('isPlantInQuarantine respects until boundary', () {
      final until = DateTime(2026, 3, 15, 9);
      expect(
        isPlantInQuarantine(
          quarantineUntil: until,
          now: DateTime(2026, 3, 14, 23),
        ),
        isTrue,
      );
      expect(
        isPlantInQuarantine(
          quarantineUntil: until,
          now: DateTime(2026, 3, 15, 10),
        ),
        isFalse,
      );
      expect(isPlantInQuarantine(quarantineUntil: null), isFalse);
    });

    test('first fertilizing after quarantine uses season delay', () {
      final until = DateTime(2026, 4, 1);
      expect(
        firstFertilizingAfterQuarantine(
          quarantineUntil: until,
          lastFertilizedAt: null,
          season: FertilizingGrowthSeason.springSummer,
        ),
        DateTime(2026, 4, 15),
      );
      expect(
        firstFertilizingAfterQuarantine(
          quarantineUntil: until,
          lastFertilizedAt: null,
          season: FertilizingGrowthSeason.autumnWinter,
        ),
        DateTime(2026, 4, 22),
      );
      expect(
        firstFertilizingAfterQuarantine(
          quarantineUntil: until,
          lastFertilizedAt: DateTime(2026, 4, 2),
          season: FertilizingGrowthSeason.springSummer,
        ),
        isNull,
      );
    });

    test('nextFertilizingDate defers to post-quarantine first feed', () {
      final until = DateTime(2026, 4, 1);
      final next = nextFertilizingDate(
        frequencyDays: 14,
        lastFertilizedAt: DateTime(2026, 3, 20),
        quarantineUntil: until,
        quarantineSeason: FertilizingGrowthSeason.springSummer,
      );
      // Normal next would be 2026-04-03; quarantine first feed is 2026-04-15.
      expect(next, DateTime(2026, 4, 15));
    });

    test('QuarantineReason parsing', () {
      expect(QuarantineReason.tryParse('purchase'), QuarantineReason.purchase);
      expect(QuarantineReason.tryParse('repotting'), QuarantineReason.repotting);
      expect(QuarantineReason.tryParse('transplant'), QuarantineReason.repotting);
      expect(QuarantineReason.tryParse('other'), isNull);
    });
  });

  group('PlantFilterCriteria quarantine', () {
    test('quarantineOnly matches active quarantine plants', () {
      final inQuarantine = Plant(
        id: '1',
        genus: 'Monstera',
        species: 'deliciosa',
        nickname: 'A',
        stage: 2,
        quarantineUntil: DateTime.now().add(const Duration(days: 5)),
        quarantineReason: QuarantineReason.purchase,
      );
      final clear = Plant(
        id: '2',
        genus: 'Monstera',
        species: 'deliciosa',
        nickname: 'B',
        stage: 2,
      );

      const criteria = PlantFilterCriteria(quarantineOnly: true);
      expect(criteria.activeCount, 1);
      expect(
        criteria.matches(inQuarantine, isPropagating: false, isRerooting: false),
        isTrue,
      );
      expect(
        criteria.matches(clear, isPropagating: false, isRerooting: false),
        isFalse,
      );
    });
  });
}
