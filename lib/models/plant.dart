import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';
import 'plant_archive_reason.dart';
import 'plant_member.dart';
import 'plant_photo.dart';
import 'variegation.dart';

class Plant {
  static const maxGalleryPhotos = 5;

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
  final List<PlantPhoto> images;
  final int? wateringFrequency;
  final int? fertilizingFrequencyDays;
  final bool isFertilizingFrequencyCustom;
  final DateTime? createdAt;
  final DateTime? lastWateredAt;
  final DateTime? lastFertilizedAt;
  final String? lastFertilizerName;
  final DateTime? lastRepottedAt;
  final DateTime? lastManipulationAt;
  final int initialLeafCount;
  final List<PlantMember> members;
  final DateTime? archivedAt;
  final DateTime? expiresAt;
  final PlantArchiveReason? archiveReason;
  final String? archiveNote;
  final String? mergedIntoPlantId;
  final String? giftedToUid;

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
    this.images = const [],
    this.wateringFrequency,
    this.fertilizingFrequencyDays,
    this.isFertilizingFrequencyCustom = false,
    this.createdAt,
    this.lastWateredAt,
    this.lastFertilizedAt,
    this.lastFertilizerName,
    this.lastRepottedAt,
    this.lastManipulationAt,
    this.initialLeafCount = 0,
    this.members = const [],
    this.archivedAt,
    this.expiresAt,
    this.archiveReason,
    this.archiveNote,
    this.mergedIntoPlantId,
    this.giftedToUid,
  });

  bool get isGroup => members.length >= 2;

  bool get isArchived => archivedAt != null;

  bool get isArchiveVisible {
    if (!isArchived) return false;
    final expires = expiresAt;
    if (expires == null) return true;
    return expires.isAfter(DateTime.now());
  }

  /// Cultivar labels for display: group members, else single cultivar.
  List<String> get cultivarLabels {
    if (isGroup) {
      return members
          .map((m) => (m.cultivar ?? '').trim())
          .where((c) => c.isNotEmpty)
          .toList();
    }
    final single = (cultivar ?? '').trim();
    return single.isEmpty ? const [] : [single];
  }

  String get cultivarsDisplay {
    final labels = cultivarLabels;
    if (labels.isEmpty) return '';
    return labels.join(' · ');
  }

  /// Prefer thumb for lists/grids; fall back to full image.
  String? get listImageUrl {
    final thumb = imageThumbUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final full = imageUrl?.trim();
    if (full != null && full.isNotEmpty) return full;
    return null;
  }

  /// Gallery for UI: persisted `images`, or a single legacy cover photo.
  List<PlantPhoto> get galleryPhotos {
    if (images.isNotEmpty) return images;
    final full = imageUrl?.trim();
    if (full == null || full.isEmpty) return const [];
    final thumb = imageThumbUrl?.trim();
    return [
      PlantPhoto(
        id: PlantPhoto.legacyId,
        imageUrl: full,
        imageThumbUrl:
            (thumb != null && thumb.isNotEmpty) ? thumb : full,
        // Not a real upload time — cover may have been replaced long after
        // plant creation. UI hides the date for legacy photos.
        addedAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      ),
    ];
  }

  static String? _nullableTrimmed(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<PlantMember> _readMembers(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => PlantMember.fromMap(Map<String, dynamic>.from(e)))
        .take(3)
        .toList();
  }

  static List<PlantPhoto> _readImages(dynamic raw) {
    if (raw is! List) return const [];
    final photos = raw
        .whereType<Map>()
        .map((e) => PlantPhoto.fromMap(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.imageUrl.isNotEmpty)
        .toList();
    // Newest first so details PageView opens on the latest photo.
    photos.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    if (photos.length <= maxGalleryPhotos) return photos;
    return photos.sublist(0, maxGalleryPhotos);
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
      images: _readImages(data['images']),
      wateringFrequency: data['wateringFrequency'] as int?,
      fertilizingFrequencyDays: data['fertilizingFrequencyDays'] as int?,
      isFertilizingFrequencyCustom:
          data['isFertilizingFrequencyCustom'] as bool? ?? false,
      createdAt: readTimestamp(data['createdAt']),
      lastWateredAt: readTimestamp(data['lastWateredAt']),
      lastFertilizedAt: readTimestamp(data['lastFertilizedAt']),
      lastFertilizerName: _nullableTrimmed(data['lastFertilizerName'] as String?),
      lastRepottedAt: readTimestamp(data['lastRepottedAt']),
      lastManipulationAt: readTimestamp(data['lastManipulationAt']),
      initialLeafCount: data['initialLeafCount'] as int? ?? 0,
      members: _readMembers(data['members']),
      archivedAt: readTimestamp(data['archivedAt']),
      expiresAt: readTimestamp(data['expiresAt']),
      archiveReason: PlantArchiveReason.fromCode(
        data['archiveReason'] as String?,
      ),
      archiveNote: _nullableTrimmed(data['archiveNote'] as String?),
      mergedIntoPlantId: data['mergedIntoPlantId'] as String?,
      giftedToUid: data['giftedToUid'] as String?,
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
      'images': images.map((p) => p.toMap()).toList(),
      'wateringFrequency': wateringFrequency,
      'fertilizingFrequencyDays': fertilizingFrequencyDays,
      'isFertilizingFrequencyCustom': isFertilizingFrequencyCustom,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (lastWateredAt != null)
        'lastWateredAt': Timestamp.fromDate(lastWateredAt!),
      if (lastFertilizedAt != null)
        'lastFertilizedAt': Timestamp.fromDate(lastFertilizedAt!),
      if (lastFertilizerName != null)
        'lastFertilizerName': lastFertilizerName,
      if (lastRepottedAt != null)
        'lastRepottedAt': Timestamp.fromDate(lastRepottedAt!),
      if (lastManipulationAt != null)
        'lastManipulationAt': Timestamp.fromDate(lastManipulationAt!),
      'initialLeafCount': initialLeafCount,
      if (members.isNotEmpty) 'members': members.map((m) => m.toMap()).toList(),
      if (archivedAt != null) 'archivedAt': Timestamp.fromDate(archivedAt!),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (archiveReason != null) 'archiveReason': archiveReason!.code,
      if (archiveNote != null) 'archiveNote': archiveNote,
      if (mergedIntoPlantId != null) 'mergedIntoPlantId': mergedIntoPlantId,
      if (giftedToUid != null) 'giftedToUid': giftedToUid,
    };
  }
}
