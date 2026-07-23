import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
  final QueryDocumentSnapshot plant;

  const PlantCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final data = plant.data() as Map<String, dynamic>;

    final imageUrl = data['imageUrl'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    final name = (data['name'] as String? ?? 'Unnamed Plant').toTitleCase();
    final nickname = (data['nickname'] as String? ?? '').toTitleCase();
    final hasNickname = nickname.trim().isNotEmpty;

    final double screenWidth = MediaQuery.of(context).size.width;

    final double mainFontSize = (screenWidth * 0.035).clamp(14.0, 20.0);

    final double subFontSize = (screenWidth * 0.03).clamp(12.0, 16.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlantDetailsPage(plant: plant)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.greenDeep.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark1.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                        placeholderErrorBuilder: (context, error, stackTrace) {
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
                      Text(
                        hasNickname ? nickname : name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: mainFontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          color: AppColors.goldAccent,
                          height: 1.2,
                        ),
                      ),
                      if (hasNickname) ...[
                        const SizedBox(height: 4),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subFontSize,
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
