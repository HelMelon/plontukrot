import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';
import 'component.dart';

class Soil {
  final String id;
  final String name;
  final DateTime? createdAt;
  final List<SoilComponent> components;

  const Soil({
    required this.id,
    required this.name,
    this.createdAt,
    this.components = const [],
  });

  factory Soil.fromMap(String id, Map<String, dynamic> data) {
    var rawComponents = data['components'] as List<dynamic>?;

    List<SoilComponent> parsedComponents = rawComponents != null
        ? rawComponents
            .map((item) => SoilComponent.fromMap(item as Map<String, dynamic>))
            .toList()
        : [];

    return Soil(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: readTimestamp(data['createdAt']),
      components: parsedComponents,
    );
  }

  factory Soil.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Soil.fromMap(doc.id, doc.data());
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': createdAt,
      'components': components.map((e) => e.toMap()).toList(),
    };
  }
}
