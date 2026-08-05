import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

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
      nameEn: data['nameEn'] as String? ?? '',
      // Prefer nameAlt; fall back to legacy nameRu from early WishLeafs docs.
      nameAlt: data['nameAlt'] as String? ?? data['nameRu'] as String? ?? '',
      createdAt: readTimestamp(data['createdAt']),
      updatedAt: readTimestamp(data['updatedAt']),
    );
  }

  factory WishListItem.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return WishListItem.fromMap(doc.id, doc.data());
  }

  Map<String, dynamic> toMap() {
    return {
      'nameEn': nameEn,
      'nameAlt': nameAlt,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
