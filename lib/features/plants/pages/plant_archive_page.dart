import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/theme_context.dart';
import '../../../models/plant.dart';
import '../../../models/plant_archive_reason.dart';
import '../../../models/propagation.dart';
import '../../../models/propagation_parent_label.dart';
import '../../../services/plant_service.dart';
import '../../../services/propagation_service.dart';
import '../widgets/common/plant_image.dart';
import '../widgets/sheets/propagation_details_sheet.dart';
import 'plant_details_page.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/app_bar_chrome_actions.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

/// Unified archive: archived plants and archived propagation batches.
class PlantArchivePage extends StatefulWidget {
  const PlantArchivePage({super.key});

  @override
  State<PlantArchivePage> createState() => _PlantArchivePageState();
}

class _PlantArchivePageState extends State<PlantArchivePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PlantService _plantService;
  late final PropagationService _propagationService;
  late final Stream<List<Plant>> _archivedPlantsStream;
  late final Stream<List<Plant>> _activePlantsStream;
  late final Stream<List<Propagation>> _archivedPropagationsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _plantService = PlantService();
    _propagationService = PropagationService();
    _archivedPlantsStream = _plantService.watchArchivedPlants();
    _activePlantsStream = _plantService.getPlants();
    _archivedPropagationsStream =
        _propagationService.watchArchivedPropagations();
    unawaited(_plantService.purgeExpiredArchived());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Map<String, Plant> _plantsById(List<Plant>? active, List<Plant>? archived) {
    final map = <String, Plant>{};
    if (active != null) {
      for (final plant in active) {
        map[plant.id] = plant;
      }
    }
    if (archived != null) {
      for (final plant in archived) {
        map[plant.id] = plant;
      }
    }
    return map;
  }

  Future<void> _openPropagationDetails(Propagation propagation) async {
    await showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PropagationDetailsSheet(propagation: propagation),
    );
  }

  Widget _plantsTab(AppLocalizations l10n, List<Plant>? archivedPlants) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final typography = context.typography;
    final dimensions = context.dimensions;

    // Data comes from the outer StreamBuilder in build(); this tab must not
    // subscribe to _archivedPlantsStream again (it is single-subscription).
    if (archivedPlants == null) {
      return const Center(child: AccessibleProgressIndicator());
    }

    final plants = archivedPlants;
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
        final fullUrl = plant.imageUrl?.trim();
        final archiveThumbError = ColoredBox(
          color: colors.outline.withValues(alpha: 0.2),
          child: Icon(
            Icons.local_florist_outlined,
            color: colors.icon,
          ),
        );
        final archivedAt = plant.archivedAt;
        final dateLabel = archivedAt == null
            ? null
            : DateFormat('d MMM y').format(archivedAt);
        final note = plant.archiveNote?.trim();
        final title = _titleFor(plant, l10n);
        final reason = _reasonLabel(l10n, plant.archiveReason);
        final semanticsParts = <String>[
          title,
          reason,
          if (dateLabel != null) l10n.plantArchiveDate(dateLabel),
          if (note != null && note.isNotEmpty)
            l10n.plantArchiveNoteLabel(note),
        ];

        return Material(
          color: colors.modal,
          borderRadius: BorderRadius.circular(radii.md),
          child: Semantics(
            button: true,
            label: semanticsParts.join('. '),
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
                    ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radii.sm),
                        child: SizedBox(
                          width: dimensions.avatar,
                          height: dimensions.avatar,
                          child: imageUrl != null
                              ? PlantImage(
                                  imageUrl: imageUrl,
                                  fallbackUrl: fullUrl,
                                  fit: BoxFit.cover,
                                  excludeFromSemantics: true,
                                  errorWidget: archiveThumbError,
                                  placeholder: archiveThumbError,
                                )
                              : ColoredBox(
                                  color: colors.outline
                                      .withValues(alpha: 0.2),
                                  child: Icon(
                                    Icons.local_florist_outlined,
                                    color: colors.icon,
                                  ),
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
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: typography.titleSmall,
                          ),
                          spacing.vXxs,
                          Text(
                            reason,
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
          ),
        );
      },
    );
  }

  Widget _propagationsTab(
    AppLocalizations l10n,
    Map<String, Plant> plantsById,
  ) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final propTheme = context.screens.propagations;
    final dateLocale = Localizations.localeOf(context).toString();

    return StreamBuilder<List<Propagation>>(
      stream: _archivedPropagationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: spacing.allXl,
              child: Text(
                l10n.commonError('${snapshot.error}'),
                textAlign: TextAlign.center,
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: AccessibleProgressIndicator(color: colors.primary),
          );
        }

        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(spacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.propagationEmptyArchive,
                    textAlign: TextAlign.center,
                    style: typography.titleMedium,
                  ),
                  spacing.vSm,
                  Text(
                    l10n.propagationEmptyArchiveHint,
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
          itemCount: items.length,
          separatorBuilder: (_, __) => spacing.vSm,
          itemBuilder: (context, index) {
            final item = items[index];
            final parentLabel = l10n.propagationParentLabel(
              propagationParentLabel(
                propagation: item,
                parent: plantsById[item.parentPlantId],
              ),
            );
            final title =
                '${l10n.stageTitle(item.stage)} · ${l10n.propagationStatusLabel(item.status)}';
            final subtitle =
                '${l10n.propagationStatusLabel(item.status)} · ${item.quantity} ${l10n.propagationMethodPlural(item.method)}';
            final archivedAt = item.archivedAt ?? item.soldAt;
            final dateLabel = archivedAt == null
                ? null
                : DateFormat('d MMM y', dateLocale).format(archivedAt);
            final outcomeLine = [
              if (item.soldQuantity > 0)
                l10n.propagationSoldCount(item.soldQuantity),
              if (item.giftedQuantity > 0)
                l10n.propagationGiftedCount(item.giftedQuantity),
              if (item.tradedQuantity > 0)
                l10n.propagationTradedCount(item.tradedQuantity),
              if (item.lostQuantity > 0)
                l10n.propagationLostCount(item.lostQuantity),
            ].join(' · ');

            final semanticsParts = <String>[
              title,
              parentLabel,
              subtitle,
              if (dateLabel != null) l10n.plantArchiveDate(dateLabel),
              if (outcomeLine.isNotEmpty) outcomeLine,
            ];

            return Material(
              color: colors.modal,
              borderRadius: BorderRadius.circular(propTheme.cardRadius),
              child: Semantics(
                button: true,
                label: semanticsParts.join('. '),
                child: InkWell(
                  borderRadius: BorderRadius.circular(propTheme.cardRadius),
                  onTap: () => _openPropagationDetails(item),
                  child: Padding(
                    padding: propTheme.cardPadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: typography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              spacing.vXxs,
                              Text(
                                parentLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: typography.bodyLarge.copyWith(
                                  color: colors.heading,
                                ),
                              ),
                              spacing.vXxs,
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: typography.bodySmall,
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
                              if (outcomeLine.isNotEmpty) ...[
                                spacing.vXxs,
                                Text(
                                  outcomeLine,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: typography.caption.copyWith(
                                    color: colors.icon,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ExcludeSemantics(
                          child: Icon(
                            Icons.chevron_right,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;

    return StreamBuilder<List<Plant>>(
      stream: _activePlantsStream,
      builder: (context, activeSnapshot) {
        return StreamBuilder<List<Plant>>(
          stream: _archivedPlantsStream,
          builder: (context, archivedSnapshot) {
            final plantsById = _plantsById(
              activeSnapshot.data,
              archivedSnapshot.data,
            );

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: Text(l10n.plantArchiveTitle),
                actions: buildAppBarChromeActions(context),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: colors.primary,
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: typography.bodyMedium,
                  tabs: [
                    Tab(text: l10n.plantArchivePlantsTab),
                    Tab(text: l10n.plantArchivePropagationsTab),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _plantsTab(l10n, archivedSnapshot.data),
                  _propagationsTab(l10n, plantsById),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
