import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/component.dart';
import '../models/soil.dart';

class SoilService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _soilsRef =>
      _db.collection('users').doc(_uid).collection('soils');

  Future<Soil?> findSoilByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    final snapshot = await _soilsRef.get();
    for (final doc in snapshot.docs) {
      final existingName = (doc.data()['name'] as String?)?.trim() ?? '';
      if (existingName.toLowerCase() == lower) {
        return Soil.fromMap(doc.id, doc.data());
      }
    }
    return null;
  }

  /// Creates a soil mix, or returns the existing id if the name already exists
  /// (case-insensitive). Does not overwrite an existing mix.
  Future<String> ensureSoil({
    required String name,
    required List<SoilComponent> components,
  }) async {
    final existing = await findSoilByName(name);
    if (existing != null) return existing.id;
    return addSoil(name: name, components: components);
  }

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
