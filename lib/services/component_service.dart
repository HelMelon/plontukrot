import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/catalog_component.dart';

const List<String> kDefaultSoilComponentNames = [
  'Perlite',
  'Coco coir',
  'Bark',
  'Peat',
  'Sand',
  'Charcoal',
  'Zeolite',
  'Pumice',
  'Worm castings',
  'Vermiculite',
];

class ComponentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _componentsRef =>
      _db.collection('users').doc(_uid).collection('components');

  Future<CatalogComponent?> findComponentByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    final snapshot = await _componentsRef.get();
    for (final doc in snapshot.docs) {
      final existingName = (doc.data()['name'] as String?)?.trim() ?? '';
      if (existingName.toLowerCase() == lower) {
        return CatalogComponent.fromMap(doc.id, doc.data());
      }
    }
    return null;
  }

  /// Creates a component, or returns the existing id if the name already exists
  /// (case-insensitive).
  Future<String> ensureComponent({required String name}) async {
    final existing = await findComponentByName(name);
    if (existing != null) return existing.id;
    return addComponent(name: name);
  }

  Future<String> addComponent({required String name}) async {
    final trimmed = name.trim();
    final doc = await _componentsRef.add({
      'name': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateComponent({
    required String componentId,
    required String name,
  }) async {
    await _componentsRef.doc(componentId).update({
      'name': name.trim(),
    });
  }

  Future<void> deleteComponent(String componentId) async {
    await _componentsRef.doc(componentId).delete();
  }

  Stream<List<CatalogComponent>> getComponents() {
    return _componentsRef.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs.map(CatalogComponent.fromFirestore).toList(),
        );
  }

  /// Seeds the catalog with defaults once if it is empty.
  Future<void> ensureDefaultComponents() async {
    final existing = await _componentsRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final name in kDefaultSoilComponentNames) {
      final ref = _componentsRef.doc();
      batch.set(ref, {
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
