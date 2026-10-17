import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/plant.dart';
import 'package:plontukrot/models/plant_filter_criteria.dart';
import 'package:plontukrot/models/room.dart';

void main() {
  group('PlantFilterCriteria', () {
    test('empty criteria matches all plants and is not active', () {
      const criteria = PlantFilterCriteria.empty;
      expect(criteria.isEmpty, isTrue);
      expect(criteria.isActive, isFalse);
      expect(criteria.activeCount, 0);

      final plant = Plant(
        id: '1',
        genus: 'Monstera',
        species: 'deliciosa',
        nickname: 'Monster',
        plantFamily: 'Araceae',
        stage: 2,
        createdAt: DateTime.now(),
      );

      expect(
        criteria.matches(plant, isPropagating: false, isRerooting: false),
        isTrue,
      );
    });

    test('matches filtering by family, genus, stage, propagating, rerooting', () {
      final plant1 = Plant(
        id: '1',
        genus: 'Monstera',
        species: 'deliciosa',
        cultivar: 'Thai Constellation',
        nickname: 'Thai',
        plantFamily: 'Araceae',
        stage: 2,
        createdAt: DateTime.now(),
      );

      final plant2 = Plant(
        id: '2',
        genus: 'Philodendron',
        species: 'erubescens',
        nickname: 'Philo',
        plantFamily: 'Araceae',
        stage: 1,
        createdAt: DateTime.now(),
      );

      const criteriaGenus = PlantFilterCriteria(genus: 'Monstera');
      expect(criteriaGenus.isActive, isTrue);
      expect(criteriaGenus.activeCount, 1);
      expect(
        criteriaGenus.matches(plant1, isPropagating: false, isRerooting: false),
        isTrue,
      );
      expect(
        criteriaGenus.matches(plant2, isPropagating: false, isRerooting: false),
        isFalse,
      );

      const criteriaCultivar = PlantFilterCriteria(cultivar: 'Thai Constellation');
      expect(
        criteriaCultivar.matches(plant1, isPropagating: false, isRerooting: false),
        isTrue,
      );
      expect(
        criteriaCultivar.matches(plant2, isPropagating: false, isRerooting: false),
        isFalse,
      );

      const criteriaProp = PlantFilterCriteria(propagatingOnly: true);
      expect(
        criteriaProp.matches(plant1, isPropagating: true, isRerooting: false),
        isTrue,
      );
      expect(
        criteriaProp.matches(plant1, isPropagating: false, isRerooting: false),
        isFalse,
      );

      const criteriaReroot = PlantFilterCriteria(rerootingOnly: true);
      expect(
        criteriaReroot.matches(plant1, isPropagating: false, isRerooting: true),
        isTrue,
      );
      expect(
        criteriaReroot.matches(plant1, isPropagating: false, isRerooting: false),
        isFalse,
      );
    });

    test('serialization roundtrip works', () {
      const criteria = PlantFilterCriteria(
        propagatingOnly: true,
        plantFamily: 'Araceae',
        genus: 'Monstera',
        cultivar: 'Albo',
        stage: 3,
        presetId: 'p1',
        presetName: 'My Preset',
      );

      final map = criteria.toMap();
      final restored = PlantFilterCriteria.fromMap(map);

      expect(restored.propagatingOnly, criteria.propagatingOnly);
      expect(restored.groupsOnly, criteria.groupsOnly);
      expect(restored.plantFamily, criteria.plantFamily);
      expect(restored.genus, criteria.genus);
      expect(restored.cultivar, criteria.cultivar);
      expect(restored.stage, criteria.stage);
      expect(restored.presetId, criteria.presetId);
      expect(restored.presetName, criteria.presetName);
      expect(restored.activeCount, criteria.activeCount);
    });

    test('PlantFilterPreset serialization roundtrip works', () {
      final preset = PlantFilterPreset(
        id: '123',
        name: 'Monstera Care',
        criteria: const PlantFilterCriteria(
          genus: 'Monstera',
          propagatingOnly: true,
        ),
        createdAt: DateTime.utc(2026, 8, 28, 12, 0, 0),
      );

      final map = preset.toMap();
      final restored = PlantFilterPreset.fromMap(map);

      expect(restored.id, preset.id);
      expect(restored.name, preset.name);
      expect(restored.criteria.genus, 'Monstera');
      expect(restored.criteria.propagatingOnly, isTrue);
      expect(restored.createdAt, preset.createdAt);
    });

    test('room filter matches the balcony and a custom room', () {
      final balcony = Plant(
        id: 'b',
        genus: 'Ficus',
        species: 'elastica',
        nickname: 'Balcony ficus',
        stage: 2,
        onBalcony: true,
      );
      final kitchen = Plant(
        id: 'k',
        genus: 'Ficus',
        species: 'elastica',
        nickname: 'Kitchen ficus',
        stage: 2,
        roomId: 'kitchen',
      );

      const balconyFilter = PlantFilterCriteria(roomId: Room.balconyId);
      const kitchenFilter = PlantFilterCriteria(roomId: 'kitchen');

      expect(
        balconyFilter.matches(balcony, isPropagating: false, isRerooting: false),
        isTrue,
      );
      expect(
        balconyFilter.matches(kitchen, isPropagating: false, isRerooting: false),
        isFalse,
      );
      expect(
        kitchenFilter.matches(kitchen, isPropagating: false, isRerooting: false),
        isTrue,
      );
      expect(balconyFilter.isActive, isTrue);
      expect(balconyFilter.activeCount, 1);
      expect(
        PlantFilterCriteria.fromMap(balconyFilter.toMap()).roomId,
        Room.balconyId,
      );
    });

    test('fertilizingDueOnly matches plants due today or overdue', () {
      final now = DateTime(2026, 10, 16, 12);
      final due = Plant(
        id: 'due',
        genus: 'Hoya',
        species: 'carnosa',
        nickname: 'Due',
        stage: 2,
        fertilizingFrequencyDays: 14,
        lastFertilizedAt: now.subtract(const Duration(days: 14)),
        createdAt: now.subtract(const Duration(days: 40)),
      );
      final waiting = Plant(
        id: 'wait',
        genus: 'Hoya',
        species: 'carnosa',
        nickname: 'Wait',
        stage: 2,
        fertilizingFrequencyDays: 14,
        lastFertilizedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 40)),
      );
      final stopped = Plant(
        id: 'stop',
        genus: 'Hoya',
        species: 'carnosa',
        nickname: 'Stop',
        stage: 2,
        fertilizingFrequencyDays: 0,
        lastFertilizedAt: now.subtract(const Duration(days: 40)),
        createdAt: now.subtract(const Duration(days: 40)),
      );

      const criteria = PlantFilterCriteria(fertilizingDueOnly: true);
      expect(criteria.isActive, isTrue);
      expect(criteria.activeCount, 1);
      expect(
        criteria.matches(
          due,
          isPropagating: false,
          isRerooting: false,
          now: now,
        ),
        isTrue,
      );
      expect(
        criteria.matches(
          waiting,
          isPropagating: false,
          isRerooting: false,
          now: now,
        ),
        isFalse,
      );
      expect(
        criteria.matches(
          stopped,
          isPropagating: false,
          isRerooting: false,
          now: now,
        ),
        isFalse,
      );
      expect(
        PlantFilterCriteria.fromMap(criteria.toMap()).fertilizingDueOnly,
        isTrue,
      );
    });
  });
}
