import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../pages/plant_image_crop_page.dart';

Future<ImageSource?> showPlantImageSourceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final sheets = context.components.sheets;
  return showAppModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: sheets.background,
    shape: RoundedRectangleBorder(
      borderRadius: sheets.topBorderRadius,
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(context.icons.gallery),
              title: Text(l10n.plantGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(context.icons.camera),
              title: Text(l10n.plantCamera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );
}

/// Re-encodes picker bytes to PNG via the Flutter codec so `crop_your_image`
/// (package `image`) always receives a format it can parse. Prevents an
/// infinite loading spinner when the camera/gallery returns HEIC/unknown data.
Future<Uint8List?> normalizeImageBytesForCrop(Uint8List bytes) async {
  if (bytes.isEmpty) return null;
  try {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 1280,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } catch (_) {
    return null;
  }
}

void _showCropPrepError(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final colors = context.colors;
  final typography = context.typography;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: colors.card,
      content: Text(
        l10n.plantCropError(l10n.plantCropLoadFailed),
        style: typography.bodyLarge,
      ),
    ),
  );
}

/// Gallery/camera → normalize → 1:1 crop. Returns bytes or null if cancelled.
Future<Uint8List?> pickAndCropPlantPhoto(BuildContext context) async {
  final source = await showPlantImageSourceSheet(context);
  if (source == null || !context.mounted) return null;

  final pickedFile = await ImagePicker().pickImage(
    source: source,
    imageQuality: 80,
    maxWidth: 1280,
    maxHeight: 1280,
  );
  if (pickedFile == null || !context.mounted) return null;

  final sourceBytes = await pickedFile.readAsBytes();
  if (!context.mounted) return null;

  final normalized = await normalizeImageBytesForCrop(sourceBytes);
  if (!context.mounted) return null;
  if (normalized == null || normalized.isEmpty) {
    _showCropPrepError(context);
    return null;
  }

  return Navigator.of(context, rootNavigator: true).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PlantImageCropPage(imageBytes: normalized),
    ),
  );
}
