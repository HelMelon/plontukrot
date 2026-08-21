import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/focusable_tap.dart';
import '../../../../models/plant.dart';
import '../../pages/plant_details_page.dart';
import '../common/plant_image.dart';

extension CapitalizeString on String {
  String toTitleCase() {
    if (trim().isEmpty) return '';

    return split(' ').where((word) => word.isNotEmpty).map((word) {
      if (word.length == 1) return word.toUpperCase();
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }
}

class PlantCard extends StatelessWidget {
  final Plant plant;
  final bool isSelected;
  final bool preferSpeciesAsTitle;
  final int propagationBatchCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PlantCard({
    super.key,
    required this.plant,
    this.isSelected = false,
    this.preferSpeciesAsTitle = false,
    this.propagationBatchCount = 0,
    this.onTap,
    this.onLongPress,
  });

  String _dateLabel(DateTime? date, String empty) {
    if (date == null) return empty;
    return DateFormat('d.MM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final radii = context.radii;
    final spacing = context.spacing;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final imageUrl = plant.listImageUrl;
    final fullUrl = plant.imageUrl?.trim();
    final hasImage = imageUrl != null;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final emptyDate = l10n.profileEmDash;
    final fertilizedLabel = _dateLabel(plant.lastFertilizedAt, emptyDate);
    final wateredLabel = _dateLabel(plant.lastWateredAt, emptyDate);
    final batchesLabel = '$propagationBatchCount';

    final speciesBase =
        (plant.species.isEmpty ? l10n.commonUntitled : plant.species)
            .toTitleCase();
    final cultivars = plant.cultivarsDisplay.toTitleCase();
    final species =
        cultivars.isEmpty ? speciesBase : '$speciesBase · $cultivars';
    final nickname = plant.nickname.toTitleCase();
    final hasNickname = nickname.trim().isNotEmpty;
    final showSpeciesOnTop = preferSpeciesAsTitle || !hasNickname;
    final title = showSpeciesOnTop ? species : nickname;
    final subtitle =
        showSpeciesOnTop ? (hasNickname ? nickname : null) : species;
    final semanticsLabel = [
      title,
      if (subtitle != null) subtitle,
      l10n.a11yLastFertilized(fertilizedLabel),
      l10n.a11yLastWatered(wateredLabel),
      l10n.a11yPropagationBatches(propagationBatchCount),
    ].join('. ');

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      child: FocusableTap(
        borderRadius: BorderRadius.circular(radii.md),
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PlantDetailsPage(plantId: plant.id)),
              );
            },
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: colors.modal,
            borderRadius: BorderRadius.circular(radii.md),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.3),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: context.shadows.card,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radii.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: hasImage
                          ? PlantImage(
                              imageUrl: imageUrl,
                              fallbackUrl: fullUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              memCacheWidth: 600,
                              excludeFromSemantics: true,
                              placeholder: const _PlantAssetPlaceholder(),
                              errorWidget: const _PlantAssetPlaceholder(),
                            )
                          : const _PlantAssetPlaceholder(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(spacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: typography.bodyEmphasis.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                    color: colors.primary,
                                    height: 1.2,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  spacing.vXxs,
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.bodySmall.copyWith(
                                      color: colors.textSecondary,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Divider(color: colors.primary, thickness: 1),
                                ExcludeSemantics(
                                  child: isMobile
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _StatChip(
                                              icon: context.icons.fertilizing,
                                              label: fertilizedLabel,
                                            ),
                                            spacing.vXxs,
                                            _StatChip(
                                              icon: context.icons.watering,
                                              label: wateredLabel,
                                            ),
                                            spacing.vXxs,
                                            _StatChip(
                                              hugeIcon: context
                                                  .icons.propagations,
                                              label: batchesLabel,
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: _StatChip(
                                                icon: context.icons.fertilizing,
                                                label: fertilizedLabel,
                                              ),
                                            ),
                                            spacing.hXxs,
                                            Expanded(
                                              child: _StatChip(
                                                icon: context.icons.watering,
                                                label: wateredLabel,
                                              ),
                                            ),
                                            spacing.hXxs,
                                            Expanded(
                                              child: _StatChip(
                                                hugeIcon: context
                                                    .icons.propagations,
                                                label: batchesLabel,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: spacing.xs,
                  right: spacing.xs,
                  child: ExcludeSemantics(
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: colors.primary,
                      child: Icon(
                        context.icons.check,
                        color: colors.onPrimary,
                        size: dimensions.iconMd,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData? icon;
  final List<List<dynamic>>? hugeIcon;
  final String label;

  const _StatChip({
    this.icon,
    this.hugeIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final iconSize = context.dimensions.iconSm;
    final Widget leading;
    if (icon != null) {
      leading = Icon(icon, size: iconSize, color: colors.icon);
    } else {
      leading = HugeIcon(
        icon: hugeIcon!,
        size: iconSize,
        color: colors.icon,
      );
    }

    return Row(
      children: [
        leading,
        SizedBox(width: spacing.xxs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.caption.copyWith(
              color: colors.textSecondary,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlantAssetPlaceholder extends StatelessWidget {
  const _PlantAssetPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimensions = context.dimensions;
    return ExcludeSemantics(
      child: Container(
        color: colors.modal,
        child: Image.asset(
          'assets/images/default-img.webp',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                context.icons.stage,
                color: colors.icon,
                size: dimensions.photoPlaceholder,
              ),
            );
          },
        ),
      ),
    );
  }
}
