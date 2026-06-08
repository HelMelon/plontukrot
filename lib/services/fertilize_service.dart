import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FertilizeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // ─────────────────────────────
  // 🌿 FERTILIZERS CATALOG
  // ─────────────────────────────

  CollectionReference<Map<String, dynamic>> get _fertilizersRef =>
      _db.collection('users').doc(uid).collection('fertilizers');

  Future<String> addFertilizer({
    required String name,
    required String type,
  }) async {
    final doc = await _fertilizersRef.add({
      'name': name,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFertilizers() {
    return _fertilizersRef.orderBy('createdAt', descending: true).snapshots();
  }

  // ─────────────────────────────
  // 🌱 FERTILIZING HISTORY (per plant)
  // ─────────────────────────────

  CollectionReference<Map<String, dynamic>> _fertilizingRef(String plantId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('plants')
        .doc(plantId)
        .collection('fertilizing');
  }

  Future<void> addFertilizing({
    required String plantId,
    required String fertilizerId,
    required DateTime appliedAt,
    DateTime? nextFertilizing,
  }) async {
    await _fertilizingRef(plantId).add({
      'fertilizerId': fertilizerId,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'nextFertilizing': nextFertilizing != null
          ? Timestamp.fromDate(nextFertilizing)
          : null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getFertilizingHistory(String plantId) {
    return _fertilizingRef(
      plantId,
    ).orderBy('appliedAt', descending: true).snapshots().asyncMap((
      snapshot,
    ) async {
      final fertilizersSnap = await _fertilizersRef.get();

      final fertilizerMap = {
        for (var doc in fertilizersSnap.docs)
          doc.id: doc.data()['name'] as String,
      };

      return snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'fertilizerId': data['fertilizerId'],
          'fertilizerName': fertilizerMap[data['fertilizerId']] ?? 'Unknown',
          'appliedAt': (data['appliedAt'] as Timestamp).toDate(),
          'nextFertilizing': data['nextFertilizing'] != null
              ? (data['nextFertilizing'] as Timestamp).toDate()
              : null,
        };
      }).toList();
    });
  }

  Future<void> deleteFertilizing({
    required String plantId,
    required String fertilizingId,
  }) async {
    await _fertilizingRef(plantId).doc(fertilizingId).delete();
  }
}
