import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/plant.dart';
import '../../pages/plant_details_page.dart';

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

  static const double _mainFontSize = 15;
  static const double _subFontSize = 13;

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
    final imageUrl = plant.listImageUrl;
    final hasImage = imageUrl != null;

    final speciesBase =
        (plant.species.isEmpty ? 'Без названия' : plant.species).toTitleCase();
    final cultivar = (plant.cultivar ?? '').trim().toTitleCase();
    final species = cultivar.isEmpty ? speciesBase : '$speciesBase · $cultivar';
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
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.goldAccent
                : AppColors.greenDeep.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark1.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            memCacheWidth: 600,
                            fadeInDuration: const Duration(milliseconds: 300),
                            placeholder: (context, url) =>
                                const _PlantAssetPlaceholder(),
                            errorWidget: (context, url, error) =>
                                const _PlantAssetPlaceholder(),
                          )
                        : const _PlantAssetPlaceholder(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: _mainFontSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                color: AppColors.goldAccent,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: _subFontSize,
                                fontWeight: FontWeight.normal,
                                color: AppColors.warmGray,
                                height: 1.2,
                              ),
                            ),
                          ],
                          if (fertilizerName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              fertilizerName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: _subFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppColors.accentLight,
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
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.goldAccent,
                  child: Icon(Icons.check, color: AppColors.dark1, size: 18),
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
    return Container(
      color: AppColors.backgroundSecondary,
      child: Image.asset(
        'assets/images/default-img.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child:
                Icon(Icons.eco_rounded, color: AppColors.goldAccent, size: 40),
          );
        },
      ),
    );
  }
}
