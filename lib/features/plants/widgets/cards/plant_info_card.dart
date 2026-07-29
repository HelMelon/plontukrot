import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/fertilizing_entry.dart';
import '../../../../models/plant.dart';
import '../../../../models/repotting_entry.dart';
import '../../../../models/stage_info.dart';
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

class PlantInfoCard extends StatelessWidget {
  final Plant plant;
  final String plantId;

  const PlantInfoCard({super.key, required this.plant, required this.plantId});

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

  @override
  Widget build(BuildContext context) {
    final stage = stageInfos.firstWhere(
      (e) => e.value == plant.stage,
      orElse: () => stageInfos.first,
    );

    final plantFamilyLine = _botanicalLine('Семейство', plant.plantFamily);
    final genusLine = _botanicalLine('Род', plant.genus);
    final speciesTrimmed = plant.species.trim();
    final cultivarLine = _botanicalLine('Сорт', plant.cultivar);

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
          const SizedBox(height: 8),
          if (plantFamilyLine != null) plantFamilyLine,
          if (genusLine != null) genusLine,
          if (speciesTrimmed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                    decorationColor: AppColors.heading.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          if (cultivarLine != null) cultivarLine,
          stage.value != 0
              ? Text(
                  'Стадия: ${stage.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppColors.heading,
                  ),
                )
              : const SizedBox.shrink(),
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
        ],
      ),
    );
  }
}
