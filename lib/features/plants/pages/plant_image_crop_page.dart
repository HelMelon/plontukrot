import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

/// Full-screen 1:1 crop step before plant photo upload.
///
/// Pops with cropped [Uint8List] on confirm, or `null` on cancel/back.
class PlantImageCropPage extends StatefulWidget {
  final Uint8List imageBytes;

  const PlantImageCropPage({super.key, required this.imageBytes});

  @override
  State<PlantImageCropPage> createState() => _PlantImageCropPageState();
}

class _PlantImageCropPageState extends State<PlantImageCropPage> {
  final _cropController = CropController();
  bool _isCropping = false;

  void _confirm() {
    if (_isCropping) return;
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure(:final cause):
        setState(() => _isCropping = false);
        final l10n = AppLocalizations.of(context);
        final colors = context.colors;
        final typography = context.typography;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.card,
            content: Text(
              l10n.plantCropError(cause.toString()),
              style: typography.bodyLarge,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final dimensions = context.dimensions;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.screen,
      appBar: AppBar(
        backgroundColor: colors.screen,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.icon),
        title: Text(
          l10n.plantCropTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.titleMedium,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: spacing.allMd,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: radii.mdAll,
                  child: Crop(
                    image: widget.imageBytes,
                    controller: _cropController,
                    onCropped: _onCropped,
                    aspectRatio: 1,
                    interactive: true,
                    radius: radii.sm,
                    baseColor: colors.screen,
                    maskColor: colors.screen.withValues(alpha: 0.72),
                    progressIndicator: CircularProgressIndicator(
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              spacing.vMd,
              SizedBox(
                width: double.infinity,
                height: dimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isCropping ? null : _confirm,
                  child: _isCropping
                      ? SizedBox(
                          width: dimensions.iconXl,
                          height: dimensions.iconXl,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      : Text(l10n.plantCropConfirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
