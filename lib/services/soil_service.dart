import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/component.dart';
import '../models/soil.dart';

class SoilService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _soilsRef =>
      _db.collection('users').doc(_uid).collection('soils');

  Future<String> addSoil({
    required String name,
    required List<SoilComponent> components,
  }) async {
    final doc = await _soilsRef.add({
      'name': name,
      'components': components.map((e) => e.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Stream<List<Soil>> getSoils() {
    return _soilsRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(Soil.fromFirestore).toList(),
        );
  }

  Future<Soil?> getSoil(String soilId) async {
    final doc = await _soilsRef.doc(soilId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Soil.fromMap(doc.id, doc.data()!);
  }
}
