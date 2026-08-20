import 'model_helpers.dart';

class WishListItem {
  final String id;
  final String nameEn;
  final String nameAlt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WishListItem({
    required this.id,
    required this.nameEn,
    required this.nameAlt,
    this.createdAt,
    this.updatedAt,
  });

  factory WishListItem.fromMap(String id, Map<String, dynamic> data) {
    return WishListItem(
      id: id,
      nameEn: readString(data, 'nameEn') ?? '',
      nameAlt: readString(data, 'nameAlt') ??
          readString(data, 'nameRu') ??
          '',
      createdAt: readDate(data, 'createdAt'),
      updatedAt: readDate(data, 'updatedAt'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameEn': nameEn,
      'name_en': nameEn,
      'nameAlt': nameAlt,
      'name_alt': nameAlt,
      if (createdAt != null) 'createdAt': isoOrNull(createdAt),
      if (updatedAt != null) 'updatedAt': isoOrNull(updatedAt),
    };
  }
}
