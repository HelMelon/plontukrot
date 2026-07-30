import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/fertilizing_entry.dart';
import '../../../../models/plant.dart';
import '../../../../models/repotting_entry.dart';
import '../../../../models/stage_info.dart';
import '../../../../models/variegation.dart';
import '../../../../models/watering_entry.dart';
import '../../../../services/fertilize_service.dart';
import '../../../../services/repotting_service.dart';
import '../../../../services/watering_service.dart';
import '../../pages/plant_species_details_page.dart';
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
    final plant = widget.plant;
    final plantId = widget.plantId;

    final stage = stageInfos.firstWhere(
      (e) => e.value == plant.stage,
      orElse: () => stageInfos.first,
    );

    final speciesTrimmed = plant.species.trim();
    final cultivarTrimmed = plant.cultivar?.trim() ?? '';
    final tradingNameTrimmed = plant.tradingName.trim();
    final plantFamilyLine = _botanicalLine('Семейство', plant.plantFamily);
    final genusLine = _botanicalLine('Род', plant.genus);
    final tradingNameLine = _botanicalLine('Торговое название', tradingNameTrimmed);
    final variegation = plant.variegation;
    final hasBotanicalDetails = plantFamilyLine != null ||
        genusLine != null ||
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
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlantSpeciesDetailsPage(
                              species: speciesTrimmed,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Text(
                        'Вид: $speciesTrimmed',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _botanicalStyle.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor:
                              AppColors.heading.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  if (variegation.showIconNearSpecies) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: variegation.label,
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
                'Сорт: $cultivarTrimmed',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _botanicalStyle,
              ),
            ),
          if (stage.value != 0)
            Text(
              'Стадия: ${stage.title}',
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
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ботанические данные',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
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

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  wrapItem(
                    StreamBuilder<WateringEntry?>(
                      stream: WateringService().watchLastWatering(plantId),
                      builder: (context, snapshot) {
                        void openHistory() {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            enableDrag: true,
                            builder: (_) =>
                                WateringHistorySheet(plantId: plantId),
                          );
                        }

                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return InfoCard(
                            icon: _icon('assets/icons/watering.png'),
                            title: 'Полив',
                            value: 'Загрузка...',
                            onTap: openHistory,
                          );
                        }

                        final watering = snapshot.data;
                        final last = watering?.wateredAt;
                        final value = last == null
                            ? 'Нет данных'
                            : DateFormat('d MMM y').format(last);

                        return InfoCard(
                          icon: _icon('assets/icons/watering.png'),
                          title: 'Полив',
                          value: value,
                          onTap: openHistory,
                        );
                      },
                    ),
                  ),
                  wrapItem(
                    StreamBuilder<List<FertilizingEntry>>(
                      stream: FertilizeService().getFertilizingHistory(plantId),
                      builder: (context, snapshot) {
                        void openHistory() {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            enableDrag: true,
                            builder: (_) =>
                                FertilizingHistorySheet(plantId: plantId),
                          );
                        }

                        if (!snapshot.hasData) {
                          return InfoCard(
                            icon: _icon('assets/icons/fertilize.png'),
                            title: 'Подкормка',
                            value: 'Загрузка...',
                            onTap: openHistory,
                          );
                        }

                        final items = snapshot.data!;
                        final value = items.isEmpty
                            ? 'Нет данных'
                            : DateFormat('d MMM y')
                                .format(items.first.appliedAt);

                        return InfoCard(
                          icon: _icon('assets/icons/fertilize.png'),
                          title: 'Подкормка',
                          value: value,
                          onTap: openHistory,
                        );
                      },
                    ),
                  ),
                  wrapItem(
                    StreamBuilder<RepottingEntry?>(
                      stream: RepottingService().watchLastRepotting(plantId),
                      builder: (context, snapshot) {
                        void openHistory() {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            enableDrag: true,
                            builder: (_) =>
                                RepottingHistorySheet(plantId: plantId),
                          );
                        }

                        if (!snapshot.hasData &&
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return InfoCard(
                            icon: _icon('assets/icons/potting.png'),
                            title: 'Пересадка',
                            value: 'Загрузка...',
                            onTap: openHistory,
                          );
                        }

                        final last = snapshot.data;
                        final value = last == null
                            ? 'Нет данных'
                            : DateFormat('d MMM y').format(last.repottedAt);

                        return InfoCard(
                          icon: _icon('assets/icons/potting.png'),
                          title: 'Пересадка',
                          value: value,
                          onTap: openHistory,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          PlantPropagationsSection(
            plantId: plantId,
            plantName:
                plant.species.isNotEmpty ? plant.species : 'Без названия',
            plantFamily: plant.plantFamily ?? '',
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Журнал',
                  style: TextStyle(
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
                label: const Text('Добавить'),
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
                  const Text(
                    'Ботанические данные',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (plantFamilyLine != null) plantFamilyLine,
                  if (genusLine != null) genusLine,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Вариегатность: ${variegation.label}',
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
