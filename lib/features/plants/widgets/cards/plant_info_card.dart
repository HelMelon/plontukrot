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
import '../../../../services/note_service.dart';
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

  Widget _infoRow({
    required String label,
    required String value,
    Widget? valueTrailing,
    Widget? valueWidget,
  }) {
    final details = context.screens.plantDetails;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              style: details.infoRowLabelStyle,
            ),
          ),
          spacing.hSm,
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: valueWidget ??
                      Text(
                        value,
                        textAlign: TextAlign.end,
                        style: details.infoRowValueStyle,
                      ),
                ),
                if (valueTrailing != null) ...[
                  spacing.hXs,
                  valueTrailing,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _infoRowIfPresent(String label, String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return _infoRow(label: label, value: trimmed);
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
    final details = context.screens.plantDetails;
    final plant = widget.plant;
    final plantId = widget.plantId;

    final stage = stageInfos.firstWhere(
      (e) => e.value == plant.stage,
      orElse: () => stageInfos.first,
    );

    final speciesTrimmed = plant.species.trim();
    final cultivarsDisplay = plant.cultivarsDisplay;
    final tradingNameTrimmed = plant.tradingName.trim();
    final plantFamilyRow =
        _infoRowIfPresent(l10n.plantFamilyLabel, plant.plantFamily);
    final tradingNameRow =
        _infoRowIfPresent(l10n.plantTradingNameLabel, tradingNameTrimmed);
    final variegation = plant.isGroup
        ? Variegation.none
        : plant.variegation;
    final variegationLabel = l10n.variegationLabelOf(variegation);
    final dateLocale = Localizations.localeOf(context).toString();
    final createdAtLabel = plant.createdAt == null
        ? null
        : DateFormat('d MMM y', dateLocale).format(plant.createdAt!);
    final dateAddedRow =
        _infoRowIfPresent(l10n.plantDateAddedLabel, createdAtLabel);
    final hasBotanicalDetails = plantFamilyRow != null ||
        plant.genus.trim().isNotEmpty ||
        tradingNameRow != null ||
        variegation != Variegation.none ||
        dateAddedRow != null;

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
              style: details.nicknameStyle,
            ),
          if (plant.nickname.trim().isNotEmpty) spacing.vXs,
          if (plant.isArchived) ...[
            Text(
              switch (plant.archiveReason) {
                PlantArchiveReason.merged => l10n.plantArchiveReasonMerged,
                PlantArchiveReason.died => l10n.plantArchiveReasonDied,
                PlantArchiveReason.sold => l10n.plantArchiveReasonSold,
                PlantArchiveReason.gifted => l10n.plantArchiveReasonGifted,
                null => l10n.homeArchive,
              },
              style: details.infoRowLabelStyle,
            ),
            if ((plant.archiveNote ?? '').trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: spacing.xxs, bottom: spacing.xs),
                child: Text(
                  l10n.plantArchiveNoteLabel(plant.archiveNote!.trim()),
                  style: details.infoRowValueStyle,
                ),
              )
            else
              spacing.vXs,
          ],
          if (speciesTrimmed.isNotEmpty)
            _infoRow(
              label: l10n.plantSpecies,
              value: speciesTrimmed,
              valueTrailing: variegation.showIconNearSpecies
                  ? Tooltip(
                      message: variegationLabel,
                      child: Icon(
                        variegation.icon,
                        color: variegation.iconColor,
                        size: spacing.xl,
                      ),
                    )
                  : null,
            ),
          if (cultivarsDisplay.isNotEmpty)
            _infoRow(
              label: l10n.plantCultivar,
              value: cultivarsDisplay,
            ),
          if (plant.isGroup && plant.members.isNotEmpty) ...[
            for (final member in plant.members)
              if (member.variegation != Variegation.none)
                _infoRow(
                  label: (member.cultivar ?? '').trim().isNotEmpty
                      ? member.cultivar!.trim()
                      : l10n.variegationLabel,
                  value: l10n.variegationLabelOf(member.variegation),
                  valueTrailing: Icon(
                    member.variegation.icon,
                    color: member.variegation.iconColor,
                    size: spacing.xl,
                  ),
                ),
          ],
          if (stage.value != 0)
            _infoRow(
              label: l10n.plantGrowthStage,
              value: l10n.stageInfoTitle(stage),
            ),
          if (hasBotanicalDetails) ...[
            spacing.vXs,
            Semantics(
              button: true,
              label: l10n.plantBotanicalData,
              child: InkWell(
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
                      ExcludeSemantics(
                        child: Icon(
                          Icons.arrow_downward,
                          size: context.dimensions.iconSm,
                          color: colors.icon,
                        ),
                      ),
                    ],
                  ),
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
            icon: _icon(context, 'assets/icons/watering.webp'),
            title: l10n.watering,
            value: careDateLabel(plant.lastWateredAt),
            onTap: openWateringHistory,
          ),
          spacing.vXs,
          InfoCard(
            icon: _icon(context, 'assets/icons/fertilize.webp'),
            title: l10n.fertilizing,
            value: careDateLabel(plant.lastFertilizedAt),
            onTap: openFertilizingHistory,
          ),
          spacing.vXs,
          InfoCard(
            icon: _icon(context, 'assets/icons/potting.webp'),
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
                    builder: (_) => AddNoteSheet(
                      parent: NoteParent.plant(plantId),
                    ),
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
          PlantNotesSection(parent: NoteParent.plant(plantId)),
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
                if (plantFamilyRow != null) plantFamilyRow,
                if (plant.genus.trim().isNotEmpty)
                  _infoRow(
                    label: l10n.plantGenus,
                    value: plant.genus.trim(),
                    valueWidget: Semantics(
                      button: true,
                      label: '${l10n.plantGenus}: ${plant.genus.trim()}',
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
                          textAlign: TextAlign.end,
                          style: details.infoRowValueStyle.copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor:
                                colors.heading.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                _infoRow(
                  label: l10n.variegationLabel,
                  value: variegationLabel,
                  valueTrailing: variegation != Variegation.none
                      ? Icon(
                          variegation.icon,
                          color: variegation.iconColor,
                          size: context.dimensions.iconXl,
                        )
                      : null,
                ),
                if (tradingNameRow != null) tradingNameRow,
                if (dateAddedRow != null) dateAddedRow,
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
