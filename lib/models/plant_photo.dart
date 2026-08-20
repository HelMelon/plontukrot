import 'model_helpers.dart';

/// One photo in a plant gallery (max [Plant.maxGalleryPhotos]).
class PlantPhoto {
  /// Synthetic id for plants that still only have legacy `imageUrl` fields.
  static const legacyId = 'legacy';

  final String id;
  final String imageUrl;
  final String imageThumbUrl;
  final DateTime addedAt;

  const PlantPhoto({
    required this.id,
    required this.imageUrl,
    required this.imageThumbUrl,
    required this.addedAt,
  });

  bool get isLegacy => id == legacyId;

  factory PlantPhoto.fromMap(Map<String, dynamic> data) {
    final id = readString(data, 'id')?.trim() ?? '';
    final imageUrl = readString(data, 'imageUrl')?.trim() ?? '';
    final thumb = readString(data, 'imageThumbUrl')?.trim() ?? '';
    return PlantPhoto(
      id: id,
      imageUrl: imageUrl,
      imageThumbUrl: thumb.isEmpty ? imageUrl : thumb,
      addedAt: readDate(data, 'addedAt') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'imageThumbUrl': imageThumbUrl,
      'image_url': imageUrl,
      'image_thumb_url': imageThumbUrl,
      'addedAt': isoOrNull(addedAt),
      'added_at': isoOrNull(addedAt),
    };
  }
}
