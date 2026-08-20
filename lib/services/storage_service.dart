import 'package:flutter/foundation.dart';

import '../models/model_helpers.dart';
import '../models/plant_photo.dart';
import 'api_client.dart';
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

/// Photo files are stored as URLs in Postgres. Binary upload is not available
/// until Object Storage is wired on the backend (ADR-033 Phase 4).
class StorageService {
  final ApiClient _api = ApiClient.instance;

  static const int thumbMaxPx = 400;
  static const int thumbQuality = 70;

  static const financeReceiptsFolder = '_receipts';

  Future<PlantImageUploadResult> uploadPlantPhoto({
    required Uint8List imageBytes,
    required String plantId,
    String? photoId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[StorageService] Starting photo upload for plantId: $plantId (${imageBytes.length} bytes)',
        );
      }
      final rawResponse = await _api.postMultipart(
        '/plants/$plantId/photos/upload',
        fileField: 'file',
        filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fileBytes: imageBytes,
      );
      if (kDebugMode) {
        debugPrint('[StorageService] Raw upload response: $rawResponse');
      }
      final json = jsonMap(rawResponse);
      final id = readString(json, 'id') ?? '';
      final imageUrl = readString(json, 'imageUrl')?.trim() ??
          readString(json, 'image_url')?.trim() ??
          '';
      final thumb = readString(json, 'imageThumbUrl')?.trim() ??
          readString(json, 'image_thumb_url')?.trim() ??
          imageUrl;
      if (imageUrl.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[StorageService] Empty imageUrl! Raw response: $rawResponse, parsed json: $json',
          );
        }
        throw StateError(
          'Upload succeeded but no imageUrl returned (response: $rawResponse)',
        );
      }
      return PlantImageUploadResult(
        photoId: id.isEmpty ? photoId ?? '' : id,
        imageUrl: imageUrl,
        imageThumbUrl: thumb.isEmpty ? imageUrl : thumb,
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[StorageService] uploadPlantPhoto failed: $error\n$stack');
      }
      await AppCrashReporting.instance.recordError(
        error,
        stack,
        reason: 'storage_upload_plant_photo_failed',
      );
      rethrow;
    }
  }

  Future<PlantImageUploadResult> uploadPlantImages({
    required Uint8List imageBytes,
    required String plantId,
  }) {
    return uploadPlantPhoto(imageBytes: imageBytes, plantId: plantId);
  }

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
    if (photoId == PlantPhoto.legacyId) return;
    try {
      await _api.delete('/plants/$plantId/photos/$photoId');
    } catch (error, stack) {
      await AppCrashReporting.instance.recordError(
        error,
        stack,
        reason: 'storage_delete_plant_photo_failed',
      );
    }
  }

  Future<void> deletePlantImage(String plantId) async {}

  Future<void> deleteAllPlantImages({
    required String plantId,
    required Iterable<String> photoIds,
  }) async {
    for (final id in photoIds.toSet()) {
      await deletePlantPhoto(plantId, id);
    }
  }

  Future<({String receiptId, String url})> uploadFinanceReceipt({
    required Uint8List imageBytes,
    required String entryId,
    String? receiptId,
  }) async {
    throw UnsupportedError(
      'Receipt upload is unavailable until object storage is enabled',
    );
  }

  Future<void> deleteFinanceReceipt({
    required String entryId,
    required String receiptId,
  }) async {}

  Future<void> deleteFinanceReceipts({
    required String entryId,
    required Iterable<String> receiptIds,
  }) async {}

  Future<void> deleteAllUserPlantImages() async {}
}
