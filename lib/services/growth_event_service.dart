import '../models/growth_event.dart';
import '../models/model_helpers.dart';
import 'api_client.dart';
import 'rest_stream.dart';

class GrowthEventService {
  static const retention = Duration(days: 730);

  final ApiClient _api = ApiClient.instance;

  Stream<List<GrowthEvent>> watchGrowthEvents(String plantId) {
    return restPollStream(() async {
      final list =
          jsonMapList(await _api.get('/plants/$plantId/growth-events'));
      final events = list
          .map((m) => GrowthEvent.fromMap(readString(m, 'id') ?? '', m))
          .toList()
        ..sort((a, b) {
          final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aAt.compareTo(bAt);
        });
      return events;
    });
  }

  Future<void> addEvent({
    required String plantId,
    required GrowthEventType type,
    DateTime? at,
    LeafRemovalReason? reason,
  }) async {
    final when = at ?? DateTime.now();
    await _api.post('/plants/$plantId/growth-events', body: {
      'type': type.index,
      'expires_at': isoDate(when.add(retention)),
    });
  }

  Future<void> addNewLeaf(String plantId) {
    return addEvent(plantId: plantId, type: GrowthEventType.newLeaf);
  }

  Future<void> removeLeaf(
    String plantId, {
    required int currentDisplayCount,
    required LeafRemovalReason reason,
  }) async {
    if (currentDisplayCount <= 0) return;
    await addEvent(
      plantId: plantId,
      type: GrowthEventType.leafRemoved,
      reason: reason,
    );
  }

  Future<void> addWateringEvent(String plantId, {DateTime? at}) {
    return addEvent(
      plantId: plantId,
      type: GrowthEventType.watering,
      at: at,
    );
  }

  Future<void> addFertilizingEvent(String plantId, {DateTime? at}) {
    return addEvent(
      plantId: plantId,
      type: GrowthEventType.fertilizing,
      at: at,
    );
  }

  Future<void> addRepottingEvent(String plantId, {DateTime? at}) {
    return addEvent(
      plantId: plantId,
      type: GrowthEventType.repotting,
      at: at,
    );
  }

  Future<void> addTrimmingEvent(String plantId, {DateTime? at}) {
    return addEvent(
      plantId: plantId,
      type: GrowthEventType.trimming,
      at: at,
    );
  }

  Future<void> addPinchingEvent(String plantId, {DateTime? at}) {
    return addEvent(
      plantId: plantId,
      type: GrowthEventType.pinching,
      at: at,
    );
  }

  Future<void> purgeExpired(String plantId) async {
    // Expiry is enforced client-side when listing; no bulk delete route yet.
  }
}
