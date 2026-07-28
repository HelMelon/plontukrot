import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/component.dart';
import '../models/repotting_entry.dart';

class RepottingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _plantsCollection {
    return _db.collection('users').doc(_uid).collection('plants');
  }

  CollectionReference<Map<String, dynamic>> _repottingRef(String plantId) {
    return _plantsCollection.doc(plantId).collection('repotting');
  }

  Future<void> _syncLastRepottedAt(String plantId) async {
    final snapshot = await _repottingRef(plantId)
        .orderBy('repottedAt', descending: true)
        .limit(1)
        .get();

    await _plantsCollection.doc(plantId).update({
      'lastRepottedAt': snapshot.docs.isEmpty
          ? FieldValue.delete()
          : snapshot.docs.first.data()['repottedAt'],
      'careHistoryMigrated': true,
    });
  }

  Future<void> addRepotting({
    required String plantId,
    required DateTime repottedAt,
    required List<SoilComponent> components,
    String? soilId,
    String? soilName,
    bool slowReleaseFertilizer = false,
  }) async {
    final plantDoc = await _plantsCollection.doc(plantId).get();
    final plantData = plantDoc.data();
    final lastRepottedAt = plantData?['lastRepottedAt'] as Timestamp?;

    await _repottingRef(plantId).add({
      'repottedAt': Timestamp.fromDate(repottedAt),
      'createdAt': FieldValue.serverTimestamp(),
      if (soilId != null) 'soilId': soilId,
      if (soilName != null) 'soilName': soilName,
      'components': components.map((e) => e.toMap()).toList(),
      'slowReleaseFertilizer': slowReleaseFertilizer,
    });

    if (lastRepottedAt == null || repottedAt.isAfter(lastRepottedAt.toDate())) {
      await _plantsCollection.doc(plantId).update({
        'lastRepottedAt': Timestamp.fromDate(repottedAt),
        'careHistoryMigrated': true,
      });
    }
  }

  Stream<List<RepottingEntry>> getRepottingHistory(String plantId) {
    return _repottingRef(plantId)
        .orderBy('repottedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(RepottingEntry.fromFirestore).toList(),
        );
  }

  Stream<RepottingEntry?> watchLastRepotting(String plantId) {
    return _repottingRef(plantId)
        .orderBy('repottedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return RepottingEntry.fromFirestore(snapshot.docs.first);
    });
  }

  Future<void> deleteRepotting({
    required String plantId,
    required String repottingId,
  }) async {
    await _repottingRef(plantId).doc(repottingId).delete();
    await _syncLastRepottedAt(plantId);
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
    await _repottingRef(plantId).doc(repottingId).update({
      'repottedAt': Timestamp.fromDate(repottedAt),
      'soilId': soilId ?? FieldValue.delete(),
      'soilName': soilName ?? FieldValue.delete(),
      'components': components.map((e) => e.toMap()).toList(),
      'slowReleaseFertilizer': slowReleaseFertilizer,
    });

    await _syncLastRepottedAt(plantId);
  }
}
