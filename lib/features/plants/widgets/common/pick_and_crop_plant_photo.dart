import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
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

/// Re-encodes picker bytes to baseline JPEG via the Flutter codec.
///
/// Camera/gallery files are often HEIC or another format `crop_your_image`
/// cannot parse, which leaves the crop screen on its spinner. Flutter decodes
/// those files (and applies EXIF orientation). The result is encoded as JPEG
/// with the `image` package so the cropper and the `.jpg` upload match.
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
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (byteData == null) return null;
      final pixels = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final decoded = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: pixels.buffer,
        bytesOffset: pixels.offsetInBytes,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
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

  // The image picker activity can leave the navigator locked for a frame.
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return null;

  return Navigator.of(context, rootNavigator: true).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PlantImageCropPage(imageBytes: normalized),
    ),
  );
}
