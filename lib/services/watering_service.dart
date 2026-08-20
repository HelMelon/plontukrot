import '../models/model_helpers.dart';
import '../models/watering_entry.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'growth_event_service.dart';
import 'rest_stream.dart';

class WateringService {
  final ApiClient _api = ApiClient.instance;

  Future<List<WateringEntry>> _fetchHistory(String plantId) async {
    final list = jsonMapList(await _api.get('/plants/$plantId/waterings'));
    final entries = list
        .map((m) => WateringEntry.fromMap(readString(m, 'id'), m))
        .toList()
      ..sort((a, b) => b.wateredAt.compareTo(a.wateredAt));
    return entries;
  }

  Future<void> addWatering({
    required String plantId,
    required DateTime wateredAt,
    int? wateringFrequency,
    DateTime? lastWateredAt,
    bool skipPlantFetch = false,
  }) async {
    DateTime? nextWatering;
    if (wateringFrequency != null && wateringFrequency > 0) {
      nextWatering = wateredAt.add(Duration(days: wateringFrequency));
    }

    await _api.post('/plants/$plantId/waterings', body: {
      'watered_at': isoDate(wateredAt),
      'next_watering': isoDateOrNull(nextWatering),
    });

    await GrowthEventService().addWateringEvent(plantId, at: wateredAt);
  }

  Future<void> addWaterings({
    required Iterable<String> plantIds,
    required DateTime wateredAt,
    Map<String, int?> wateringFrequencyByPlantId = const {},
    Map<String, DateTime?> lastWateredAtByPlantId = const {},
  }) async {
    for (final plantId in plantIds) {
      await addWatering(
        plantId: plantId,
        wateredAt: wateredAt,
        wateringFrequency: wateringFrequencyByPlantId[plantId],
        lastWateredAt: lastWateredAtByPlantId[plantId],
        skipPlantFetch: true,
      );
    }
  }

  Stream<List<WateringEntry>> getWateringHistory(
    String plantId, {
    int limit = 40,
  }) {
    return restPollStream(() async {
      final entries = await _fetchHistory(plantId);
      if (entries.length <= limit) return entries;
      return entries.take(limit).toList();
    });
  }

  Stream<WateringEntry?> watchLastWatering(String plantId) {
    return restPollStream(() => getLastWatering(plantId));
  }

  Future<WateringEntry?> getLastWatering(String plantId) async {
    final entries = await _fetchHistory(plantId);
    if (entries.isEmpty) return null;
    return entries.first;
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<bool> hasWateringOnDay({
    required String plantId,
    required DateTime day,
  }) async {
    final start = _startOfDay(day);
    final end = start.add(const Duration(days: 1));
    final entries = await _fetchHistory(plantId);
    return entries.any((e) {
      final at = e.wateredAt;
      return !at.isBefore(start) && at.isBefore(end);
    });
  }

  Future<void> addWateringIfMissingBeforeFertilizing({
    required String plantId,
    required DateTime fertilizedAt,
    DateTime? lastWateredAt,
    int? wateringFrequency,
    bool skipPlantFetch = false,
  }) async {
    final fertDay = _startOfDay(fertilizedAt);
    final dayBefore = fertDay.subtract(const Duration(days: 1));

    if (skipPlantFetch || lastWateredAt != null) {
      if (lastWateredAt != null) {
        final lastDay = _startOfDay(lastWateredAt);
        if (!lastDay.isBefore(dayBefore)) return;
      }
    } else {
      if (await hasWateringOnDay(plantId: plantId, day: dayBefore)) {
        return;
      }
      if (await hasWateringOnDay(plantId: plantId, day: fertDay)) {
        return;
      }
    }

    await addWatering(
      plantId: plantId,
      wateredAt: fertDay,
      wateringFrequency: wateringFrequency,
      lastWateredAt: lastWateredAt,
      skipPlantFetch: skipPlantFetch || lastWateredAt != null,
    );
  }

  Future<void> deleteWatering({
    required String plantId,
    required String wateringId,
  }) async {
    try {
      await _api.delete('/plants/$plantId/waterings/$wateringId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> updateWatering({
    required String plantId,
    required String wateringId,
    required DateTime wateredAt,
    int? wateringFrequency,
    bool skipPlantFetch = false,
  }) async {
    DateTime? nextWatering;
    if (wateringFrequency != null && wateringFrequency > 0) {
      nextWatering = wateredAt.add(Duration(days: wateringFrequency));
    }
    try {
      await _api.patch('/plants/$plantId/waterings/$wateringId', body: {
        'watered_at': isoDate(wateredAt),
        'next_watering': isoDateOrNull(nextWatering),
      });
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }
}
