import 'dart:typed_data';

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
    await AppCrashReporting.instance.log(
      'storage_upload_skipped_no_object_storage',
    );
    throw UnsupportedError(
      'Photo upload is unavailable until object storage is enabled',
    );
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
