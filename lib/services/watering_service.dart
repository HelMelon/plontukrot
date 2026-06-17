import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WateringService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _plantsCollection {
    return _db.collection('users').doc(_uid).collection('plants');
  }

  CollectionReference<Map<String, dynamic>> _wateringRef(String plantId) {
    return _plantsCollection.doc(plantId).collection('watering');
  }

  Future<void> addWatering({
    required String plantId,
    required DateTime wateredAt,
  }) async {
    final plantDoc = await _plantsCollection.doc(plantId).get();

    final plantData = plantDoc.data();

    DateTime? nextWatering;

    final frequency = plantData?['wateringFrequency'] as int?;

    if (frequency != null && frequency > 0) {
      nextWatering = wateredAt.add(Duration(days: frequency));
    }

    await _wateringRef(plantId).add({
      'wateredAt': Timestamp.fromDate(wateredAt),
      'nextWatering': nextWatering != null
          ? Timestamp.fromDate(nextWatering)
          : null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getWateringHistory(String plantId) {
    return _wateringRef(
      plantId,
    ).orderBy('wateredAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'wateredAt': (data['wateredAt'] as Timestamp).toDate(),
          'nextWatering': data['nextWatering'] != null
              ? (data['nextWatering'] as Timestamp).toDate()
              : null,
        };
      }).toList();
    });
  }

  Stream<Map<String, dynamic>?> watchLastWatering(String plantId) {
    return _wateringRef(plantId)
        .orderBy('wateredAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;

          final data = snapshot.docs.first.data();

          return {
            'wateredAt': (data['wateredAt'] as Timestamp).toDate(),
            'nextWatering': data['nextWatering'] != null
                ? (data['nextWatering'] as Timestamp).toDate()
                : null,
          };
        });
  }

  Future<Map<String, dynamic>?> getLastWatering(String plantId) async {
    final snapshot = await _wateringRef(
      plantId,
    ).orderBy('wateredAt', descending: true).limit(1).get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();

    return {
      'id': snapshot.docs.first.id,
      'wateredAt': (data['wateredAt'] as Timestamp).toDate(),
      'nextWatering': data['nextWatering'] != null
          ? (data['nextWatering'] as Timestamp).toDate()
          : null,
    };
  }

  Future<void> deleteWatering({
    required String plantId,
    required String wateringId,
  }) async {
    await _wateringRef(plantId).doc(wateringId).delete();
  }

  Future<void> updateWatering({
    required String plantId,
    required String wateringId,
    DateTime? wateredAt,
  }) async {
    final updateData = <String, dynamic>{};

    if (wateredAt != null) {
      updateData['wateredAt'] = Timestamp.fromDate(wateredAt);

      final plantDoc = await _plantsCollection.doc(plantId).get();

      final frequency = plantDoc.data()?['wateringFrequency'] as int?;

      if (frequency != null && frequency > 0) {
        updateData['nextWatering'] = Timestamp.fromDate(
          wateredAt.add(Duration(days: frequency)),
        );
      } else {
        updateData['nextWatering'] = null;
      }
    }

    await _wateringRef(plantId).doc(wateringId).update(updateData);
  }
}
