import 'package:cloud_firestore/cloud_firestore.dart';

import 'component.dart';
import 'firestore_helpers.dart';

class RepottingEntry {
  final String? id;
  final DateTime repottedAt;
  final String? soilId;
  final String? soilName;
  final List<SoilComponent> components;
  final bool slowReleaseFertilizer;

  const RepottingEntry({
    this.id,
    required this.repottedAt,
    this.soilId,
    this.soilName,
    this.components = const [],
    this.slowReleaseFertilizer = false,
  });

  factory RepottingEntry.fromMap(String? id, Map<String, dynamic> data) {
    final rawComponents = data['components'] as List<dynamic>?;

    return RepottingEntry(
      id: id,
      repottedAt: readTimestamp(data['repottedAt']) ?? DateTime.now(),
      soilId: data['soilId'] as String?,
      soilName: data['soilName'] as String?,
      components: rawComponents != null
          ? rawComponents
              .map((item) => SoilComponent.fromMap(item as Map<String, dynamic>))
              .toList()
          : const [],
      slowReleaseFertilizer: data['slowReleaseFertilizer'] as bool? ?? false,
    );
  }

  factory RepottingEntry.fromFirestore(QueryDocumentSnapshot doc) {
    return RepottingEntry.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'repottedAt': Timestamp.fromDate(repottedAt),
      if (soilId != null) 'soilId': soilId,
      if (soilName != null) 'soilName': soilName,
      'components': components.map((e) => e.toMap()).toList(),
      'slowReleaseFertilizer': slowReleaseFertilizer,
    };
  }
}
