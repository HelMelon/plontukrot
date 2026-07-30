import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/propagation.dart';
import '../../../../models/stage_info.dart';
import '../../../../services/propagation_service.dart';
import '../sheets/add_propagation_sheet.dart';
import '../sheets/propagation_details_sheet.dart';

class PlantPropagationsSection extends StatefulWidget {
  final String plantId;
  final String plantName;
  final String plantFamily;

  const PlantPropagationsSection({
    super.key,
    required this.plantId,
    required this.plantName,
    required this.plantFamily,
  });

  @override
  State<PlantPropagationsSection> createState() =>
      _PlantPropagationsSectionState();
}

class _PlantPropagationsSectionState extends State<PlantPropagationsSection> {
  late final Stream<List<Propagation>> _propagationsStream;

  @override
  void initState() {
    super.initState();
    _propagationsStream =
        PropagationService().watchPropagationsForPlant(widget.plantId);
  }

  static String _daysLabel(int days) {
    if (days == 0) return 'сегодня';
    if (days == 1) return '1 день';
    if (days >= 2 && days <= 4) return '$days дня';
    return '$days дней';
  }

  static String _stageTitle(int value) {
    return stageInfos
        .firstWhere(
          (stage) => stage.value == value,
          orElse: () => stageInfos[1],
        )
        .title;
  }

  Future<void> _openAdd(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPropagationSheet(
        parentPlantId: widget.plantId,
        parentPlantName: widget.plantName,
        parentPlantFamily: widget.plantFamily,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Размножение',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.heading,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openAdd(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.goldAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Propagation>>(
          stream: _propagationsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.goldAccent),
                ),
              );
            }

            final items = snapshot.data ?? const <Propagation>[];
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dark2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Нет активных размножений',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _openDetails(context, item),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.dark2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.greenDeep),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_stageTitle(item.stage)} · ${_daysLabel(item.daysSinceStart)}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantityAlive} ${item.method.pluralLabel} · ${DateFormat('d MMM y').format(item.startedAt)}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
