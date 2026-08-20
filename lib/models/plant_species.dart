import 'model_helpers.dart';

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
    final trimmedFamily = readString(data, 'plantFamily')?.trim();
    return PlantSpecies(
      id: id,
      species: readString(data, 'species') ?? '',
      genus: readString(data, 'genus') ?? '',
      plantFamily:
          (trimmedFamily == null || trimmedFamily.isEmpty) ? null : trimmedFamily,
      createdAt: readDate(data, 'createdAt'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'species': species,
      'genus': genus,
      'plantFamily': plantFamily,
      'plant_family': plantFamily,
      if (createdAt != null) 'createdAt': isoOrNull(createdAt),
    };
  }

  /// Deterministic catalog id from a species display name.
  static String docIdFor(String species) {
    return species.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }
}
