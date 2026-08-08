import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/plant.dart';
import '../../pages/plant_details_page.dart';
import '../common/plant_network_image.dart';

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
  final bool showLastFertilizer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PlantCard({
    super.key,
    required this.plant,
    this.isSelected = false,
    this.preferSpeciesAsTitle = false,
    this.showLastFertilizer = false,
    this.onTap,
    this.onLongPress,
  });

  String? get _fertilizerLabel {
    if (!showLastFertilizer) return null;
    final name = plant.lastFertilizerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final at = plant.lastFertilizedAt;
    if (at == null) return null;
    return DateFormat('d MMM y').format(at);
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
    final fertilizerName = _fertilizerLabel;

    return GestureDetector(
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
                        ? PlantNetworkImage(
                            imageUrl: imageUrl,
                            fallbackUrl: fullUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            memCacheWidth: 600,
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
                        children: [
                          Flexible(
                            child: Text(
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
                          ),
                          if (subtitle != null) ...[
                            spacing.vXxs,
                            Text(
                              subtitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: typography.bodySmall.copyWith(
                                color: colors.textSecondary,
                                height: 1.2,
                              ),
                            ),
                          ],
                          if (fertilizerName != null) ...[
                            spacing.vXxs,
                            Text(
                              fertilizerName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: typography.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colors.icon,
                                height: 1.2,
                              ),
                            ),
                          ],
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
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.primary,
                  child: Icon(
                    Icons.check,
                    color: colors.onPrimary,
                    size: dimensions.iconMd,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlantAssetPlaceholder extends StatelessWidget {
  const _PlantAssetPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimensions = context.dimensions;
    return Container(
      color: colors.modal,
      child: Image.asset(
        'assets/images/default-img.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.eco_rounded,
              color: colors.icon,
              size: dimensions.photoPlaceholder,
            ),
          );
        },
      ),
    );
  }
}
