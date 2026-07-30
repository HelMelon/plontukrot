import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PlantImageUploadResult {
  final String imageUrl;
  final String imageThumbUrl;

  const PlantImageUploadResult({
    required this.imageUrl,
    required this.imageThumbUrl,
  });
}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  static const int thumbMaxPx = 400;
  static const int thumbQuality = 70;

  Reference _plantImageRef(String plantId) {
    return _storage.ref().child('plants').child(uid).child('$plantId.jpg');
  }

  Reference _plantThumbRef(String plantId) {
    return _storage.ref().child('plants').child(uid).child('${plantId}_thumb.jpg');
  }

  Future<Uint8List> _buildThumbBytes(Uint8List imageBytes) async {
    final compressed = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: thumbMaxPx,
      minHeight: thumbMaxPx,
      quality: thumbQuality,
      format: CompressFormat.jpeg,
    );
    if (compressed.isEmpty) return imageBytes;
    return Uint8List.fromList(compressed);
  }

  Future<PlantImageUploadResult> uploadPlantImages({
    required Uint8List imageBytes,
    required String plantId,
  }) async {
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final fullRef = _plantImageRef(plantId);
    final thumbRef = _plantThumbRef(plantId);
    final thumbBytes = await _buildThumbBytes(imageBytes);

    await Future.wait([
      fullRef.putData(imageBytes, metadata),
      thumbRef.putData(thumbBytes, metadata),
    ]);

    final urls = await Future.wait([
      fullRef.getDownloadURL(),
      thumbRef.getDownloadURL(),
    ]);

    return PlantImageUploadResult(
      imageUrl: urls[0],
      imageThumbUrl: urls[1],
    );
  }

  /// Legacy single-upload path kept for callers; also writes a thumb.
  Future<String> uploadPlantImageWeb({
    required Uint8List imageBytes,
    required String plantId,
  }) async {
    final result = await uploadPlantImages(
      imageBytes: imageBytes,
      plantId: plantId,
    );
    return result.imageUrl;
  }

  Future<void> deletePlantImage(String plantId) async {
    await Future.wait([
      _deleteQuietly(_plantImageRef(plantId)),
      _deleteQuietly(_plantThumbRef(plantId)),
    ]);
  }

  Future<void> _deleteQuietly(Reference ref) async {
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
