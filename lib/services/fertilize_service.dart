import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/fertilizer.dart';
import '../models/fertilizer_application_method.dart';
import '../models/fertilizer_dose.dart';
import '../models/fertilizer_ingredient.dart';
import '../models/fertilizing_entry.dart';
import 'watering_service.dart';

class FertilizeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _fertilizersRef =>
      _db.collection('users').doc(uid).collection('fertilizers');

  CollectionReference<Map<String, dynamic>> get _ingredientsRef =>
      _db.collection('users').doc(uid).collection('fertilizerComponents');

  CollectionReference<Map<String, dynamic>> _fertilizingRef(String plantId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('plants')
        .doc(plantId)
        .collection('fertilizing');
  }

  // --- Ingredient catalog ---

  Future<String> addIngredient({required String name}) async {
    final doc = await _ingredientsRef.add({
      'name': name.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateIngredient({
    required String ingredientId,
    required String name,
  }) async {
    await _ingredientsRef.doc(ingredientId).update({
      'name': name.trim(),
    });
  }

  Future<void> deleteIngredient(String ingredientId) async {
    await _ingredientsRef.doc(ingredientId).delete();
  }

  Stream<List<FertilizerIngredient>> getIngredients() {
    return _ingredientsRef.orderBy('name').snapshots().map(
          (snapshot) =>
              snapshot.docs.map(FertilizerIngredient.fromFirestore).toList(),
        );
  }

  // --- Fertilizer catalog (named mixes) ---

  Future<String> addFertilizer({
    required String name,
    FertilizerKind kind = FertilizerKind.mix,
    int waterMl = 250,
    List<FertilizerDose> components = const [],
  }) async {
    final doc = await _fertilizersRef.add({
      'name': name.trim(),
      'kind': kind.code,
      'waterMl': normalizeWaterMl(waterMl),
      'components': components.map((e) => e.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> updateFertilizer({
    required String fertilizerId,
    required String name,
    required FertilizerKind kind,
    required int waterMl,
    required List<FertilizerDose> components,
  }) async {
    await _fertilizersRef.doc(fertilizerId).update({
      'name': name.trim(),
      'kind': kind.code,
      'waterMl': normalizeWaterMl(waterMl),
      'components': components.map((e) => e.toMap()).toList(),
      'type': FieldValue.delete(),
    });
  }

  Future<void> deleteFertilizer(String fertilizerId) async {
    await _fertilizersRef.doc(fertilizerId).delete();
  }

  Stream<List<Fertilizer>> getFertilizers() {
    return _fertilizersRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(Fertilizer.fromFirestore).toList(),
        );
  }

  Future<Fertilizer?> getFertilizer(String fertilizerId) async {
    final doc = await _fertilizersRef.doc(fertilizerId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Fertilizer.fromMap(doc.id, doc.data()!);
  }

  // --- Plant fertilizing history ---

  DocumentReference<Map<String, dynamic>> _plantRef(String plantId) {
    return _db.collection('users').doc(uid).collection('plants').doc(plantId);
  }

  /// Returns stored UGC fertilizer name only. Never invents presentation fallbacks.
  static String? resolveStoredFertilizerName(Map<String, dynamic> data) {
    final stored = (data['fertilizerName'] as String?)?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return null;
  }

  Future<void> _syncLastFertilizedAt(String plantId) async {
    final snapshot = await _fertilizingRef(plantId)
        .orderBy('appliedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      await _plantRef(plantId).update({
        'lastFertilizedAt': FieldValue.delete(),
        'lastFertilizerName': FieldValue.delete(),
        'careHistoryMigrated': true,
      });
      return;
    }

    final data = snapshot.docs.first.data();
    final storedName = resolveStoredFertilizerName(data);
    await _plantRef(plantId).update({
      'lastFertilizedAt': data['appliedAt'],
      if (storedName != null)
        'lastFertilizerName': storedName
      else
        'lastFertilizerName': FieldValue.delete(),
      'careHistoryMigrated': true,
    });
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
    final plantRef = _plantRef(plantId);
    var lastFertilized = lastFertilizedAt;

    if (!skipPlantFetch && lastFertilized == null) {
      final plant = await plantRef.get();
      lastFertilized =
          (plant.data()?['lastFertilizedAt'] as Timestamp?)?.toDate();
    }

    final trimmedName = fertilizerName?.trim();
    final storedName =
        (trimmedName != null && trimmedName.isNotEmpty) ? trimmedName : null;

    final batch = _db.batch();
    batch.set(_fertilizingRef(plantId).doc(), {
      if (fertilizerId != null) 'fertilizerId': fertilizerId,
      if (storedName != null) 'fertilizerName': storedName,
      'waterMl': normalizeWaterMl(waterMl),
      'components': components.map((e) => e.toMap()).toList(),
      'appliedAt': Timestamp.fromDate(appliedAt),
      'applicationMethod': applicationMethod.code,
      'nextFertilizing':
          nextFertilizing != null ? Timestamp.fromDate(nextFertilizing) : null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (lastFertilized == null || appliedAt.isAfter(lastFertilized)) {
      batch.update(plantRef, {
        'lastFertilizedAt': Timestamp.fromDate(appliedAt),
        if (storedName != null)
          'lastFertilizerName': storedName
        else
          'lastFertilizerName': FieldValue.delete(),
        'careHistoryMigrated': true,
      });
    }

    await batch.commit();

    await WateringService().addWateringIfMissingBeforeFertilizing(
      plantId: plantId,
      fertilizedAt: appliedAt,
      lastWateredAt: lastWateredAt,
      wateringFrequency: wateringFrequency,
      skipPlantFetch: skipPlantFetch || lastWateredAt != null,
    );
  }

  /// Bulk fertilizing using known plant denorm fields (no plant doc reads).
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
    final ids = plantIds.toList();
    const chunkSize = 200;
    final trimmedName = fertilizerName?.trim();
    final storedName =
        (trimmedName != null && trimmedName.isNotEmpty) ? trimmedName : null;

    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.skip(i).take(chunkSize);
      final batch = _db.batch();

      for (final plantId in chunk) {
        final lastFertilized = lastFertilizedAtByPlantId[plantId];
        batch.set(_fertilizingRef(plantId).doc(), {
          if (fertilizerId != null) 'fertilizerId': fertilizerId,
          if (storedName != null) 'fertilizerName': storedName,
          'waterMl': normalizeWaterMl(waterMl),
          'components': components.map((e) => e.toMap()).toList(),
          'appliedAt': Timestamp.fromDate(appliedAt),
          'applicationMethod': applicationMethod.code,
          'nextFertilizing': nextFertilizing != null
              ? Timestamp.fromDate(nextFertilizing)
              : null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (lastFertilized == null || appliedAt.isAfter(lastFertilized)) {
          batch.update(_plantRef(plantId), {
            'lastFertilizedAt': Timestamp.fromDate(appliedAt),
            if (storedName != null)
              'lastFertilizerName': storedName
            else
              'lastFertilizerName': FieldValue.delete(),
            'careHistoryMigrated': true,
          });
        }
      }

      await batch.commit();
    }

    for (final plantId in ids) {
      await WateringService().addWateringIfMissingBeforeFertilizing(
        plantId: plantId,
        fertilizedAt: appliedAt,
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

    await _fertilizingRef(plantId).doc(fertilizingId).update({
      'fertilizerId': fertilizerId ?? FieldValue.delete(),
      'fertilizerName': storedName ?? FieldValue.delete(),
      'waterMl': normalizeWaterMl(waterMl),
      'components': components.map((e) => e.toMap()).toList(),
      'appliedAt': Timestamp.fromDate(appliedAt),
      'applicationMethod': applicationMethod.code,
      'nextFertilizing':
          nextFertilizing != null ? Timestamp.fromDate(nextFertilizing) : null,
    });

    await _syncLastFertilizedAt(plantId);
  }

  Stream<List<FertilizingEntry>> getFertilizingHistory(
    String plantId, {
    int limit = 40,
  }) {
    return _fertilizingRef(plantId)
        .orderBy('appliedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FertilizingEntry.fromFirestoreData(
          id: doc.id,
          data: data,
          fertilizerName: resolveStoredFertilizerName(data) ?? '',
        );
      }).toList();
    });
  }

  Stream<FertilizingEntry?> watchLastFertilizing(String plantId) {
    return _fertilizingRef(plantId)
        .orderBy('appliedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();
      return FertilizingEntry.fromFirestoreData(
        id: doc.id,
        data: data,
        fertilizerName: resolveStoredFertilizerName(data) ?? '',
      );
    });
  }

  Future<void> deleteFertilizing({
    required String plantId,
    required String fertilizingId,
  }) async {
    await _fertilizingRef(plantId).doc(fertilizingId).delete();
    await _syncLastFertilizedAt(plantId);
  }
}
