import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/growth_event.dart';
import '../../../../models/plant.dart';
import '../../../../models/plant_archive_reason.dart';
import '../../../../models/stage_info.dart';
import '../../../../models/variegation.dart';
import '../../pages/plant_genus_details_page.dart';
import '../growth/plant_growth_stats_section.dart';
import '../notes/plant_notes_section.dart';
import '../propagations/plant_propagations_section.dart';
import '../sheets/add_note_sheet.dart';
import '../sheets/fertilizing_history_sheet.dart';
import '../sheets/repotting_history_sheet.dart';
import '../sheets/watering_history_sheet.dart';
import 'info_card.dart';

class PlantInfoCard extends StatefulWidget {
  final Plant plant;
  final String plantId;
  final GlobalKey? growthStatsKey;
  final List<MonthlyLeafStat> monthlyLeafStats;

  const PlantInfoCard({
    super.key,
    required this.plant,
    required this.plantId,
    this.growthStatsKey,
    this.monthlyLeafStats = const [],
  });

  @override
  State<PlantInfoCard> createState() => _PlantInfoCardState();
}

class _PlantInfoCardState extends State<PlantInfoCard> {
  final GlobalKey _botanicalDetailsKey = GlobalKey();

  double get _sectionGap => context.spacing.md;

  static Widget _icon(BuildContext context, String asset) {
    final size = context.dimensions.avatar - 8;
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  TextStyle get _botanicalStyle => context.typography.titleMedium.copyWith(
        fontWeight: FontWeight.normal,
        color: context.colors.heading,
      );

  Widget _section({Key? key, required Widget child}) {
    final cards = context.components.cards;
    return Container(
      key: key,
      width: double.infinity,
      padding: cards.padding,
      decoration: cards.decoration.copyWith(
        color: context.colors.modal,
      ),
      child: child,
    );
  }

  Widget? _botanicalLine(String label, String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.xs),
      child: Text(
        '$label: $trimmed',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: _botanicalStyle,
      ),
    );
  }

  Future<void> _scrollToBotanicalDetails() async {
    final targetContext = _botanicalDetailsKey.currentContext;
    if (targetContext == null) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final typography = context.typography;
    final plant = widget.plant;
    final plantId = widget.plantId;

    final stage = stageInfos.firstWhere(
      (e) => e.value == plant.stage,
      orElse: () => stageInfos.first,
    );

    final speciesTrimmed = plant.species.trim();
    final cultivarsDisplay = plant.cultivarsDisplay;
    final tradingNameTrimmed = plant.tradingName.trim();
    final plantFamilyLine =
        _botanicalLine(l10n.plantFamilyLabel, plant.plantFamily);
    final tradingNameLine =
        _botanicalLine(l10n.plantTradingNameLabel, tradingNameTrimmed);
    final variegation = plant.isGroup
        ? Variegation.none
        : plant.variegation;
    final variegationLabel = l10n.variegationLabelOf(variegation);
    final dateLocale = Localizations.localeOf(context).toString();
    final createdAtLabel = plant.createdAt == null
        ? null
        : DateFormat('d MMM y', dateLocale).format(plant.createdAt!);
    final dateAddedLine =
        _botanicalLine(l10n.plantDateAddedLabel, createdAtLabel);
    final hasBotanicalDetails = plantFamilyLine != null ||
        plant.genus.trim().isNotEmpty ||
        tradingNameLine != null ||
        variegation != Variegation.none ||
        dateAddedLine != null;

    String careDateLabel(DateTime? date) {
      if (date == null) return l10n.commonNoData;
      return DateFormat('d MMM y').format(date);
    }

    void openWateringHistory() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        builder: (_) => WateringHistorySheet(plantId: plantId),
      );
    }

    void openFertilizingHistory() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        builder: (_) => FertilizingHistorySheet(plantId: plantId),
      );
    }

    void openRepottingHistory() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        builder: (_) => RepottingHistorySheet(plantId: plantId),
      );
    }

    final mainInfo = _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plant.nickname.trim().isNotEmpty)
            Text(
              plant.nickname,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: typography.titlePage,
            ),
          if (plant.nickname.trim().isNotEmpty) spacing.vXs,
          if (plant.isArchived) ...[
            Text(
              switch (plant.archiveReason) {
                PlantArchiveReason.merged => l10n.plantArchiveReasonMerged,
                PlantArchiveReason.died => l10n.plantArchiveReasonDied,
                PlantArchiveReason.sold => l10n.plantArchiveReasonSold,
                null => l10n.homeArchive,
              },
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _botanicalStyle.copyWith(color: colors.textSecondary),
            ),
            if ((plant.archiveNote ?? '').trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: spacing.xxs, bottom: spacing.xs),
                child: Text(
                  l10n.plantArchiveNoteLabel(plant.archiveNote!.trim()),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: _botanicalStyle,
                ),
              )
            else
              spacing.vXs,
          ],
          if (speciesTrimmed.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l10n.plantSpeciesLabel(speciesTrimmed),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _botanicalStyle,
                    ),
                  ),
                  if (variegation.showIconNearSpecies) ...[
                    spacing.hXs,
                    Tooltip(
                      message: variegationLabel,
                      child: Icon(
                        variegation.icon,
                        color: variegation.iconColor,
                        size: spacing.xl,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (cultivarsDisplay.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.xs),
              child: Text(
                plant.isGroup
                    ? l10n.plantCultivarsLabel(cultivarsDisplay)
                    : l10n.plantCultivarLabel(cultivarsDisplay),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: _botanicalStyle,
              ),
            ),
          if (plant.isGroup && plant.members.isNotEmpty) ...[
            for (final member in plant.members)
              if (member.variegation != Variegation.none)
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.xxs),
                  child: Row(
                    children: [
                      Icon(
                        member.variegation.icon,
                        color: member.variegation.iconColor,
                        size: spacing.xl,
                      ),
                      spacing.hXs,
                      Expanded(
                        child: Text(
                          [
                            if ((member.cultivar ?? '').trim().isNotEmpty)
                              member.cultivar!.trim(),
                            l10n.variegationLabelOf(member.variegation),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _botanicalStyle,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
          if (stage.value != 0)
            Text(
              l10n.plantStageLabel(l10n.stageInfoTitle(stage)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _botanicalStyle,
            ),
          if (hasBotanicalDetails) ...[
            spacing.vXs,
            InkWell(
              onTap: _scrollToBotanicalDetails,
              borderRadius: BorderRadius.circular(radii.sm),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.xxs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.plantBotanicalData,
                      style: typography.bodyEmphasis.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    spacing.hXxs,
                    Icon(
                      Icons.arrow_downward,
                      size: context.dimensions.iconSm,
                      color: colors.icon,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final careHistory = _section(
      child: Column(
        children: [
          InfoCard(
            icon: _icon(context, 'assets/icons/watering.png'),
            title: l10n.watering,
            value: careDateLabel(plant.lastWateredAt),
            onTap: openWateringHistory,
          ),
          spacing.vXs,
          InfoCard(
            icon: _icon(context, 'assets/icons/fertilize.png'),
            title: l10n.fertilizing,
            value: careDateLabel(plant.lastFertilizedAt),
            onTap: openFertilizingHistory,
          ),
          spacing.vXs,
          InfoCard(
            icon: _icon(context, 'assets/icons/potting.png'),
            title: l10n.repotting,
            value: careDateLabel(plant.lastRepottedAt),
            onTap: openRepottingHistory,
          ),
        ],
      ),
    );

    final propagation = _section(
      child: PlantPropagationsSection(
        plantId: plantId,
        plantName:
            plant.species.isNotEmpty ? plant.species : l10n.commonUntitled,
        plantFamily: plant.plantFamily ?? '',
      ),
    );

    final journal = _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.plantJournal,
                  style: typography.sectionTitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    enableDrag: true,
                    builder: (_) => AddNoteSheet(plantId: plantId),
                  );
                },
                icon: Icon(Icons.add, size: context.dimensions.iconMd),
                label: Text(l10n.commonAdd),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                ),
              ),
            ],
          ),
          spacing.vXs,
          PlantNotesSection(plantId: plantId),
        ],
      ),
    );

    final botanical = !hasBotanicalDetails
        ? null
        : _section(
            key: _botanicalDetailsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.plantBotanicalData,
                  style: typography.sectionTitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                spacing.vSm,
                if (plantFamilyLine != null) plantFamilyLine,
                if (plant.genus.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.plantGenusPrefix, style: _botanicalStyle),
                        Flexible(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlantGenusDetailsPage(
                                    genus: plant.genus.trim(),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(radii.sm),
                            child: Text(
                              plant.genus.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _botanicalStyle.copyWith(
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    colors.heading.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.xs),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.plantVariegationLabel(variegationLabel),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _botanicalStyle,
                        ),
                      ),
                      if (variegation != Variegation.none) ...[
                        spacing.hXs,
                        Icon(
                          variegation.icon,
                          color: variegation.iconColor,
                          size: context.dimensions.iconXl,
                        ),
                      ],
                    ],
                  ),
                ),
                if (tradingNameLine != null) tradingNameLine,
                if (dateAddedLine != null) dateAddedLine,
              ],
            ),
          );

    final leafStats = _section(
      key: widget.growthStatsKey,
      child: PlantGrowthStatsSection(
        monthlyStats: widget.monthlyLeafStats,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mainInfo,
        SizedBox(height: _sectionGap),
        careHistory,
        SizedBox(height: _sectionGap),
        propagation,
        SizedBox(height: _sectionGap),
        journal,
        if (botanical != null) ...[
          SizedBox(height: _sectionGap),
          botanical,
        ],
        SizedBox(height: _sectionGap),
        leafStats,
      ],
    );
  }
}
