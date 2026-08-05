import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/features/plants/widgets/cards/placeholder_widget.dart';

import '../../../../core/theme/theme_context.dart';

class PlantImageCard extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isUploading;
  final double aspectRatio;

  const PlantImageCard({
    super.key,
    required this.imageUrl,
    required this.onTap,
    required this.isUploading,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.radii.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasUrl)
                CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  memCacheWidth: 800,
                  placeholder: (context, url) => const Align(
                    alignment: Alignment.topCenter,
                    child: PlaceholderWithIcon(),
                  ),
                  errorWidget: (context, url, error) => const Align(
                    alignment: Alignment.topCenter,
                    child: PlaceholderWithIcon(),
                  ),
                )
              else
                const Align(
                  alignment: Alignment.topCenter,
                  child: PlaceholderWithIcon(),
                ),
              if (isUploading)
                ColoredBox(
                  color: colors.screen.withValues(alpha: 0.45),
                  child: const Center(child: _PlantImageUploadSpinner()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantImageUploadSpinner extends StatefulWidget {
  const _PlantImageUploadSpinner();

  @override
  State<_PlantImageUploadSpinner> createState() =>
      _PlantImageUploadSpinnerState();
}

class _PlantImageUploadSpinnerState extends State<_PlantImageUploadSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = context.dimensions.photoPlaceholder;

    return RotationTransition(
      turns: _controller,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedLaurelWreath01,
        color: colors.icon,
        size: size,
      ),
    );
  }
}
