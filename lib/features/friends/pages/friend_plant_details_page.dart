import 'package:flutter/material.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/theme_context.dart';
import '../../../models/plant.dart';
import '../../../models/stage_info.dart';
import '../../../services/plant_service.dart';
import '../../plants/widgets/cards/placeholder_widget.dart';
import '../../plants/widgets/common/plant_network_image.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

/// Read-only plant details for a friend's collection (card fields only).
class FriendPlantDetailsPage extends StatelessWidget {
  final String ownerUid;
  final String plantId;
  final String ownerLabel;

  const FriendPlantDetailsPage({
    super.key,
    required this.ownerUid,
    required this.plantId,
    required this.ownerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;
    final radii = context.radii;

    return StreamBuilder<Plant?>(
      stream: PlantService().watchPlantForUser(ownerUid, plantId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(),
            body: Center(
              child: Text(
                l10n.commonError(snapshot.error.toString()),
                style: typography.bodyMedium,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(),
            body: Center(
              child: AccessibleProgressIndicator(color: colors.primary),
            ),
          );
        }
        final plant = snapshot.data;
        if (plant == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(),
            body: Center(
              child: Text(
                l10n.friendsCollectionEmpty,
                style: typography.bodyMedium,
              ),
            ),
          );
        }

        final title =
            plant.nickname.isNotEmpty ? plant.nickname : l10n.plantDefaultTitle;
        final photos = plant.galleryPhotos;
        final stage = stageInfos.firstWhere(
          (e) => e.value == plant.stage,
          orElse: () => stageInfos.first,
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: ListView(
            padding: EdgeInsets.all(spacing.lg),
            children: [
              Text(
                l10n.friendsReadOnly,
                style: typography.captionSmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radii.lg),
                  child: photos.isEmpty
                      ? const PlaceholderWithIcon()
                      : PageView.builder(
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            return PlantNetworkImage(
                              imageUrl: photo.imageUrl,
                              fallbackUrl: photo.imageThumbUrl,
                              fit: BoxFit.cover,
                              placeholder: const PlaceholderWithIcon(),
                              errorWidget: const PlaceholderWithIcon(),
                            );
                          },
                        ),
                ),
              ),
              SizedBox(height: spacing.lg),
              _InfoRow(label: l10n.plantGenus, value: plant.genus),
              _InfoRow(label: l10n.plantSpecies, value: plant.species),
              if (plant.cultivarsDisplay.isNotEmpty)
                _InfoRow(
                  label: l10n.plantCultivar,
                  value: plant.cultivarsDisplay,
                ),
              if ((plant.plantFamily ?? '').isNotEmpty)
                _InfoRow(
                  label: l10n.plantFamilyLabel,
                  value: plant.plantFamily!,
                ),
              if (plant.tradingName.trim().isNotEmpty)
                _InfoRow(
                  label: l10n.plantTradingNameLabel,
                  value: plant.tradingName,
                ),
              _InfoRow(
                label: l10n.plantGrowthStage,
                value: l10n.stageInfoTitle(stage),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: typography.captionSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              value,
              style: typography.bodyMedium,
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
