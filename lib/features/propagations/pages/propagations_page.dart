import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/theme/theme_context.dart';

import '../../../models/plant.dart';
import '../../../models/propagation.dart';
import '../../../models/propagation_parent_label.dart';
import '../../../models/propagation_year_stats.dart';
import '../../../services/plant_service.dart';
import '../../../services/propagation_service.dart';
import '../../plants/widgets/sheets/propagation_details_sheet.dart';

class PropagationsPage extends StatefulWidget {
  const PropagationsPage({super.key});

  @override
  State<PropagationsPage> createState() => _PropagationsPageState();
}

class _PropagationsPageState extends State<PropagationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PropagationService _service;
  late final PlantService _plantService;
  late final Stream<List<Propagation>> _activeStream;
  late final Stream<List<Propagation>> _archivedStream;
  late final Stream<List<Plant>> _plantsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = PropagationService();
    _plantService = PlantService();
    _activeStream = _service.watchActivePropagations();
    _archivedStream = _service.watchArchivedPropagations();
    _plantsStream = _plantService.getPlants();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openDetails(
    BuildContext context,
    Propagation propagation,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PropagationDetailsSheet(propagation: propagation),
    );
  }

  Map<String, Plant> _plantsById(List<Plant>? plants) {
    if (plants == null) return const {};
    return {for (final plant in plants) plant.id: plant};
  }

  Widget _statsCard(PropagationYearStats stats) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final propTheme = context.screens.propagations;
    final methodParts = stats.byMethod.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final familyParts = stats.byFamily.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: propTheme.cardPadding,
      decoration: BoxDecoration(
        color: colors.modal,
        borderRadius: BorderRadius.circular(propTheme.cardRadius),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.propagationStatsTitle(stats.year),
            style: typography.titleSmall,
          ),
          spacing.vSm,
          Text(
            l10n.propagationStartedLabel(
              stats.startedBatches,
              stats.startedQuantity,
            ),
            style: typography.bodyLarge,
          ),
          spacing.vXxs,
          Text(
            l10n.propagationSoldLabel(
              stats.soldQuantity,
              l10n.unitPiecesShort,
            ),
            style: typography.bodyLarge,
          ),
          if (stats.giftedQuantity > 0) ...[
            spacing.vXxs,
            Text(
              l10n.propagationGiftedLabel(
                stats.giftedQuantity,
                l10n.unitPiecesShort,
              ),
              style: typography.bodyLarge,
            ),
          ],
          if (stats.tradedQuantity > 0) ...[
            spacing.vXxs,
            Text(
              l10n.propagationTradedLabel(
                stats.tradedQuantity,
                l10n.unitPiecesShort,
              ),
              style: typography.bodyLarge,
            ),
          ],
          spacing.vXxs,
          Text(
            l10n.propagationLostLabel(
              stats.lostQuantity,
              l10n.unitPiecesShort,
            ),
            style: typography.bodyLarge,
          ),
          if (methodParts.isNotEmpty) ...[
            spacing.vSm,
            Text(
              l10n.propagationByMethods(
                methodParts
                    .take(4)
                    .map(
                      (e) =>
                          '${l10n.propagationMethodLabel(e.key)} ${e.value}',
                    )
                    .join(' · '),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall,
            ),
          ],
          if (familyParts.isNotEmpty) ...[
            spacing.vXxs,
            Text(
              l10n.propagationByFamilies(
                familyParts
                    .take(3)
                    .map(
                      (e) =>
                          '${e.key.isEmpty ? l10n.homeNoFamily : e.key} ${e.value}',
                    )
                    .join(' · '),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState({
    required Widget icon,
    required String title,
    required String subtitle,
  }) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final propTheme = context.screens.propagations;

    return Center(
      child: Container(
        margin: spacing.allXl,
        padding: propTheme.cardPadding,
        decoration: BoxDecoration(
          color: colors.modal,
          borderRadius: BorderRadius.circular(propTheme.cardRadius),
          border: Border.all(color: colors.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            spacing.vSm,
            Text(
              title,
              style: typography.bodyLarge
                  .copyWith(color: colors.textSecondary),
            ),
            spacing.vXs,
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: typography.bodyMedium
                  .copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propagationTile(
    Propagation item, {
    required bool archived,
    required Map<String, Plant> plantsById,
  }) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final propTheme = context.screens.propagations;
    final dateLocale = Localizations.localeOf(context).toString();
    final parentLabel = l10n.propagationParentLabel(
      propagationParentLabel(
        propagation: item,
        parent: plantsById[item.parentPlantId],
      ),
    );
    final subtitle = archived
        ? '${l10n.propagationStatusLabel(item.status)} · ${item.quantity} ${l10n.propagationMethodPlural(item.method)}'
        : '${l10n.propagationAliveWithMethod(item.quantityAlive, l10n.propagationMethodPlural(item.method))} · ${DateFormat('d MMM y', dateLocale).format(item.startedAt)}';

    final title = archived
        ? '${l10n.stageTitle(item.stage)} · ${l10n.propagationStatusLabel(item.status)}'
        : '${l10n.stageTitle(item.stage)} · ${l10n.daysCount(item.daysSinceStart)}';

    return InkWell(
      onTap: () => _openDetails(context, item),
      borderRadius: BorderRadius.circular(propTheme.cardRadius),
      child: Container(
        padding: propTheme.cardPadding,
        decoration: BoxDecoration(
          color: colors.modal,
          borderRadius: BorderRadius.circular(propTheme.cardRadius),
          border: Border.all(color: colors.outline),
        ),
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
                  if (archived &&
                      (item.soldQuantity > 0 ||
                          item.giftedQuantity > 0 ||
                          item.tradedQuantity > 0 ||
                          item.lostQuantity > 0)) ...[
                    spacing.vXxs,
                    Text(
                      [
                        if (item.soldQuantity > 0)
                          l10n.propagationSoldCount(item.soldQuantity),
                        if (item.giftedQuantity > 0)
                          l10n.propagationGiftedCount(item.giftedQuantity),
                        if (item.tradedQuantity > 0)
                          l10n.propagationTradedCount(item.tradedQuantity),
                        if (item.lostQuantity > 0)
                          l10n.propagationLostCount(item.lostQuantity),
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.caption
                          .copyWith(color: colors.icon),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _propagationList(
    AsyncSnapshot<List<Propagation>> snapshot, {
    required bool archived,
    required Map<String, Plant> plantsById,
  }) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: spacing.allXl,
          child: Text(
            l10n.commonError('${snapshot.error}'),
            textAlign: TextAlign.center,
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    if (!snapshot.hasData) {
      return Center(
        child: CircularProgressIndicator(color: colors.primary),
      );
    }

    final items = snapshot.data!;
    if (items.isEmpty) {
      final iconSize = context.dimensions.avatar + context.spacing.xs;
      return _emptyState(
        icon: archived
            ? Icon(Icons.inventory_2_outlined, size: iconSize, color: colors.icon)
            : HugeIcon(
                icon: HugeIcons.strokeRoundedEcoLab01,
                size: iconSize,
                color: colors.icon,
              ),
        title: archived
            ? l10n.propagationEmptyArchive
            : l10n.propagationEmptyActive,
        subtitle: archived
            ? l10n.propagationEmptyArchiveHint
            : l10n.propagationEmptyActiveHint,
      );
    }

    return ListView.separated(
      padding: spacing.allLg,
      itemCount: items.length,
      separatorBuilder: (_, __) => spacing.vSm,
      itemBuilder: (context, index) {
        return _propagationTile(
          items[index],
          archived: archived,
          plantsById: plantsById,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    return StreamBuilder<List<Plant>>(
      stream: _plantsStream,
      builder: (context, plantsSnapshot) {
        final plantsById = _plantsById(plantsSnapshot.data);

        return StreamBuilder<List<Propagation>>(
          stream: _activeStream,
          builder: (context, activeSnapshot) {
            return StreamBuilder<List<Propagation>>(
              stream: _archivedStream,
              builder: (context, archivedSnapshot) {
                final stats =
                    activeSnapshot.hasData && archivedSnapshot.hasData
                        ? PropagationYearStats.fromList(
                            DateTime.now().year,
                            [
                              ...activeSnapshot.data!,
                              ...archivedSnapshot.data!,
                            ],
                          )
                        : null;

                return Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: colors.screen,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      l10n.propagationTitle,
                      style: typography.titleMedium,
                    ),
                    bottom: TabBar(
                      controller: _tabController,
                      indicatorColor: colors.primary,
                      labelColor: colors.primary,
                      unselectedLabelColor: colors.textSecondary,
                      tabs: [
                        Tab(text: l10n.propagationActiveTab),
                        Tab(text: l10n.propagationArchiveTab),
                      ],
                    ),
                  ),
                  body: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          spacing.lg,
                          spacing.md,
                          spacing.lg,
                          0,
                        ),
                        child: stats == null
                            ? spacing.vXs
                            : _statsCard(stats),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _propagationList(
                              activeSnapshot,
                              archived: false,
                              plantsById: plantsById,
                            ),
                            _propagationList(
                              archivedSnapshot,
                              archived: true,
                              plantsById: plantsById,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
