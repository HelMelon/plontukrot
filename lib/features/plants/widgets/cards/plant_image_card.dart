import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PlantImageCard extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final bool isUploading;

  const PlantImageCard({
    required this.imageUrl,
    required this.onTap,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,

      child: AspectRatio(
        aspectRatio: 4 / 5,

        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: AppColors.backgroundSecondary,
            border: Border.all(color: AppColors.greenDeep),
          ),

          clipBehavior: Clip.antiAlias,

          child: imageUrl.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.add_a_photo,
                    size: 50,
                    color: AppColors.accentLight,
                  ),
                )
              : Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
