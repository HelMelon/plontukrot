import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

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
    final id = (data['id'] as String?)?.trim() ?? '';
    final imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
    final thumb = (data['imageThumbUrl'] as String?)?.trim() ?? '';
    return PlantPhoto(
      id: id,
      imageUrl: imageUrl,
      imageThumbUrl: thumb.isEmpty ? imageUrl : thumb,
      addedAt: readTimestamp(data['addedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'imageThumbUrl': imageThumbUrl,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}
