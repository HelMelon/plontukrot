import 'component.dart';
import 'model_helpers.dart';

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
    final rawComponents = readField(data, 'components') as List<dynamic>?;

    final parsedComponents = rawComponents != null
        ? rawComponents
            .whereType<Map>()
            .map(
              (item) => SoilComponent.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList()
        : <SoilComponent>[];

    return Soil(
      id: id,
      name: readString(data, 'name') ?? '',
      createdAt: readDate(data, 'createdAt'),
      components: parsedComponents,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': isoOrNull(createdAt),
      'components': components.map((e) => e.toMap()).toList(),
    };
  }
}
