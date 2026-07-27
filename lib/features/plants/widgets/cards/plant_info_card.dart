import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/fertilizing_entry.dart';
import '../../../../models/repotting_entry.dart';
import '../../../../models/stage_info.dart';
import '../../../../services/fertilize_service.dart';
import '../../../../services/repotting_service.dart';
import '../../../../services/watering_service.dart';
import '../notes/plant_notes_section.dart';
import '../sheets/fertilizing_history_sheet.dart';
import '../sheets/repotting_history_sheet.dart';
import '../sheets/watering_history_sheet.dart';
import 'info_card.dart';

class PlantInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String plantId;

  const PlantInfoCard({super.key, required this.data, required this.plantId});

  static Widget _icon(String asset) {
    return Image.asset(
      asset,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = stageInfos.firstWhere(
      (e) => e.value == data['stage'],
      orElse: () => stageInfos.first,
    );

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
            data['name'] ?? 'Unnamed Plant',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Name: ${data['nickname'] ?? 'Unnamed Plant'}',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 24,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Семейство: ${data['family'] ?? 'Не известно'}',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 24,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          stage.value != 0
              ? Text(
                  'Stage: ${stage.title}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 24,
                    color: AppColors.heading,
                  ),
                )
              : const SizedBox.shrink(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: WateringService().watchLastWatering(plantId),
                  builder: (context, snapshot) {
                    void openHistory() {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            WateringHistorySheet(plantId: plantId),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return InfoCard(
                        icon: _icon('assets/icons/watering.png'),
                        title: 'Watering',
                        value: 'Loading...',
                        onTap: openHistory,
                      );
                    }

                    final watering = snapshot.data;
                    final last = watering?['wateredAt'] as DateTime?;
                    final value = last == null
                        ? 'No data'
                        : DateFormat('d MMM y').format(last);

                    return InfoCard(
                      icon: _icon('assets/icons/watering.png'),
                      title: 'Watering',
                      value: value,
                      onTap: openHistory,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StreamBuilder<List<FertilizingEntry>>(
                  stream: FertilizeService().getFertilizingHistory(plantId),
                  builder: (context, snapshot) {
                    void openHistory() {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            FertilizingHistorySheet(plantId: plantId),
                      );
                    }

                    if (!snapshot.hasData) {
                      return InfoCard(
                        icon: _icon('assets/icons/fertilize.png'),
                        title: 'Fertilizing',
                        value: 'Loading...',
                        onTap: openHistory,
                      );
                    }

                    final items = snapshot.data!;
                    final value = items.isEmpty
                        ? 'No data'
                        : DateFormat('d MMM y').format(items.first.appliedAt);

                    return InfoCard(
                      icon: _icon('assets/icons/fertilize.png'),
                      title: 'Fertilizing',
                      value: value,
                      onTap: openHistory,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StreamBuilder<RepottingEntry?>(
                  stream: RepottingService().watchLastRepotting(plantId),
                  builder: (context, snapshot) {
                    void openHistory() {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            RepottingHistorySheet(plantId: plantId),
                      );
                    }

                    if (!snapshot.hasData &&
                        snapshot.connectionState == ConnectionState.waiting) {
                      return InfoCard(
                        icon: _icon('assets/icons/potting.png'),
                        title: 'Repotting',
                        value: 'Loading...',
                        onTap: openHistory,
                      );
                    }

                    final last = snapshot.data;
                    final value = last == null
                        ? 'No data'
                        : DateFormat('d MMM y').format(last.repottedAt);

                    return InfoCard(
                      icon: _icon('assets/icons/potting.png'),
                      title: 'Repotting',
                      value: value,
                      onTap: openHistory,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Plant Journal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 12),
          PlantNotesSection(plantId: plantId),
        ],
      ),
    );
  }
}
