import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

/// Catalog entry for a reusable fertilizer ingredient.
class FertilizerIngredient {
  final String id;
  final String name;
  final DateTime? createdAt;

  const FertilizerIngredient({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory FertilizerIngredient.fromMap(String id, Map<String, dynamic> data) {
    return FertilizerIngredient(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: readTimestamp(data['createdAt']),
    );
  }

  factory FertilizerIngredient.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return FertilizerIngredient.fromMap(doc.id, doc.data());
  }
}
