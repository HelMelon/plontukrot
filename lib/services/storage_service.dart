import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../models/plant_photo.dart';
import 'app_crash_reporting.dart';

class PlantImageUploadResult {
  final String photoId;
  final String imageUrl;
  final String imageThumbUrl;

  const PlantImageUploadResult({
    required this.photoId,
    required this.imageUrl,
    required this.imageThumbUrl,
  });
}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  static const int thumbMaxPx = 400;
  static const int thumbQuality = 70;

  Reference _legacyPlantImageRef(String plantId) {
    return _storage.ref().child('plants').child(uid).child('$plantId.jpg');
  }

  Reference _legacyPlantThumbRef(String plantId) {
    return _storage.ref().child('plants').child(uid).child('${plantId}_thumb.jpg');
  }

  Reference _plantPhotoRef(String plantId, String photoId) {
    return _storage
        .ref()
        .child('plants')
        .child(uid)
        .child(plantId)
        .child('$photoId.jpg');
  }

  Reference _plantPhotoThumbRef(String plantId, String photoId) {
    return _storage
        .ref()
        .child('plants')
        .child(uid)
        .child(plantId)
        .child('${photoId}_thumb.jpg');
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

  /// Upload a gallery photo under `plants/{uid}/{plantId}/{photoId}.jpg`.
  Future<PlantImageUploadResult> uploadPlantPhoto({
    required Uint8List imageBytes,
    required String plantId,
    String? photoId,
  }) async {
    try {
      final id = (photoId != null && photoId.trim().isNotEmpty)
          ? photoId.trim()
          : DateTime.now().microsecondsSinceEpoch.toString();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final fullRef = _plantPhotoRef(plantId, id);
      final thumbRef = _plantPhotoThumbRef(plantId, id);
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
        photoId: id,
        imageUrl: urls[0],
        imageThumbUrl: urls[1],
      );
    } catch (error, stack) {
      await AppCrashReporting.instance.recordError(
        error,
        stack,
        reason: 'storage_upload_plant_photo_failed',
      );
      rethrow;
    }
  }

  /// Legacy single-file upload kept for older callers.
  Future<PlantImageUploadResult> uploadPlantImages({
    required Uint8List imageBytes,
    required String plantId,
  }) async {
    try {
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final fullRef = _legacyPlantImageRef(plantId);
      final thumbRef = _legacyPlantThumbRef(plantId);
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
        photoId: PlantPhoto.legacyId,
        imageUrl: urls[0],
        imageThumbUrl: urls[1],
      );
    } catch (error, stack) {
      await AppCrashReporting.instance.recordError(
        error,
        stack,
        reason: 'storage_upload_plant_images_failed',
      );
      rethrow;
    }
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

  Future<void> deletePlantPhoto(String plantId, String photoId) async {
    if (photoId == PlantPhoto.legacyId) {
      await deletePlantImage(plantId);
      return;
    }
    await Future.wait([
      _deleteQuietly(_plantPhotoRef(plantId, photoId)),
      _deleteQuietly(_plantPhotoThumbRef(plantId, photoId)),
    ]);
  }

  Future<void> deletePlantImage(String plantId) async {
    await Future.wait([
      _deleteQuietly(_legacyPlantImageRef(plantId)),
      _deleteQuietly(_legacyPlantThumbRef(plantId)),
    ]);
  }

  /// Deletes gallery photos and legacy cover files for a plant.
  Future<void> deleteAllPlantImages({
    required String plantId,
    required Iterable<String> photoIds,
  }) async {
    final uniqueIds = photoIds.toSet();
    await Future.wait([
      for (final id in uniqueIds) deletePlantPhoto(plantId, id),
      deletePlantImage(plantId),
    ]);
  }

  Future<void> _deleteQuietly(Reference ref) async {
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  /// Deletes all objects under `plants/{uid}/` (legacy + gallery).
  Future<void> deleteAllUserPlantImages() async {
    final root = _storage.ref().child('plants').child(uid);
    await _deleteRefRecursive(root);
  }

  Future<void> _deleteRefRecursive(Reference ref) async {
    final listed = await ref.listAll();
    await Future.wait([
      for (final item in listed.items) _deleteQuietly(item),
      for (final prefix in listed.prefixes) _deleteRefRecursive(prefix),
    ]);
  }
}
