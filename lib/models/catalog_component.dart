import 'model_helpers.dart';

/// Catalog entry for a reusable soil ingredient.
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
      name: readString(data, 'name') ?? '',
      createdAt: readDate(data, 'createdAt'),
    );
  }
}
