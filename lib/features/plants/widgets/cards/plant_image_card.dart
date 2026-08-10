import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/features/plants/widgets/cards/placeholder_widget.dart';
import 'package:plontukrot/features/plants/widgets/common/plant_network_image.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/plant_photo.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/focusable_tap.dart';

class PlantImageCard extends StatefulWidget {
  final List<PlantPhoto> photos;
  final VoidCallback onAdd;
  final ValueChanged<PlantPhoto>? onDelete;
  final bool isUploading;
  final double aspectRatio;

  const PlantImageCard({
    super.key,
    required this.photos,
    required this.onAdd,
    this.onDelete,
    required this.isUploading,
    this.aspectRatio = 1.0,
  });

  @override
  State<PlantImageCard> createState() => _PlantImageCardState();
}

class _PlantImageCardState extends State<PlantImageCard> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = 0;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didUpdateWidget(covariant PlantImageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photos.length != oldWidget.photos.length) {
      // New upload lands at index 0 (newest-first); reset the pager.
      if (_index != 0 || widget.photos.length > oldWidget.photos.length) {
        _index = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pageController.hasClients) return;
          _pageController.jumpToPage(0);
        });
      }
    } else if (widget.photos.isNotEmpty && _index >= widget.photos.length) {
      _index = widget.photos.length - 1;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final typography = context.typography;
    final gallery = context.screens.plantDetails;
    final l10n = AppLocalizations.of(context);
    final photos = widget.photos;
    final hasPhotos = photos.isNotEmpty;
    final current = hasPhotos ? photos[_index.clamp(0, photos.length - 1)] : null;
    final dateLocale = Localizations.localeOf(context).toString();
    final dateLabel = current == null || current.isLegacy
        ? null
        : DateFormat('d MMM y', dateLocale).format(current.addedAt);

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radii.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!hasPhotos)
              Semantics(
                button: true,
                enabled: !widget.isUploading,
                label: l10n.plantPhotoAdd,
                child: FocusableTap(
                  enabled: !widget.isUploading,
                  onTap: widget.isUploading ? null : widget.onAdd,
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: PlaceholderWithIcon(),
                  ),
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final photo = photos[i];
                  final photoDate = photo.isLegacy
                      ? null
                      : DateFormat('d MMM y', dateLocale)
                          .format(photo.addedAt);
                  return PlantNetworkImage(
                    imageUrl: photo.imageUrl,
                    fallbackUrl: photo.imageThumbUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    memCacheWidth: 800,
                    semanticLabel: [
                      l10n.a11yGalleryPhoto(i + 1, photos.length),
                      if (photoDate != null) photoDate,
                    ].join('. '),
                    placeholder: const Align(
                      alignment: Alignment.topCenter,
                      child: PlaceholderWithIcon(),
                    ),
                    errorWidget: const Align(
                      alignment: Alignment.topCenter,
                      child: PlaceholderWithIcon(),
                    ),
                  );
                },
              ),
            if (hasPhotos && dateLabel != null)
              Positioned(
                left: spacing.md,
                right: spacing.md,
                bottom: spacing.md,
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (photos.length > 1) ...[
                        ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < photos.length; i++) ...[
                                if (i > 0)
                                  SizedBox(width: gallery.galleryDotGap),
                                Container(
                                  width: gallery.galleryDotSize,
                                  height: gallery.galleryDotSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _index
                                        ? gallery.galleryDotActive
                                        : gallery.galleryDotInactive,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                      ],
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: gallery.galleryDateScrim,
                          borderRadius: BorderRadius.circular(radii.sm),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.sm,
                            vertical: spacing.xs,
                          ),
                          child: Text(
                            dateLabel,
                            style: typography.bodySmall.copyWith(
                              color: gallery.galleryDateText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (hasPhotos && !widget.isUploading)
              Positioned(
                top: spacing.sm,
                right: spacing.sm,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GalleryActionButton(
                      tooltip: l10n.plantPhotoAdd,
                      background: gallery.galleryActionBackground,
                      iconColor: colors.onPrimary,
                      icon: HugeIcons.strokeRoundedAdd01,
                      onTap: widget.onAdd,
                    ),
                    if (widget.onDelete != null && current != null) ...[
                      SizedBox(width: spacing.xs),
                      _GalleryActionButton(
                        tooltip: l10n.plantPhotoDeleteTitle,
                        background: gallery.galleryActionBackground,
                        iconColor: colors.onPrimary,
                        icon: HugeIcons.strokeRoundedDelete02,
                        onTap: () => widget.onDelete!(current),
                      ),
                    ],
                  ],
                ),
              ),
            if (widget.isUploading)
              ColoredBox(
                color: colors.screen.withValues(alpha: 0.45),
                child: const Center(child: _PlantImageUploadSpinner()),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryActionButton extends StatelessWidget {
  final String tooltip;
  final Color background;
  final Color iconColor;
  final List<List<dynamic>> icon;
  final VoidCallback onTap;

  const _GalleryActionButton({
    required this.tooltip,
    required this.background,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final size = context.dimensions.iconLg;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(spacing.sm),
              child: ExcludeSemantics(
                child: HugeIcon(icon: icon, color: iconColor, size: size),
              ),
            ),
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
