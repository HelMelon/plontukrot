import 'model_helpers.dart';

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
      name: readString(data, 'name') ?? '',
      createdAt: readDate(data, 'createdAt'),
    );
  }
}
