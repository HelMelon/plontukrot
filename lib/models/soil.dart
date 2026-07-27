import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

class Fertilizer {
  final String id;
  final String name;
  final String type;
  final DateTime? createdAt;

  const Fertilizer({
    required this.id,
    required this.name,
    required this.type,
    this.createdAt,
  });

  factory Fertilizer.fromMap(String id, Map<String, dynamic> data) {
    return Fertilizer(
      id: id,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? '',
      createdAt: readTimestamp(data['createdAt']),
    );
  }

  factory Fertilizer.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Fertilizer.fromMap(doc.id, doc.data());
  }
}
