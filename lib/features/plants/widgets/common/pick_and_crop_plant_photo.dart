import 'dart:typed_data';

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
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.plantGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.plantCamera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );
}

/// Gallery/camera → 1:1 crop. Returns bytes or null if cancelled.
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

  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      builder: (_) => PlantImageCropPage(imageBytes: sourceBytes),
    ),
  );
}
