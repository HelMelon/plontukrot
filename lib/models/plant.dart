import 'model_helpers.dart';
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
    final rawFamily =
        readString(data, 'plantFamily') ?? readString(data, 'family');
    return Plant(
      id: id,
      genus: readString(data, 'genus') ?? '',
      species: readString(data, 'species') ?? readString(data, 'name') ?? '',
      cultivar: _nullableTrimmed(readString(data, 'cultivar')),
      plantFamily: _nullableTrimmed(rawFamily),
      variegation: Variegation.fromJson(readField(data, 'variegation')),
      tradingName: readString(data, 'tradingName') ?? '',
      nickname: readString(data, 'nickname') ?? '',
      stage: readInt(data, 'stage') ?? 0,
      imageUrl: readString(data, 'imageUrl'),
      imageThumbUrl: readString(data, 'imageThumbUrl'),
      images: _readImages(readField(data, 'images')),
      wateringFrequency: readInt(data, 'wateringFrequency'),
      fertilizingFrequencyDays: readInt(data, 'fertilizingFrequencyDays'),
      isFertilizingFrequencyCustom:
          readBool(data, 'isFertilizingFrequencyCustom'),
      createdAt: readDate(data, 'createdAt'),
      lastWateredAt: readDate(data, 'lastWateredAt'),
      lastFertilizedAt: readDate(data, 'lastFertilizedAt'),
      lastFertilizerName:
          _nullableTrimmed(readString(data, 'lastFertilizerName')),
      lastRepottedAt: readDate(data, 'lastRepottedAt') ??
          readDate(data, 'last_repotted_at'),
      lastManipulationAt: readDate(data, 'lastManipulationAt') ??
          readDate(data, 'last_manipulation_at'),
      initialLeafCount: readInt(data, 'initialLeafCount') ??
          readInt(data, 'initial_leaf_count') ??
          0,
      members: _readMembers(readField(data, 'members')),
      archivedAt: readDate(data, 'archivedAt') ??
          readDate(data, 'archived_at'),
      expiresAt: readDate(data, 'expiresAt') ??
          readDate(data, 'expires_at'),
      archiveReason: PlantArchiveReason.fromCode(
        readString(data, 'archiveReason') ??
            readString(data, 'archive_reason'),
      ),
      archiveNote: _nullableTrimmed(
        readString(data, 'archiveNote') ??
            readString(data, 'archive_note'),
      ),
      mergedIntoPlantId: readString(data, 'mergedIntoPlantId') ??
          readString(data, 'merged_into_plant_id'),
      giftedToUid: readString(data, 'giftedToUid') ??
          readString(data, 'gifted_to_uid'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'genus': genus,
      'species': species,
      'cultivar': cultivar,
      'plantFamily': plantFamily,
      'plant_family': plantFamily,
      'variegation': variegation.index,
      'tradingName': tradingName,
      'trading_name': tradingName,
      'nickname': nickname,
      'stage': stage,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'imageThumbUrl': imageThumbUrl,
      'image_thumb_url': imageThumbUrl,
      'images': images.map((p) => p.toMap()).toList(),
      'wateringFrequency': wateringFrequency,
      'watering_frequency': wateringFrequency,
      'fertilizingFrequencyDays': fertilizingFrequencyDays,
      'fertilizing_frequency_days': fertilizingFrequencyDays,
      'isFertilizingFrequencyCustom': isFertilizingFrequencyCustom,
      if (createdAt != null) 'createdAt': isoOrNull(createdAt),
      if (createdAt != null) 'created_at': isoOrNull(createdAt),
      if (lastWateredAt != null) 'lastWateredAt': isoOrNull(lastWateredAt),
      if (lastWateredAt != null) 'last_watered_at': isoOrNull(lastWateredAt),
      if (lastFertilizedAt != null)
        'lastFertilizedAt': isoOrNull(lastFertilizedAt),
      if (lastFertilizedAt != null)
        'last_fertilized_at': isoOrNull(lastFertilizedAt),
      if (lastFertilizerName != null) 'lastFertilizerName': lastFertilizerName,
      if (lastRepottedAt != null) 'lastRepottedAt': isoOrNull(lastRepottedAt),
      if (lastRepottedAt != null) 'last_repotted_at': isoOrNull(lastRepottedAt),
      if (lastManipulationAt != null)
        'lastManipulationAt': isoOrNull(lastManipulationAt),
      if (lastManipulationAt != null)
        'last_manipulation_at': isoOrNull(lastManipulationAt),
      'initialLeafCount': initialLeafCount,
      'initial_leaf_count': initialLeafCount,
      if (members.isNotEmpty) 'members': members.map((m) => m.toMap()).toList(),
      if (archivedAt != null) 'archivedAt': isoOrNull(archivedAt),
      if (expiresAt != null) 'expiresAt': isoOrNull(expiresAt),
      if (archiveReason != null) 'archiveReason': archiveReason!.code,
      if (archiveNote != null) 'archiveNote': archiveNote,
      if (mergedIntoPlantId != null) 'mergedIntoPlantId': mergedIntoPlantId,
      if (giftedToUid != null) 'giftedToUid': giftedToUid,
    };
  }
}
