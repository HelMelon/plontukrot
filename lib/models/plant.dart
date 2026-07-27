import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

class Plant {
  final String id;
  final String name;
  final String nickname;
  final String family;
  final int stage;
  final String? imageUrl;
  final int? wateringFrequency;
  final DateTime? createdAt;

  const Plant({
    required this.id,
    required this.name,
    required this.nickname,
    required this.family,
    required this.stage,
    this.imageUrl,
    this.wateringFrequency,
    this.createdAt,
  });

  factory Plant.fromMap(String id, Map<String, dynamic> data) {
    return Plant(
      id: id,
      name: data['name'] as String? ?? '',
      nickname: data['nickname'] as String? ?? '',
      family: data['family'] as String? ?? '',
      stage: data['stage'] as int? ?? 0,
      imageUrl: data['imageUrl'] as String?,
      wateringFrequency: data['wateringFrequency'] as int?,
      createdAt: readTimestamp(data['createdAt']),
    );
  }

  factory Plant.fromFirestore(QueryDocumentSnapshot doc) {
    return Plant.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  factory Plant.fromDocument(DocumentSnapshot doc) {
    return Plant.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nickname': nickname,
      'family': family,
      'stage': stage,
      'imageUrl': imageUrl,
      'wateringFrequency': wateringFrequency,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
