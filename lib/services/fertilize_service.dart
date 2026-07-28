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

  Future<void> _syncLastFertilizedAt(String plantId) async {
    final snapshot = await _fertilizingRef(plantId)
        .orderBy('appliedAt', descending: true)
        .limit(1)
        .get();

    await _plantRef(plantId).update({
      'lastFertilizedAt': snapshot.docs.isEmpty
          ? FieldValue.delete()
          : snapshot.docs.first.data()['appliedAt'],
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
  }) async {
    final plantRef = _plantRef(plantId);
    final plant = await plantRef.get();
    final lastFertilizedAt = plant.data()?['lastFertilizedAt'] as Timestamp?;

    await _fertilizingRef(plantId).add({
      if (fertilizerId != null) 'fertilizerId': fertilizerId,
      if (fertilizerName != null) 'fertilizerName': fertilizerName,
      'waterMl': normalizeWaterMl(waterMl),
      'components': components.map((e) => e.toMap()).toList(),
      'appliedAt': Timestamp.fromDate(appliedAt),
      'applicationMethod': applicationMethod.code,
      'nextFertilizing':
          nextFertilizing != null ? Timestamp.fromDate(nextFertilizing) : null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (lastFertilizedAt == null ||
        appliedAt.isAfter(lastFertilizedAt.toDate())) {
      await plantRef.update({
        'lastFertilizedAt': Timestamp.fromDate(appliedAt),
        'careHistoryMigrated': true,
      });
    }

    await WateringService().addWateringIfMissingBeforeFertilizing(
      plantId: plantId,
      fertilizedAt: appliedAt,
    );
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
    await _fertilizingRef(plantId).doc(fertilizingId).update({
      'fertilizerId': fertilizerId ?? FieldValue.delete(),
      'fertilizerName': fertilizerName ?? FieldValue.delete(),
      'waterMl': normalizeWaterMl(waterMl),
      'components': components.map((e) => e.toMap()).toList(),
      'appliedAt': Timestamp.fromDate(appliedAt),
      'applicationMethod': applicationMethod.code,
      'nextFertilizing':
          nextFertilizing != null ? Timestamp.fromDate(nextFertilizing) : null,
    });

    await _syncLastFertilizedAt(plantId);
  }

  Stream<List<FertilizingEntry>> getFertilizingHistory(String plantId) {
    return _fertilizingRef(plantId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final fertilizersSnap = await _fertilizersRef.get();
      final fertilizerMap = {
        for (var doc in fertilizersSnap.docs)
          doc.id: doc.data()['name'] as String? ?? 'Unknown',
      };

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final fertilizerId = data['fertilizerId'] as String?;
        final storedName = data['fertilizerName'] as String?;
        final resolvedName = storedName ??
            (fertilizerId != null
                ? fertilizerMap[fertilizerId] ?? 'Unknown'
                : 'Custom mix');

        return FertilizingEntry.fromFirestoreData(
          id: doc.id,
          data: data,
          fertilizerName: resolvedName,
        );
      }).toList();
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
