import 'component.dart';
import 'model_helpers.dart';

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
    final rawComponents = readField(data, 'components') as List<dynamic>?;

    return RepottingEntry(
      id: id,
      repottedAt: readDate(data, 'repottedAt') ?? DateTime.now(),
      soilId: readString(data, 'soilId'),
      soilName: readString(data, 'soilName'),
      components: rawComponents != null
          ? rawComponents
              .whereType<Map>()
              .map((item) => SoilComponent.fromMap(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      slowReleaseFertilizer: readBool(data, 'slowReleaseFertilizer'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'repottedAt': isoOrNull(repottedAt),
      'repotted_at': isoOrNull(repottedAt),
      if (soilId != null) 'soilId': soilId,
      if (soilId != null) 'soil_id': soilId,
      if (soilName != null) 'soilName': soilName,
      if (soilName != null) 'soil_name': soilName,
      'components': components.map((e) => e.toMap()).toList(),
      'slowReleaseFertilizer': slowReleaseFertilizer,
      'slow_release_fertilizer': slowReleaseFertilizer,
    };
  }
}
