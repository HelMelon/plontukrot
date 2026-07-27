import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

/// Catalog entry for a reusable soil ingredient (stored in Firestore).
class CatalogComponent {
  final String id;
  final String name;
  final DateTime? createdAt;

  const CatalogComponent({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory CatalogComponent.fromMap(String id, Map<String, dynamic> data) {
    return CatalogComponent(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: readTimestamp(data['createdAt']),
    );
  }

  factory CatalogComponent.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return CatalogComponent.fromMap(doc.id, doc.data());
  }
}
