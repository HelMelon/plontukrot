import '../models/component.dart';
import '../models/model_helpers.dart';
import '../models/repotting_entry.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'growth_event_service.dart';
import 'rest_stream.dart';

class RepottingService {
  final ApiClient _api = ApiClient.instance;

  Future<List<RepottingEntry>> _fetchHistory(String plantId) async {
    try {
      final list = jsonMapList(await _api.get('/plants/$plantId/repottings'));
      return list
          .map((m) => RepottingEntry.fromMap(readString(m, 'id'), m))
          .toList()
        ..sort((a, b) => b.repottedAt.compareTo(a.repottedAt));
    } on ApiException catch (error) {
      if (error.isNotFound) return const [];
      rethrow;
    }
  }

  Future<void> addRepotting({
    required String plantId,
    required DateTime repottedAt,
    required List<SoilComponent> components,
    String? soilId,
    String? soilName,
    bool slowReleaseFertilizer = false,
    DateTime? lastRepottedAt,
    bool skipPlantFetch = false,
  }) async {
    await _api.post('/plants/$plantId/repottings', body: {
      'repotted_at': isoDate(repottedAt),
      if (soilId != null) 'soil_id': soilId,
      if (soilName != null) 'soil_name': soilName,
      'components': components.map((e) => e.toMap()).toList(),
      'slow_release_fertilizer': slowReleaseFertilizer,
    });
    await GrowthEventService().addRepottingEvent(plantId, at: repottedAt);
  }

  Future<void> addRepottings({
    required Iterable<String> plantIds,
    required DateTime repottedAt,
    required List<SoilComponent> components,
    String? soilId,
    String? soilName,
    bool slowReleaseFertilizer = false,
    Map<String, DateTime?> lastRepottedAtByPlantId = const {},
  }) async {
    for (final plantId in plantIds) {
      await addRepotting(
        plantId: plantId,
        repottedAt: repottedAt,
        components: components,
        soilId: soilId,
        soilName: soilName,
        slowReleaseFertilizer: slowReleaseFertilizer,
        lastRepottedAt: lastRepottedAtByPlantId[plantId],
        skipPlantFetch: true,
      );
    }
  }

  Stream<List<RepottingEntry>> getRepottingHistory(
    String plantId, {
    int limit = 40,
  }) {
    return restPollStream(() async {
      final entries = await _fetchHistory(plantId);
      if (entries.length <= limit) return entries;
      return entries.take(limit).toList();
    });
  }

  Stream<RepottingEntry?> watchLastRepotting(String plantId) {
    return restPollStream(() async {
      final entries = await _fetchHistory(plantId);
      if (entries.isEmpty) return null;
      return entries.first;
    });
  }

  Future<void> deleteRepotting({
    required String plantId,
    required String repottingId,
  }) async {
    try {
      await _api.delete('/plants/$plantId/repottings/$repottingId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> updateRepotting({
    required String plantId,
    required String repottingId,
    required DateTime repottedAt,
    required List<SoilComponent> components,
    String? soilId,
    String? soilName,
    bool slowReleaseFertilizer = false,
  }) async {
    try {
      await _api.patch('/plants/$plantId/repottings/$repottingId', body: {
        'repotted_at': isoDate(repottedAt),
        'soil_id': soilId,
        'soil_name': soilName,
        'components': components.map((e) => e.toMap()).toList(),
        'slow_release_fertilizer': slowReleaseFertilizer,
      });
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }
}
