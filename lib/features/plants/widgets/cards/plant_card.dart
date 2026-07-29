import 'package:flutter/material.dart';

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
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PlantCard({
    super.key,
    required this.plant,
    this.isSelected = false,
    this.preferSpeciesAsTitle = false,
    this.onTap,
    this.onLongPress,
  });

  static const double _mainFontSize = 15;
  static const double _subFontSize = 13;

  @override
  Widget build(BuildContext context) {
    final imageUrl = plant.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    final species =
        (plant.species.isEmpty ? 'Без названия' : plant.species).toTitleCase();
    final nickname = plant.nickname.toTitleCase();
    final hasNickname = nickname.trim().isNotEmpty;
    final showSpeciesOnTop = preferSpeciesAsTitle || !hasNickname;
    final title = showSpeciesOnTop ? species : nickname;
    final subtitle =
        showSpeciesOnTop ? (hasNickname ? nickname : null) : species;

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
                        ? FadeInImage(
                            placeholder: const AssetImage(
                                'assets/images/plant_placeholder.png'),
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeInCurve: Curves.easeIn,
                            imageErrorBuilder: (context, error, stackTrace) {
                              return const _PlantAssetPlaceholder();
                            },
                            placeholderErrorBuilder:
                                (context, error, stackTrace) {
                              return const _PlantAssetPlaceholder();
                            },
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
