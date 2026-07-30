import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';
import 'variegation.dart';

class Plant {
  final String id;
  final String genus;
  final String species;
  final String? cultivar;
  final String? plantFamily;
  final Variegation variegation;
  final String tradingName;
  final String nickname;
  final int stage;
  final String? imageUrl;
  final String? imageThumbUrl;
  final int? wateringFrequency;
  final DateTime? createdAt;
  final DateTime? lastWateredAt;
  final DateTime? lastFertilizedAt;
  final String? lastFertilizerName;
  final DateTime? lastRepottedAt;
  final bool careHistoryMigrated;
  final bool botanicalFieldsMigrated;

  const Plant({
    required this.id,
    required this.genus,
    required this.species,
    this.cultivar,
    this.plantFamily,
    this.variegation = Variegation.none,
    this.tradingName = '',
    required this.nickname,
    required this.stage,
    this.imageUrl,
    this.imageThumbUrl,
    this.wateringFrequency,
    this.createdAt,
    this.lastWateredAt,
    this.lastFertilizedAt,
    this.lastFertilizerName,
    this.lastRepottedAt,
    this.careHistoryMigrated = false,
    this.botanicalFieldsMigrated = false,
  });

  /// Prefer thumb for lists/grids; fall back to full image.
  String? get listImageUrl {
    final thumb = imageThumbUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final full = imageUrl?.trim();
    if (full != null && full.isNotEmpty) return full;
    return null;
  }

  static String? _nullableTrimmed(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  factory Plant.fromMap(String id, Map<String, dynamic> data) {
    final rawFamily = data['plantFamily'] as String? ?? data['family'] as String?;
    return Plant(
      id: id,
      genus: data['genus'] as String? ?? '',
      species: data['species'] as String? ?? data['name'] as String? ?? '',
      cultivar: _nullableTrimmed(data['cultivar'] as String?),
      plantFamily: _nullableTrimmed(rawFamily),
      variegation: Variegation.fromStorage(data['variegation'] as String?),
      tradingName: data['tradingName'] as String? ?? '',
      nickname: data['nickname'] as String? ?? '',
      stage: data['stage'] as int? ?? 0,
      imageUrl: data['imageUrl'] as String?,
      imageThumbUrl: data['imageThumbUrl'] as String?,
      wateringFrequency: data['wateringFrequency'] as int?,
      createdAt: readTimestamp(data['createdAt']),
      lastWateredAt: readTimestamp(data['lastWateredAt']),
      lastFertilizedAt: readTimestamp(data['lastFertilizedAt']),
      lastFertilizerName: _nullableTrimmed(data['lastFertilizerName'] as String?),
      lastRepottedAt: readTimestamp(data['lastRepottedAt']),
      careHistoryMigrated: data['careHistoryMigrated'] as bool? ?? false,
      botanicalFieldsMigrated:
          data['botanicalFieldsMigrated'] as bool? ?? false,
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
      'genus': genus,
      'species': species,
      'cultivar': cultivar,
      'plantFamily': plantFamily,
      'variegation': variegation.storageValue,
      'tradingName': tradingName,
      'nickname': nickname,
      'stage': stage,
      'imageUrl': imageUrl,
      'imageThumbUrl': imageThumbUrl,
      'wateringFrequency': wateringFrequency,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (lastWateredAt != null)
        'lastWateredAt': Timestamp.fromDate(lastWateredAt!),
      if (lastFertilizedAt != null)
        'lastFertilizedAt': Timestamp.fromDate(lastFertilizedAt!),
      if (lastFertilizerName != null)
        'lastFertilizerName': lastFertilizerName,
      if (lastRepottedAt != null)
        'lastRepottedAt': Timestamp.fromDate(lastRepottedAt!),
      'careHistoryMigrated': careHistoryMigrated,
      'botanicalFieldsMigrated': botanicalFieldsMigrated,
    };
  }
}
