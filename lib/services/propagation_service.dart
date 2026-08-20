import 'dart:async';

import '../models/model_helpers.dart';
import '../models/propagation.dart';
import '../models/propagation_initial_stage.dart';
import '../models/propagation_method.dart';
import '../models/propagation_outcome.dart';
import '../models/propagation_stage_entry.dart';
import '../models/propagation_status.dart';
import '../models/propagation_year_stats.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'rest_stream.dart';

class PropagationService {
  final ApiClient _api = ApiClient.instance;

  static const archiveRetention = Duration(days: 365);

  Future<List<Propagation>> _fetchAll() async {
    final list = jsonMapList(await _api.get('/propagations'));
    return list
        .map((m) => Propagation.fromMap(readString(m, 'id') ?? '', m))
        .toList();
  }

  Map<String, dynamic> _toPayload(Propagation item) {
    return {
      'parent_plant_id': item.parentPlantId,
      'parent_plant_name': item.parentPlantName,
      'parent_plant_family': item.parentPlantFamily,
      'method': item.method.index,
      'stage': item.stage,
      'status': item.status.index,
      'quantity': item.quantity,
      'quantity_alive': item.quantityAlive,
      'gifted_quantity': item.giftedQuantity,
      'sold_quantity': item.soldQuantity,
      'traded_quantity': item.tradedQuantity,
      'lost_quantity': item.lostQuantity,
      'started_at': isoDate(item.startedAt),
      'sold_at': isoDateOrNull(item.soldAt),
    };
  }

  Future<String> addPropagation({
    required String parentPlantId,
    required String parentPlantName,
    required String parentPlantFamily,
    required PropagationMethod method,
    required int quantity,
    required DateTime startedAt,
    int? divisionStage,
    int? stage,
  }) async {
    final resolvedStage =
        stage ?? initialStageFor(method, divisionStage: divisionStage);
    final created = jsonMap(await _api.post('/propagations', body: {
      'parent_plant_id': parentPlantId,
      'parent_plant_name': parentPlantName,
      'parent_plant_family': parentPlantFamily,
      'method': method.index,
      'quantity': quantity,
      'quantity_alive': quantity,
      'sold_quantity': 0,
      'gifted_quantity': 0,
      'traded_quantity': 0,
      'lost_quantity': 0,
      'stage': resolvedStage,
      'status': PropagationStatus.active.index,
      'started_at': isoDate(startedAt),
    }));
    final id = readString(created, 'id') ?? '';
    if (id.isNotEmpty) {
      await _api.post('/propagations/$id/stage-history', body: {
        'stage': resolvedStage,
        'quantity_alive': quantity,
      });
    }
    return id;
  }

  Stream<List<Propagation>> watchActivePropagations() {
    return restPollStream(() async {
      final items = (await _fetchAll())
          .where((item) =>
              item.status == PropagationStatus.active &&
              item.quantityAlive > 0)
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return items;
    });
  }

  Stream<List<Propagation>> watchArchivedPropagations() {
    return restPollStream(() async {
      final items = (await _fetchAll())
          .where((item) => item.isArchiveVisible)
          .toList()
        ..sort((a, b) {
          final aDate = a.archivedAt ?? a.soldAt ?? a.startedAt;
          final bDate = b.archivedAt ?? b.soldAt ?? b.startedAt;
          return bDate.compareTo(aDate);
        });
      return items;
    });
  }

  Stream<PropagationYearStats> watchYearStats([int? year]) {
    return yearStatsFrom(
      watchActivePropagations(),
      watchArchivedPropagations(),
      year,
    );
  }

  Stream<PropagationYearStats> yearStatsFrom(
    Stream<List<Propagation>> active,
    Stream<List<Propagation>> archived, [
    int? year,
  ]) {
    final targetYear = year ?? DateTime.now().year;
    return _combinePropagationLists(active, archived).map(
      (items) => PropagationYearStats.fromList(targetYear, items),
    );
  }

  static Stream<List<Propagation>> _combinePropagationLists(
    Stream<List<Propagation>> active,
    Stream<List<Propagation>> archived,
  ) {
    late final StreamController<List<Propagation>> controller;
    List<Propagation>? latestActive;
    List<Propagation>? latestArchived;
    StreamSubscription<List<Propagation>>? activeSub;
    StreamSubscription<List<Propagation>>? archivedSub;

    void emit() {
      if (latestActive == null || latestArchived == null) return;
      if (!controller.isClosed) {
        controller.add([...latestActive!, ...latestArchived!]);
      }
    }

    controller = StreamController<List<Propagation>>(
      onListen: () {
        activeSub = active.listen((items) {
          latestActive = items;
          emit();
        }, onError: controller.addError);
        archivedSub = archived.listen((items) {
          latestArchived = items;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await activeSub?.cancel();
        await archivedSub?.cancel();
      },
    );

    return controller.stream;
  }

  Stream<Set<String>> watchActiveParentPlantIds() {
    return watchActiveBatchCountsByPlantId().map((counts) => counts.keys.toSet());
  }

  Stream<Map<String, int>> watchActiveBatchCountsByPlantId() {
    return watchActivePropagations().map((items) {
      final counts = <String, int>{};
      for (final item in items) {
        final id = item.parentPlantId;
        if (id.isEmpty) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    });
  }

  Stream<List<Propagation>> watchPropagationsForPlant(String plantId) {
    return restPollStream(() async {
      final items = (await _fetchAll())
          .where(
            (item) =>
                item.parentPlantId == plantId &&
                item.status == PropagationStatus.active &&
                item.quantityAlive > 0,
          )
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return items;
    });
  }

  Stream<Propagation?> watchPropagation(String propagationId) {
    return restPollStream(() async {
      for (final item in await _fetchAll()) {
        if (item.id == propagationId) return item;
      }
      return null;
    });
  }

  Stream<List<PropagationStageEntry>> watchStageHistory(String propagationId) {
    return restPollStream(() async {
      final list = jsonMapList(
        await _api.get('/propagations/$propagationId/stage-history'),
      );
      final entries = list
          .map((m) => PropagationStageEntry.fromMap(readString(m, 'id'), m))
          .toList();
      entries.sort((a, b) {
        final byTime = a.changedAt.compareTo(b.changedAt);
        if (byTime != 0) return byTime;
        return (a.id ?? '').compareTo(b.id ?? '');
      });
      return entries;
    });
  }

  Future<Propagation?> _get(String id) async {
    for (final item in await _fetchAll()) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _patch(Propagation item) async {
    await _api.patch('/propagations/${item.id}', body: _toPayload(item));
  }

  Future<void> changeStage({
    required String propagationId,
    required int stage,
    required DateTime changedAt,
    int? quantityAlive,
    String? note,
  }) async {
    final current = await _get(propagationId);
    if (current == null) return;

    final previousAlive = current.quantityAlive;
    final alive = quantityAlive ?? previousAlive;
    final previousLost = current.lostQuantity;
    final lostDelta = previousAlive > alive ? previousAlive - alive : 0;
    final newLost = previousLost + lostDelta;

    var status = current.status;
    DateTime? soldAt = current.soldAt;
    DateTime? archivedAt = current.archivedAt;
    DateTime? expiresAt = current.expiresAt;

    if (alive <= 0) {
      status = PropagationStatus.archiveFromCounters(
        soldQuantity: current.soldQuantity,
        giftedQuantity: current.giftedQuantity,
        tradedQuantity: current.tradedQuantity,
        lostQuantity: newLost,
      );
      archivedAt = changedAt;
      expiresAt = changedAt.add(archiveRetention);
      if (current.soldQuantity > 0) {
        soldAt = changedAt;
      }
    }

    final updated = Propagation(
      id: current.id,
      parentPlantId: current.parentPlantId,
      parentPlantName: current.parentPlantName,
      parentPlantFamily: current.parentPlantFamily,
      method: current.method,
      quantity: current.quantity,
      quantityAlive: alive,
      soldQuantity: current.soldQuantity,
      giftedQuantity: current.giftedQuantity,
      tradedQuantity: current.tradedQuantity,
      lostQuantity: newLost,
      stage: stage,
      status: status,
      startedAt: current.startedAt,
      soldAt: soldAt,
      archivedAt: archivedAt,
      expiresAt: expiresAt,
      createdAt: current.createdAt,
    );
    await _patch(updated);
    await _api.post('/propagations/$propagationId/stage-history', body: {
      'stage': stage,
      'quantity_alive': alive,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  Future<void> markOutcome({
    required String propagationId,
    required PropagationOutcome outcome,
    required int quantity,
    required DateTime at,
    String? note,
  }) async {
    if (quantity < 1) return;
    final current = await _get(propagationId);
    if (current == null) return;

    final alive = current.quantityAlive;
    final count = quantity > alive ? alive : quantity;
    if (count < 1) return;
    final newAlive = alive - count;

    var sold = current.soldQuantity;
    var gifted = current.giftedQuantity;
    var traded = current.tradedQuantity;
    var lost = current.lostQuantity;
    DateTime? soldAt = current.soldAt;
    switch (outcome) {
      case PropagationOutcome.sold:
        sold += count;
        soldAt = at;
      case PropagationOutcome.gifted:
        gifted += count;
      case PropagationOutcome.traded:
        traded += count;
      case PropagationOutcome.lost:
        lost += count;
    }

    var status = current.status;
    DateTime? archivedAt = current.archivedAt;
    DateTime? expiresAt = current.expiresAt;
    if (newAlive <= 0) {
      status = PropagationStatus.archiveForOutcome(outcome);
      archivedAt = at;
      expiresAt = at.add(archiveRetention);
    }

    final updated = Propagation(
      id: current.id,
      parentPlantId: current.parentPlantId,
      parentPlantName: current.parentPlantName,
      parentPlantFamily: current.parentPlantFamily,
      method: current.method,
      quantity: current.quantity,
      quantityAlive: newAlive,
      soldQuantity: sold,
      giftedQuantity: gifted,
      tradedQuantity: traded,
      lostQuantity: lost,
      stage: current.stage,
      status: status,
      startedAt: current.startedAt,
      soldAt: soldAt,
      archivedAt: archivedAt,
      expiresAt: expiresAt,
      createdAt: current.createdAt,
    );
    await _patch(updated);
    await _api.post('/propagations/$propagationId/stage-history', body: {
      'stage': current.stage,
      'quantity_alive': newAlive,
      'outcome': outcome.code,
      if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
    });
  }

  Future<void> sell({
    required String propagationId,
    required int quantity,
    required DateTime soldAt,
    String? note,
  }) {
    return markOutcome(
      propagationId: propagationId,
      outcome: PropagationOutcome.sold,
      quantity: quantity,
      at: soldAt,
      note: note,
    );
  }

  Future<void> markGifted({
    required String propagationId,
    required int quantity,
    required DateTime at,
    String? note,
  }) {
    return markOutcome(
      propagationId: propagationId,
      outcome: PropagationOutcome.gifted,
      quantity: quantity,
      at: at,
      note: note,
    );
  }

  Future<void> markTraded({
    required String propagationId,
    required int quantity,
    required DateTime at,
    String? note,
  }) {
    return markOutcome(
      propagationId: propagationId,
      outcome: PropagationOutcome.traded,
      quantity: quantity,
      at: at,
      note: note,
    );
  }

  Future<void> markLost({
    required String propagationId,
    required int quantity,
    required DateTime lostAt,
    String? note,
  }) {
    return markOutcome(
      propagationId: propagationId,
      outcome: PropagationOutcome.lost,
      quantity: quantity,
      at: lostAt,
      note: note,
    );
  }

  Future<void> updateQuantityAlive({
    required String propagationId,
    required int quantityAlive,
  }) async {
    final current = await _get(propagationId);
    if (current == null) return;
    await _patch(
      Propagation(
        id: current.id,
        parentPlantId: current.parentPlantId,
        parentPlantName: current.parentPlantName,
        parentPlantFamily: current.parentPlantFamily,
        method: current.method,
        quantity: current.quantity,
        quantityAlive: quantityAlive,
        soldQuantity: current.soldQuantity,
        giftedQuantity: current.giftedQuantity,
        tradedQuantity: current.tradedQuantity,
        lostQuantity: current.lostQuantity,
        stage: current.stage,
        status: current.status,
        startedAt: current.startedAt,
        soldAt: current.soldAt,
        archivedAt: current.archivedAt,
        expiresAt: current.expiresAt,
        createdAt: current.createdAt,
      ),
    );
  }

  Future<void> deletePropagation(String propagationId) async {
    try {
      await _api.delete('/propagations/$propagationId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> deleteStageEntry({
    required String propagationId,
    required String entryId,
    required int stage,
  }) async {
    if (stage <= 1) {
      await deletePropagation(propagationId);
      return;
    }
    try {
      await _api.delete('/propagations/$propagationId/stage-history/$entryId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
    final remaining =
        await _api.get('/propagations/$propagationId/stage-history');
    final entries = jsonMapList(remaining)
        .map((m) => PropagationStageEntry.fromMap(readString(m, 'id'), m))
        .toList()
      ..sort((a, b) => b.changedAt.compareTo(a.changedAt));
    if (entries.isEmpty) {
      await deletePropagation(propagationId);
      return;
    }
    final latest = entries.first;
    final current = await _get(propagationId);
    if (current == null) return;
    await _patch(
      Propagation(
        id: current.id,
        parentPlantId: current.parentPlantId,
        parentPlantName: current.parentPlantName,
        parentPlantFamily: current.parentPlantFamily,
        method: current.method,
        quantity: current.quantity,
        quantityAlive: latest.quantityAlive ?? current.quantityAlive,
        soldQuantity: current.soldQuantity,
        giftedQuantity: current.giftedQuantity,
        tradedQuantity: current.tradedQuantity,
        lostQuantity: current.lostQuantity,
        stage: latest.stage,
        status: current.status,
        startedAt: current.startedAt,
        soldAt: current.soldAt,
        archivedAt: current.archivedAt,
        expiresAt: current.expiresAt,
        createdAt: current.createdAt,
      ),
    );
  }
}
