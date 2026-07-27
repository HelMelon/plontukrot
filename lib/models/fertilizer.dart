import 'package:cloud_firestore/cloud_firestore.dart';

import 'fertilizer_dose.dart';
import 'firestore_helpers.dart';

class Fertilizer {
  final String id;
  final String name;
  final String type;
  final DateTime? createdAt;
  final int waterMl;
  final List<FertilizerDose> components;

  const Fertilizer({
    required this.id,
    required this.name,
    this.type = '',
    this.createdAt,
    this.waterMl = 250,
    this.components = const [],
  });

  factory Fertilizer.fromMap(String id, Map<String, dynamic> data) {
    final rawComponents = data['components'] as List<dynamic>?;

    return Fertilizer(
      id: id,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? '',
      createdAt: readTimestamp(data['createdAt']),
      waterMl: normalizeWaterMl((data['waterMl'] as num?)?.toInt()),
      components: rawComponents != null
          ? rawComponents
              .map((item) => FertilizerDose.fromMap(item as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  factory Fertilizer.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Fertilizer.fromMap(doc.id, doc.data());
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'waterMl': waterMl,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'components': components.map((e) => e.toMap()).toList(),
    };
  }
}
