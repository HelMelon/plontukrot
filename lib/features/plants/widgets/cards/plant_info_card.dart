import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/plant.dart';
import '../../../../models/stage_info.dart';
import '../../../../models/variegation.dart';
import '../../pages/plant_genus_details_page.dart';
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

  const PlantInfoCard({super.key, required this.plant, required this.plantId});

  @override
  State<PlantInfoCard> createState() => _PlantInfoCardState();
}

class _PlantInfoCardState extends State<PlantInfoCard> {
  final GlobalKey _botanicalDetailsKey = GlobalKey();

  static Widget _icon(String asset) {
    return Image.asset(
      asset,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
    );
  }

  static const TextStyle _botanicalStyle = TextStyle(
    fontSize: 20,
    color: AppColors.heading,
  );

  Widget? _botanicalLine(String label, String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
    final plant = widget.plant;
    final plantId = widget.plantId;

    final stage = stageInfos.firstWhere(
      (e) => e.value == plant.stage,
      orElse: () => stageInfos.first,
    );

    final speciesTrimmed = plant.species.trim();
    final cultivarTrimmed = plant.cultivar?.trim() ?? '';
    final tradingNameTrimmed = plant.tradingName.trim();
    final plantFamilyLine = _botanicalLine(l10n.plantFamilyLabel, plant.plantFamily);
    final tradingNameLine =
        _botanicalLine(l10n.plantTradingNameLabel, tradingNameTrimmed);
    final variegation = plant.variegation;
    final variegationLabel = l10n.variegationLabelOf(variegation);
    final hasBotanicalDetails = plantFamilyLine != null ||
        plant.genus.trim().isNotEmpty ||
        tradingNameLine != null ||
        variegation != Variegation.none;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.greenDeep),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plant.nickname.trim().isNotEmpty)
            Text(
              plant.nickname,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          if (plant.nickname.trim().isNotEmpty) const SizedBox(height: 8),
          if (speciesTrimmed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                    const SizedBox(width: 8),
                    Tooltip(
                      message: variegationLabel,
                      child: Icon(
                        variegation.icon,
                        color: variegation.iconColor,
                        size: 24,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (cultivarTrimmed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.plantCultivarLabel(cultivarTrimmed),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _botanicalStyle,
              ),
            ),
          if (stage.value != 0)
            Text(
              l10n.plantStageLabel(l10n.stageInfoTitle(stage)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                color: AppColors.heading,
              ),
            ),
          if (hasBotanicalDetails) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: _scrollToBotanicalDetails,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.plantBotanicalData,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: AppColors.goldAccent,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final stackVertically = constraints.maxWidth < 340;
              final itemWidth = stackVertically
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing * 2) / 3;

              Widget wrapItem(Widget child) {
                return SizedBox(width: itemWidth, child: child);
              }

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

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  wrapItem(
                    InfoCard(
                      icon: _icon('assets/icons/watering.png'),
                      title: l10n.watering,
                      value: careDateLabel(plant.lastWateredAt),
                      onTap: openWateringHistory,
                    ),
                  ),
                  wrapItem(
                    InfoCard(
                      icon: _icon('assets/icons/fertilize.png'),
                      title: l10n.fertilizing,
                      value: careDateLabel(plant.lastFertilizedAt),
                      onTap: openFertilizingHistory,
                    ),
                  ),
                  wrapItem(
                    InfoCard(
                      icon: _icon('assets/icons/potting.png'),
                      title: l10n.repotting,
                      value: careDateLabel(plant.lastRepottedAt),
                      onTap: openRepottingHistory,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          PlantPropagationsSection(
            plantId: plantId,
            plantName: plant.species.isNotEmpty
                ? plant.species
                : l10n.commonUntitled,
            plantFamily: plant.plantFamily ?? '',
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.plantJournal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.heading,
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
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.commonAdd),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PlantNotesSection(plantId: plantId),
          if (hasBotanicalDetails) ...[
            const SizedBox(height: 32),
            KeyedSubtree(
              key: _botanicalDetailsKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.plantBotanicalData,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (plantFamilyLine != null) plantFamilyLine,
                  if (plant.genus.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
                              borderRadius: BorderRadius.circular(8),
                              child: Text(
                                plant.genus.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _botanicalStyle.copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.heading
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                          const SizedBox(width: 8),
                          Icon(
                            variegation.icon,
                            color: variegation.iconColor,
                            size: 22,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (tradingNameLine != null) tradingNameLine,
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
