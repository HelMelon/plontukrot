import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

class Stimulator {
  final String id;
  final String name;
  final String? defaultDosage;
  final DateTime? createdAt;

  const Stimulator({
    required this.id,
    required this.name,
    this.defaultDosage,
    this.createdAt,
  });

  factory Stimulator.fromMap(String id, Map<String, dynamic> data) {
    return Stimulator(
      id: id,
      name: data['name'] as String? ?? '',
      defaultDosage: _nullableTrimmed(data['defaultDosage'] as String?),
      createdAt: readTimestamp(data['createdAt']),
    );
  }

  factory Stimulator.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Stimulator.fromMap(doc.id, doc.data());
  }

  static String? _nullableTrimmed(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (defaultDosage != null) 'defaultDosage': defaultDosage,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
