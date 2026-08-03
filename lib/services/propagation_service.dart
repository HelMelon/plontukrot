import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/propagation.dart';
import '../models/propagation_method.dart';
import '../models/propagation_stage_entry.dart';
import '../models/propagation_status.dart';
import '../models/propagation_year_stats.dart';

class PropagationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const archiveRetention = Duration(days: 365);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _propagationsRef {
    return _db.collection('users').doc(_uid).collection('propagations');
  }

  CollectionReference<Map<String, dynamic>> _stageHistoryRef(
    String propagationId,
  ) {
    return _propagationsRef.doc(propagationId).collection('stageHistory');
  }

  Map<String, dynamic> _archiveFields({
    required PropagationStatus status,
    required DateTime at,
  }) {
    return {
      'status': status.code,
      'archivedAt': Timestamp.fromDate(at),
      'expiresAt': Timestamp.fromDate(at.add(archiveRetention)),
    };
  }

  Future<String> addPropagation({
    required String parentPlantId,
    required String parentPlantName,
    required String parentPlantFamily,
    required PropagationMethod method,
    required int quantity,
    required DateTime startedAt,
    int stage = 1,
  }) async {
    final docRef = _propagationsRef.doc();

    final batch = _db.batch();
    batch.set(docRef, {
      'parentPlantId': parentPlantId,
      'parentPlantName': parentPlantName,
      'parentPlantFamily': parentPlantFamily,
      'method': method.code,
      'quantity': quantity,
      'quantityAlive': quantity,
      'soldQuantity': 0,
      'lostQuantity': 0,
      'stage': stage,
      'status': PropagationStatus.active.code,
      'startedAt': Timestamp.fromDate(startedAt),
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_stageHistoryRef(docRef.id).doc(), {
      'stage': stage,
      'changedAt': Timestamp.fromDate(startedAt),
      'quantityAlive': quantity,
    });

    await batch.commit();
    return docRef.id;
  }

  Stream<List<Propagation>> watchActivePropagations() {
    return _propagationsRef
        .where('status', isEqualTo: PropagationStatus.active.code)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(Propagation.fromFirestore)
          .where((item) => item.quantityAlive > 0)
          .toList();
      items.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return items;
    });
  }

  Stream<List<Propagation>> watchArchivedPropagations() {
    return _propagationsRef
        .where(
          'status',
          whereIn: [
            PropagationStatus.sold.code,
            PropagationStatus.lost.code,
          ],
        )
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(Propagation.fromFirestore)
          .where((item) => item.isArchiveVisible)
          .toList();
      items.sort((a, b) {
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

  /// Derive year stats from already-open active/archive streams (no extra queries).
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
    return watchActivePropagations().map(
      (items) => items.map((item) => item.parentPlantId).toSet(),
    );
  }

  Stream<List<Propagation>> watchPropagationsForPlant(String plantId) {
    return _propagationsRef
        .where('parentPlantId', isEqualTo: plantId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(Propagation.fromFirestore)
          .where(
            (item) =>
                item.status == PropagationStatus.active &&
                item.quantityAlive > 0,
          )
          .toList();
      items.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return items;
    });
  }

  Stream<Propagation?> watchPropagation(String propagationId) {
    return _propagationsRef.doc(propagationId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Propagation.fromMap(doc.id, doc.data()!);
    });
  }

  Stream<List<PropagationStageEntry>> watchStageHistory(String propagationId) {
    return _stageHistoryRef(propagationId)
        .orderBy('changedAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(PropagationStageEntry.fromFirestore).toList(),
        );
  }

  Future<void> changeStage({
    required String propagationId,
    required int stage,
    required DateTime changedAt,
    int? quantityAlive,
    String? note,
  }) async {
    final docRef = _propagationsRef.doc(propagationId);
    final current = await docRef.get();
    if (!current.exists) return;

    final data = current.data()!;
    final previousAlive = data['quantityAlive'] as int? ?? 0;
    final alive = quantityAlive ?? previousAlive;
    final previousLost = data['lostQuantity'] as int? ?? 0;
    final lostDelta = previousAlive > alive ? previousAlive - alive : 0;

    final updates = <String, dynamic>{
      'stage': stage,
      'quantityAlive': alive,
      if (lostDelta > 0) 'lostQuantity': previousLost + lostDelta,
    };

    if (alive <= 0) {
      final sold = data['soldQuantity'] as int? ?? 0;
      updates.addAll(
        _archiveFields(
          status: sold > 0 ? PropagationStatus.sold : PropagationStatus.lost,
          at: changedAt,
        ),
      );
      if (sold > 0) {
        updates['soldAt'] = Timestamp.fromDate(changedAt);
      }
    }

    final batch = _db.batch();
    batch.update(docRef, updates);

    batch.set(_stageHistoryRef(propagationId).doc(), {
      'stage': stage,
      'changedAt': Timestamp.fromDate(changedAt),
      'quantityAlive': alive,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });

    await batch.commit();
  }

  Future<void> sell({
    required String propagationId,
    required int quantity,
    required DateTime soldAt,
    String? note,
  }) async {
    if (quantity < 1) return;

    final docRef = _propagationsRef.doc(propagationId);
    final current = await docRef.get();
    if (!current.exists) return;

    final data = current.data()!;
    final alive = data['quantityAlive'] as int? ?? 0;
    final sold = data['soldQuantity'] as int? ?? 0;
    final stage = data['stage'] as int? ?? 1;
    final sellCount = quantity > alive ? alive : quantity;
    if (sellCount < 1) return;

    final newAlive = alive - sellCount;
    final updates = <String, dynamic>{
      'quantityAlive': newAlive,
      'soldQuantity': sold + sellCount,
      'soldAt': Timestamp.fromDate(soldAt),
    };

    if (newAlive <= 0) {
      updates.addAll(
        _archiveFields(status: PropagationStatus.sold, at: soldAt),
      );
    }

    final batch = _db.batch();
    batch.update(docRef, updates);
    batch.set(_stageHistoryRef(propagationId).doc(), {
      'stage': stage,
      'changedAt': Timestamp.fromDate(soldAt),
      'quantityAlive': newAlive,
      if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
    });

    await batch.commit();
  }

  Future<void> markLost({
    required String propagationId,
    required int quantity,
    required DateTime lostAt,
    String? note,
  }) async {
    if (quantity < 1) return;

    final docRef = _propagationsRef.doc(propagationId);
    final current = await docRef.get();
    if (!current.exists) return;

    final data = current.data()!;
    final alive = data['quantityAlive'] as int? ?? 0;
    final lost = data['lostQuantity'] as int? ?? 0;
    final sold = data['soldQuantity'] as int? ?? 0;
    final stage = data['stage'] as int? ?? 1;
    final loseCount = quantity > alive ? alive : quantity;
    if (loseCount < 1) return;

    final newAlive = alive - loseCount;
    final updates = <String, dynamic>{
      'quantityAlive': newAlive,
      'lostQuantity': lost + loseCount,
    };

    if (newAlive <= 0) {
      updates.addAll(
        _archiveFields(
          status: sold > 0 ? PropagationStatus.sold : PropagationStatus.lost,
          at: lostAt,
        ),
      );
    }

    final batch = _db.batch();
    batch.update(docRef, updates);
    batch.set(_stageHistoryRef(propagationId).doc(), {
      'stage': stage,
      'changedAt': Timestamp.fromDate(lostAt),
      'quantityAlive': newAlive,
      if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
    });

    await batch.commit();
  }

  Future<void> updateQuantityAlive({
    required String propagationId,
    required int quantityAlive,
  }) async {
    await _propagationsRef.doc(propagationId).update({
      'quantityAlive': quantityAlive,
    });
  }

  Future<void> deletePropagation(String propagationId) async {
    final history = await _stageHistoryRef(propagationId).get();
    final batch = _db.batch();
    for (final doc in history.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_propagationsRef.doc(propagationId));
    await batch.commit();
  }

  /// Deletes a stage-history entry.
  /// Start (stage 1) removes the whole propagation batch.
  /// Later stages remove only that entry and sync current stage.
  Future<void> deleteStageEntry({
    required String propagationId,
    required String entryId,
    required int stage,
  }) async {
    if (stage <= 1) {
      await deletePropagation(propagationId);
      return;
    }

    final historyRef = _stageHistoryRef(propagationId);
    await historyRef.doc(entryId).delete();

    final remaining = await historyRef.orderBy('changedAt', descending: true).get();
    if (remaining.docs.isEmpty) {
      await deletePropagation(propagationId);
      return;
    }

    final latest = PropagationStageEntry.fromFirestore(remaining.docs.first);
    final updates = <String, dynamic>{
      'stage': latest.stage,
    };
    if (latest.quantityAlive != null) {
      updates['quantityAlive'] = latest.quantityAlive;
    }

    await _propagationsRef.doc(propagationId).update(updates);
  }
}
