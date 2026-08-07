import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/watering_entry.dart';
import 'growth_event_service.dart';

class WateringService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int _batchPlantChunk = 200;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _plantsCollection {
    return _db.collection('users').doc(_uid).collection('plants');
  }

  CollectionReference<Map<String, dynamic>> _wateringRef(String plantId) {
    return _plantsCollection.doc(plantId).collection('watering');
  }

  Future<void> _syncLastWateredAt(String plantId) async {
    final snapshot = await _wateringRef(plantId)
        .orderBy('wateredAt', descending: true)
        .limit(1)
        .get();

    await _plantsCollection.doc(plantId).update({
      'lastWateredAt': snapshot.docs.isEmpty
          ? FieldValue.delete()
          : snapshot.docs.first.data()['wateredAt'],
    });
  }

  /// When [skipPlantFetch] is true, uses [wateringFrequency] / [lastWateredAt]
  /// as provided (including null) and does not read the plant document.
  Future<void> addWatering({
    required String plantId,
    required DateTime wateredAt,
    int? wateringFrequency,
    DateTime? lastWateredAt,
    bool skipPlantFetch = false,
  }) async {
    var frequency = wateringFrequency;
    var last = lastWateredAt;

    if (!skipPlantFetch) {
      final plantDoc = await _plantsCollection.doc(plantId).get();
      final plantData = plantDoc.data();
      frequency ??= plantData?['wateringFrequency'] as int?;
      last ??= (plantData?['lastWateredAt'] as Timestamp?)?.toDate();
    }

    DateTime? nextWatering;
    if (frequency != null && frequency > 0) {
      nextWatering = wateredAt.add(Duration(days: frequency));
    }

    final batch = _db.batch();
    final entryRef = _wateringRef(plantId).doc();
    batch.set(entryRef, {
      'wateredAt': Timestamp.fromDate(wateredAt),
      'nextWatering':
          nextWatering != null ? Timestamp.fromDate(nextWatering) : null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (last == null || wateredAt.isAfter(last)) {
      batch.update(_plantsCollection.doc(plantId), {
        'lastWateredAt': Timestamp.fromDate(wateredAt),
      });
    }

    await batch.commit();

    await GrowthEventService().addWateringEvent(plantId, at: wateredAt);
  }

  /// Bulk watering without per-plant plant-document reads when maps are supplied.
  Future<void> addWaterings({
    required Iterable<String> plantIds,
    required DateTime wateredAt,
    Map<String, int?> wateringFrequencyByPlantId = const {},
    Map<String, DateTime?> lastWateredAtByPlantId = const {},
  }) async {
    final ids = plantIds.toList();
    for (var i = 0; i < ids.length; i += _batchPlantChunk) {
      final chunk = ids.skip(i).take(_batchPlantChunk);
      final batch = _db.batch();

      for (final plantId in chunk) {
        final frequency = wateringFrequencyByPlantId[plantId];
        final last = lastWateredAtByPlantId[plantId];

        DateTime? nextWatering;
        if (frequency != null && frequency > 0) {
          nextWatering = wateredAt.add(Duration(days: frequency));
        }

        batch.set(_wateringRef(plantId).doc(), {
          'wateredAt': Timestamp.fromDate(wateredAt),
          'nextWatering':
              nextWatering != null ? Timestamp.fromDate(nextWatering) : null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (last == null || wateredAt.isAfter(last)) {
          batch.update(_plantsCollection.doc(plantId), {
            'lastWateredAt': Timestamp.fromDate(wateredAt),
          });
        }
      }

      await batch.commit();

      for (final plantId in chunk) {
        await GrowthEventService().addWateringEvent(plantId, at: wateredAt);
      }
    }
  }

  Stream<List<WateringEntry>> getWateringHistory(
    String plantId, {
    int limit = 40,
  }) {
    return _wateringRef(plantId)
        .orderBy('wateredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(WateringEntry.fromFirestore).toList(),
        );
  }

  Stream<WateringEntry?> watchLastWatering(String plantId) {
    return _wateringRef(plantId)
        .orderBy('wateredAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return WateringEntry.fromFirestore(snapshot.docs.first);
    });
  }

  Future<WateringEntry?> getLastWatering(String plantId) async {
    final snapshot = await _wateringRef(plantId)
        .orderBy('wateredAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return WateringEntry.fromFirestore(snapshot.docs.first);
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<bool> hasWateringOnDay({
    required String plantId,
    required DateTime day,
  }) async {
    final start = _startOfDay(day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _wateringRef(plantId)
        .where('wateredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('wateredAt', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// After fertilizing on [fertilizedAt], add watering on the same day unless
  /// the plant was already watered the day before (or already on that day).
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
    await _wateringRef(plantId).doc(wateringId).delete();
    await _syncLastWateredAt(plantId);
  }

  Future<void> updateWatering({
    required String plantId,
    required String wateringId,
    required DateTime wateredAt,
    int? wateringFrequency,
    bool skipPlantFetch = false,
  }) async {
    final updateData = <String, dynamic>{
      'wateredAt': Timestamp.fromDate(wateredAt),
    };

    var frequency = wateringFrequency;
    if (!skipPlantFetch && frequency == null) {
      final plantDoc = await _plantsCollection.doc(plantId).get();
      frequency = plantDoc.data()?['wateringFrequency'] as int?;
    }

    if (frequency != null && frequency > 0) {
      updateData['nextWatering'] = Timestamp.fromDate(
        wateredAt.add(Duration(days: frequency)),
      );
    } else {
      updateData['nextWatering'] = null;
    }

    await _wateringRef(plantId).doc(wateringId).update(updateData);
    await _syncLastWateredAt(plantId);
  }
}
