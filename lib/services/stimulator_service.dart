import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/stimulator.dart';

class StimulatorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _stimulatorsRef =>
      _db.collection('users').doc(uid).collection('stimulators');

  Future<Stimulator?> findStimulatorByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    final snapshot = await _stimulatorsRef.get();
    for (final doc in snapshot.docs) {
      final existingName = (doc.data()['name'] as String?)?.trim() ?? '';
      if (existingName.toLowerCase() == lower) {
        return Stimulator.fromMap(doc.id, doc.data());
      }
    }
    return null;
  }

  Future<String> addStimulator({
    required String name,
    String? defaultDosage,
  }) async {
    final doc = await _stimulatorsRef.add({
      'name': name.trim(),
      if (defaultDosage != null && defaultDosage.trim().isNotEmpty)
        'defaultDosage': defaultDosage.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateStimulator({
    required String stimulatorId,
    required String name,
    String? defaultDosage,
  }) async {
    final updates = <String, dynamic>{
      'name': name.trim(),
    };
    final dosage = defaultDosage?.trim();
    if (dosage != null && dosage.isNotEmpty) {
      updates['defaultDosage'] = dosage;
    } else {
      updates['defaultDosage'] = FieldValue.delete();
    }
    await _stimulatorsRef.doc(stimulatorId).update(updates);
  }

  Future<void> deleteStimulator(String stimulatorId) async {
    await _stimulatorsRef.doc(stimulatorId).delete();
  }

  Stream<List<Stimulator>> watchStimulators() {
    return _stimulatorsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Stimulator.fromFirestore).toList(),
        );
  }

  Future<Stimulator?> getStimulator(String stimulatorId) async {
    final doc = await _stimulatorsRef.doc(stimulatorId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Stimulator.fromMap(doc.id, doc.data()!);
  }
}
