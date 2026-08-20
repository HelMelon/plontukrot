import '../models/fertilizer.dart';
import '../models/fertilizer_application_method.dart';
import '../models/fertilizer_dose.dart';
import '../models/fertilizer_ingredient.dart';
import '../models/fertilizing_entry.dart';
import '../models/model_helpers.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'growth_event_service.dart';
import 'fertilizing_notification_service.dart';
import 'plant_service.dart';
import 'rest_stream.dart';
import 'watering_service.dart';

class FertilizeService {
  final ApiClient _api = ApiClient.instance;

  String? get uid => null;

  Future<List<FertilizerIngredient>> _fetchIngredients() async {
    final list = jsonMapList(await _api.get('/components'));
    return list
        .map((m) => FertilizerIngredient.fromMap(readString(m, 'id') ?? '', m))
        .toList();
  }

  Future<List<Fertilizer>> _fetchFertilizers() async {
    final list = jsonMapList(await _api.get('/fertilizers'));
    return list
        .map((m) => Fertilizer.fromMap(readString(m, 'id') ?? '', m))
        .toList()
      ..sort((a, b) {
        final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
  }

  Future<FertilizerIngredient?> findIngredientByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    for (final item in await _fetchIngredients()) {
      if (item.name.trim().toLowerCase() == lower) return item;
    }
    return null;
  }

  Future<String> ensureIngredient({required String name}) async {
    final existing = await findIngredientByName(name);
    if (existing != null) return existing.id;
    return addIngredient(name: name);
  }

  Future<String> addIngredient({required String name}) async {
    final created = jsonMap(await _api.post('/components', body: {
      'name': name.trim(),
    }));
    return readString(created, 'id') ?? '';
  }

  Future<void> updateIngredient({
    required String ingredientId,
    required String name,
  }) async {
    try {
      await _api.patch('/components/$ingredientId', body: {
        'name': name.trim(),
      });
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> deleteIngredient(String ingredientId) async {
    await _api.delete('/components/$ingredientId');
  }

  Stream<List<FertilizerIngredient>> getIngredients() {
    return restPollStream(() async {
      final items = await _fetchIngredients();
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    });
  }

  Future<Fertilizer?> findFertilizerByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    for (final item in await _fetchFertilizers()) {
      if (item.name.trim().toLowerCase() == lower) return item;
    }
    return null;
  }

  Future<String> ensureFertilizer({
    required String name,
    FertilizerKind kind = FertilizerKind.mix,
    int waterMl = 250,
    List<FertilizerDose> components = const [],
  }) async {
    final existing = await findFertilizerByName(name);
    if (existing != null) return existing.id;
    return addFertilizer(
      name: name,
      kind: kind,
      waterMl: waterMl,
      components: components,
    );
  }

  Future<String> addFertilizer({
    required String name,
    FertilizerKind kind = FertilizerKind.mix,
    int waterMl = 250,
    List<FertilizerDose> components = const [],
  }) async {
    final created = jsonMap(await _api.post('/fertilizers', body: {
      'name': name.trim(),
      'kind': kind.index,
      'water_ml': normalizeWaterMl(waterMl),
      'components': components.map((e) => e.toMap()).toList(),
    }));
    return readString(created, 'id') ?? '';
  }

  Future<void> updateFertilizer({
    required String fertilizerId,
    required String name,
    required FertilizerKind kind,
    required int waterMl,
    required List<FertilizerDose> components,
  }) async {
    try {
      await _api.patch('/fertilizers/$fertilizerId', body: {
        'name': name.trim(),
        'kind': kind.index,
        'water_ml': normalizeWaterMl(waterMl),
        'components': components.map((e) => e.toMap()).toList(),
      });
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> deleteFertilizer(String fertilizerId) async {
    await _api.delete('/fertilizers/$fertilizerId');
  }

  Stream<List<Fertilizer>> getFertilizers() {
    return restPollStream(_fetchFertilizers);
  }

  Future<Fertilizer?> getFertilizer(String fertilizerId) async {
    for (final item in await _fetchFertilizers()) {
      if (item.id == fertilizerId) return item;
    }
    return null;
  }

  static String? resolveStoredFertilizerName(Map<String, dynamic> data) {
    final stored = readString(data, 'fertilizerName')?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return null;
  }

  Future<List<FertilizingEntry>> _fetchHistory(String plantId) async {
    final list = jsonMapList(await _api.get('/plants/$plantId/fertilizings'));
    final entries = list.map((data) {
      return FertilizingEntry.fromFirestoreData(
        id: readString(data, 'id') ?? '',
        data: data,
        fertilizerName: resolveStoredFertilizerName(data) ?? '',
      );
    }).toList()
      ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    return entries;
  }

  Future<void> addFertilizing({
    required String plantId,
    required DateTime appliedAt,
    required List<FertilizerDose> components,
    required int waterMl,
    required FertilizerApplicationMethod applicationMethod,
    String? fertilizerId,
    String? fertilizerName,
    DateTime? nextFertilizing,
    DateTime? lastFertilizedAt,
    DateTime? lastWateredAt,
    int? wateringFrequency,
    bool skipPlantFetch = false,
  }) async {
    final trimmedName = fertilizerName?.trim();
    final storedName =
        (trimmedName != null && trimmedName.isNotEmpty) ? trimmedName : null;

    await _api.post('/plants/$plantId/fertilizings', body: {
      if (fertilizerId != null) 'fertilizer_id': fertilizerId,
      if (storedName != null) 'fertilizer_name': storedName,
      'water_ml': normalizeWaterMl(waterMl),
      'components': components.map((e) => e.toMap()).toList(),
      'applied_at': isoDate(appliedAt),
      'application_method': applicationMethod.code,
      'next_fertilizing': isoDateOrNull(nextFertilizing),
    });

    await GrowthEventService().addFertilizingEvent(plantId, at: appliedAt);

    await WateringService().addWateringIfMissingBeforeFertilizing(
      plantId: plantId,
      fertilizedAt: appliedAt,
      lastWateredAt: lastWateredAt,
      wateringFrequency: wateringFrequency,
      skipPlantFetch: skipPlantFetch || lastWateredAt != null,
    );

    final plant = await PlantService().getPlant(plantId);
    if (plant != null) {
      await FertilizingNotificationService.instance.rescheduleForPlant(plant);
    }
  }

  Future<void> addFertilizings({
    required Iterable<String> plantIds,
    required DateTime appliedAt,
    required List<FertilizerDose> components,
    required int waterMl,
    required FertilizerApplicationMethod applicationMethod,
    String? fertilizerId,
    String? fertilizerName,
    DateTime? nextFertilizing,
    Map<String, DateTime?> lastFertilizedAtByPlantId = const {},
    Map<String, DateTime?> lastWateredAtByPlantId = const {},
    Map<String, int?> wateringFrequencyByPlantId = const {},
  }) async {
    for (final plantId in plantIds) {
      await addFertilizing(
        plantId: plantId,
        appliedAt: appliedAt,
        components: components,
        waterMl: waterMl,
        applicationMethod: applicationMethod,
        fertilizerId: fertilizerId,
        fertilizerName: fertilizerName,
        nextFertilizing: nextFertilizing,
        lastFertilizedAt: lastFertilizedAtByPlantId[plantId],
        lastWateredAt: lastWateredAtByPlantId[plantId],
        wateringFrequency: wateringFrequencyByPlantId[plantId],
        skipPlantFetch: true,
      );
    }
  }

  Future<void> updateFertilizing({
    required String plantId,
    required String fertilizingId,
    required DateTime appliedAt,
    required List<FertilizerDose> components,
    required int waterMl,
    required FertilizerApplicationMethod applicationMethod,
    String? fertilizerId,
    String? fertilizerName,
    DateTime? nextFertilizing,
  }) async {
    final trimmedName = fertilizerName?.trim();
    final storedName =
        (trimmedName != null && trimmedName.isNotEmpty) ? trimmedName : null;
    try {
      await _api.patch('/plants/$plantId/fertilizings/$fertilizingId', body: {
        'fertilizer_id': fertilizerId,
        'fertilizer_name': storedName,
        'water_ml': normalizeWaterMl(waterMl),
        'components': components.map((e) => e.toMap()).toList(),
        'applied_at': isoDate(appliedAt),
        'application_method': applicationMethod.code,
        'next_fertilizing': isoDateOrNull(nextFertilizing),
      });
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Stream<List<FertilizingEntry>> getFertilizingHistory(
    String plantId, {
    int limit = 40,
  }) {
    return restPollStream(() async {
      final entries = await _fetchHistory(plantId);
      if (entries.length <= limit) return entries;
      return entries.take(limit).toList();
    });
  }

  Stream<FertilizingEntry?> watchLastFertilizing(String plantId) {
    return restPollStream(() async {
      final entries = await _fetchHistory(plantId);
      if (entries.isEmpty) return null;
      return entries.first;
    });
  }

  Future<void> deleteFertilizing({
    required String plantId,
    required String fertilizingId,
  }) async {
    try {
      await _api.delete('/plants/$plantId/fertilizings/$fertilizingId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }
}
