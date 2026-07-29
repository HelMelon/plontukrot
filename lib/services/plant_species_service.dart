import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plant_species.dart';

class PlantSpeciesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('plantSpecies');

  Future<void> ensureSpecies({
    required String species,
    required String genus,
    String? plantFamily,
  }) async {
    final trimmedSpecies = species.trim();
    if (trimmedSpecies.isEmpty) return;

    final docId = PlantSpecies.docIdFor(trimmedSpecies);
    final docRef = _ref.doc(docId);
    final existing = await docRef.get();
    if (existing.exists) return;

    final trimmedFamily = plantFamily?.trim();
    await docRef.set({
      'species': trimmedSpecies,
      'genus': genus.trim(),
      'plantFamily':
          (trimmedFamily == null || trimmedFamily.isEmpty) ? null : trimmedFamily,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<PlantSpecies?> watchSpecies(String species) {
    final trimmed = species.trim();
    if (trimmed.isEmpty) {
      return Stream.value(null);
    }
    return _ref.doc(PlantSpecies.docIdFor(trimmed)).snapshots().map(
          (doc) => doc.exists ? PlantSpecies.fromDocument(doc) : null,
        );
  }
}
