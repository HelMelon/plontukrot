import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/theme_context.dart';
import '../../../models/plant.dart';
import '../../../models/plant_archive_reason.dart';
import '../../../services/plant_service.dart';
import 'plant_details_page.dart';

class PlantArchivePage extends StatefulWidget {
  const PlantArchivePage({super.key});

  @override
  State<PlantArchivePage> createState() => _PlantArchivePageState();
}

class _PlantArchivePageState extends State<PlantArchivePage> {
  late final PlantService _plantService;
  late final Stream<List<Plant>> _archiveStream;

  @override
  void initState() {
    super.initState();
    _plantService = PlantService();
    _archiveStream = _plantService.watchArchivedPlants();
    unawaited(_plantService.purgeExpiredArchived());
  }

  String _reasonLabel(AppLocalizations l10n, PlantArchiveReason? reason) {
    return switch (reason) {
      PlantArchiveReason.merged => l10n.plantArchiveReasonMerged,
      PlantArchiveReason.died => l10n.plantArchiveReasonDied,
      PlantArchiveReason.sold => l10n.plantArchiveReasonSold,
      PlantArchiveReason.gifted => l10n.plantArchiveReasonGifted,
      null => l10n.homeArchive,
    };
  }

  String _titleFor(Plant plant, AppLocalizations l10n) {
    final nickname = plant.nickname.trim();
    if (nickname.isNotEmpty) return nickname;
    final species = plant.species.trim();
    final cultivars = plant.cultivarsDisplay;
    if (species.isEmpty && cultivars.isEmpty) return l10n.commonUntitled;
    if (cultivars.isEmpty) return species;
    return '$species · $cultivars';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final typography = context.typography;
    final dimensions = context.dimensions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: colors.screen,
        title: Text(l10n.plantArchiveTitle),
      ),
      body: StreamBuilder<List<Plant>>(
        stream: _archiveStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final plants = snapshot.data ?? const <Plant>[];
          if (plants.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(spacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.plantArchiveEmpty,
                      textAlign: TextAlign.center,
                      style: typography.titleMedium,
                    ),
                    spacing.vSm,
                    Text(
                      l10n.plantArchiveEmptyHint,
                      textAlign: TextAlign.center,
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(spacing.md),
            itemCount: plants.length,
            separatorBuilder: (_, __) => spacing.vSm,
            itemBuilder: (context, index) {
              final plant = plants[index];
              final imageUrl = plant.listImageUrl;
              final archivedAt = plant.archivedAt;
              final dateLabel = archivedAt == null
                  ? null
                  : DateFormat('d MMM y').format(archivedAt);
              final note = plant.archiveNote?.trim();

              return Material(
                color: colors.modal,
                borderRadius: BorderRadius.circular(radii.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(radii.md),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlantDetailsPage(plantId: plant.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(spacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(radii.sm),
                          child: SizedBox(
                            width: dimensions.avatar,
                            height: dimensions.avatar,
                            child: imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => ColoredBox(
                                      color: colors.outline
                                          .withValues(alpha: 0.2),
                                      child: Icon(
                                        Icons.local_florist_outlined,
                                        color: colors.icon,
                                      ),
                                    ),
                                  )
                                : ColoredBox(
                                    color:
                                        colors.outline.withValues(alpha: 0.2),
                                    child: Icon(
                                      Icons.local_florist_outlined,
                                      color: colors.icon,
                                    ),
                                  ),
                          ),
                        ),
                        spacing.hMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _titleFor(plant, l10n),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: typography.titleSmall,
                              ),
                              spacing.vXxs,
                              Text(
                                _reasonLabel(l10n, plant.archiveReason),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              if (dateLabel != null) ...[
                                spacing.vXxs,
                                Text(
                                  l10n.plantArchiveDate(dateLabel),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: typography.bodySmall.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                              if (note != null && note.isNotEmpty) ...[
                                spacing.vXxs,
                                Text(
                                  l10n.plantArchiveNoteLabel(note),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: typography.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
