import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

class PlantSpecies {
  final String id;
  final String species;
  final String genus;
  final String? plantFamily;
  final DateTime? createdAt;

  const PlantSpecies({
    required this.id,
    required this.species,
    required this.genus,
    this.plantFamily,
    this.createdAt,
  });

  factory PlantSpecies.fromMap(String id, Map<String, dynamic> data) {
    final rawFamily = data['plantFamily'] as String?;
    final trimmedFamily = rawFamily?.trim();
    return PlantSpecies(
      id: id,
      species: data['species'] as String? ?? '',
      genus: data['genus'] as String? ?? '',
      plantFamily:
          (trimmedFamily == null || trimmedFamily.isEmpty) ? null : trimmedFamily,
      createdAt: readTimestamp(data['createdAt']),
    );
  }

  factory PlantSpecies.fromFirestore(QueryDocumentSnapshot doc) {
    return PlantSpecies.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  factory PlantSpecies.fromDocument(DocumentSnapshot doc) {
    return PlantSpecies.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'species': species,
      'genus': genus,
      'plantFamily': plantFamily,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  /// Deterministic Firestore document id from a species display name.
  static String docIdFor(String species) {
    return species.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }
}
