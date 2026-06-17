import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:plontukrot/features/plants/widgets/cards/placeholder_widget.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  placeholder: (context, url) => const PlaceholderWithIcon(),
                  errorWidget: (context, url, error) =>
                      const PlaceholderWithIcon(),
                )
              else
                const PlaceholderWithIcon(),

              if (isUploading)
                Container(
                  color: Colors.black45,
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
