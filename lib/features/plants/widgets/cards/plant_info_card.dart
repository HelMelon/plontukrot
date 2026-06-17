import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'info_card.dart';
import '../../../../services/watering_service.dart';
import 'package:intl/intl.dart';
import '../sheets/watering_history_sheet.dart';
import '../../../../services/fertilize_service.dart';
import '../plant_notes_section.dart';
import '../sheets/fertilizing_history_sheet.dart';

class PlantInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String plantId;

  const PlantInfoCard({required this.data, required this.plantId});

  @override
  Widget build(BuildContext context) {
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

          Row(
            children: [
              Expanded(
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: WateringService().watchLastWatering(plantId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return InfoCard(
                        iconImg: Image.asset(
                          'assets/icons/watering.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                        title: "Watering",
                        value: 'Loading...',
                      );
                    }

                    final data = snapshot.data;

                    if (data == null) {
                      return InfoCard(
                        iconImg: Image.asset(
                          'assets/icons/watering.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        title: "Watering",
                        value: 'No watering yet',
                      );
                    }

                    final last = data['wateredAt'] as DateTime?;
                    final next = data['nextWatering'] as DateTime?;

                    String formatDate(DateTime? date) {
                      if (date == null) return '—';
                      return DateFormat('d MMM y').format(date);
                    }

                    final value =
                        '''
Last: ${formatDate(last)}
Next: ${formatDate(next)}
''';

                    return InfoCard(
                      icon: Icons.water_drop,
                      title: "Watering",
                      value: value.trim(),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) =>
                              WateringHistorySheet(plantId: plantId),
                        );
                      },
                    );
                  },
                ),
              ),

              SizedBox(width: 16),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FertilizeService().getFertilizingHistory(plantId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const InfoCard(
                        icon: Icons.science,
                        title: "Fertilizing",
                        value: "Loading...",
                      );
                    }

                    final items = snapshot.data!;

                    if (items.isEmpty) {
                      return const InfoCard(
                        icon: Icons.science,
                        title: "Fertilizing",
                        value: "No data",
                      );
                    }

                    final last = items.first;

                    final value =
                        "${last['fertilizerName']}\n${DateFormat('d MMM y').format(last['appliedAt'])}";

                    return InfoCard(
                      icon: Icons.science,
                      title: "Fertilizing",
                      value: value,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) =>
                              FertilizingHistorySheet(plantId: plantId),
                        );
                      },
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
