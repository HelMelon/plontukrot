import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/growth_event.dart';

class GrowthEventService {
  static const retention = Duration(days: 730);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _growthEventsRef(String plantId) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('plants')
        .doc(plantId)
        .collection('growthEvents');
  }

  Stream<List<GrowthEvent>> watchGrowthEvents(String plantId) {
    return _growthEventsRef(plantId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(GrowthEvent.fromFirestore).toList(),
        );
  }

  /// Persists a growth/care event. Not shown in UI for care types yet.
  Future<void> addEvent({
    required String plantId,
    required GrowthEventType type,
    DateTime? at,
  }) async {
    final when = at ?? DateTime.now();
    await _growthEventsRef(plantId).add({
      'type': type.code,
      'createdAt': Timestamp.fromDate(when),
      'expiresAt': Timestamp.fromDate(when.add(retention)),
    });
  }

  Future<void> addNewLeaf(String plantId) {
    return addEvent(plantId: plantId, type: GrowthEventType.newLeaf);
  }

  /// Adds one [GrowthEventType.leafRemoved]. No-op when [currentDisplayCount] ≤ 0.
  Future<void> removeLeaf(
    String plantId, {
    required int currentDisplayCount,
  }) async {
    if (currentDisplayCount <= 0) return;
    await addEvent(plantId: plantId, type: GrowthEventType.leafRemoved);
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
    final now = DateTime.now();
    final snapshot = await _growthEventsRef(plantId)
        .where('expiresAt', isLessThan: Timestamp.fromDate(now))
        .get();

    if (snapshot.docs.isEmpty) return;

    const pageSize = 200;
    for (var i = 0; i < snapshot.docs.length; i += pageSize) {
      final end = (i + pageSize < snapshot.docs.length)
          ? i + pageSize
          : snapshot.docs.length;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs.sublist(i, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
