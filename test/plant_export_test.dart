import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/features/plants/export/plant_export.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/manipulation_entry.dart';
import 'package:plontukrot/models/manipulation_type.dart';
import 'package:plontukrot/models/note.dart';
import 'package:plontukrot/models/plant.dart';
import 'package:plontukrot/models/propagation.dart';
import 'package:plontukrot/models/propagation_method.dart';
import 'package:plontukrot/models/propagation_status.dart';
import 'package:plontukrot/models/watering_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ru'));
  });

  Plant plant() {
    return Plant(
      id: 'p1',
      genus: 'Monstera',
      species: 'deliciosa',
      plantFamily: 'Araceae',
      nickname: 'Монти',
      stage: 4,
      createdAt: DateTime(2024, 3, 2, 15),
    );
  }

  test('catalog fields stay in the agreed order', () {
    final payload = plantIdentityPayload(
      plant(),
      l10n,
      PlantExportField.values.toSet(),
    );
    expect(payload.keys.toList(), [
      'createdAt',
      'family',
      'genus',
      'species',
      'cultivar',
      'stage',
      'nickname',
    ]);
    expect(payload['createdAt'], '2024-03-02');
    expect(payload['family'], 'Araceae');
    expect(payload['stage'], '🌴 Взрослое');
    expect(payload['nickname'], 'Монти');
  });

  test('catalog omits unchecked fields and keeps order', () {
    final payload = plantCatalogPayload(
      uid: 'u1',
      plants: [plant()],
      l10n: l10n,
      fields: {
        PlantExportField.nickname,
        PlantExportField.genus,
        PlantExportField.createdAt,
      },
      exportedAt: DateTime.utc(2026, 1, 1),
    );
    expect(payload['fields'], ['createdAt', 'genus', 'nickname']);
    final stages = payload['stages'] as List<Map<String, dynamic>>;
    final row = (stages.single['plants'] as List).single as Map;
    expect(row.keys.toList(), ['createdAt', 'genus', 'nickname']);
  });

  test('journal groups events by calendar day', () {
    final payload = plantJournalPayload(
      plant: plant(),
      l10n: l10n,
      exportedAt: DateTime.utc(2026, 1, 1),
      journal: PlantJournalExport(
        waterings: [
          WateringEntry(wateredAt: DateTime(2025, 6, 1, 8)),
        ],
        fertilizings: const [],
        repottings: const [],
        manipulations: [
          ManipulationEntry(
            id: 'm1',
            type: ManipulationType.pinching,
            appliedAt: DateTime(2025, 6, 1, 18),
            note: 'верхушка',
          ),
        ],
        notes: [
          Note(
            id: 'n1',
            text: 'новый лист',
            createdAt: DateTime(2025, 5, 20),
          ),
        ],
        propagations: [
          Propagation(
            id: 'b1',
            parentPlantId: 'p1',
            parentPlantName: 'deliciosa',
            parentPlantFamily: 'Araceae',
            method: PropagationMethod.cutting,
            quantity: 2,
            quantityAlive: 2,
            soldQuantity: 0,
            lostQuantity: 0,
            stage: 1,
            status: PropagationStatus.active,
            startedAt: DateTime(2025, 6, 1),
          ),
        ],
      ),
    );

    expect(payload['propagationBatchCount'], 1);
    final days = payload['days'] as List<Map<String, dynamic>>;
    expect(days.map((day) => day['date']), ['2025-05-20', '2025-06-01']);
    final june = days[1]['events'] as List<Map<String, dynamic>>;
    expect(june.map((event) => event['type']), [
      'watering',
      'manipulation',
      'propagation',
    ]);
    expect(june[1]['kind'], 'Прищипка');
    expect(june[1]['note'], 'верхушка');
  });

  test('markdown catalog and journal use localized labels', () {
    final source = plant();
    final catalog = plantCatalogMarkdown(
      plants: [source],
      l10n: l10n,
      fields: PlantExportField.values.toSet(),
    );
    expect(catalog, contains('# Экспорт растений'));
    expect(catalog, contains('**Прозвище:** Монти'));
    expect(catalog, contains('**Дата добавления:** 2024-03-02'));

    final journal = plantJournalMarkdown(
      plant: source,
      l10n: l10n,
      journal: const PlantJournalExport(
        waterings: [],
        fertilizings: [],
        repottings: [],
        manipulations: [],
        notes: [],
        propagations: [],
      ),
    );
    expect(journal, startsWith('# Монти'));
    expect(journal, contains('**Партий размножения: 0**'));
  });
}
