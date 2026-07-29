import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/watering_entry.dart';
import '../../../../services/watering_service.dart';

class WateringHistorySheet extends StatefulWidget {
  final String plantId;

  const WateringHistorySheet({super.key, required this.plantId});

  @override
  State<WateringHistorySheet> createState() => _WateringHistorySheetState();
}

class _WateringHistorySheetState extends State<WateringHistorySheet> {
  final WateringService _service = WateringService();

  Future<void> _showWateringEditor({
    String? wateringId,
    DateTime? initialDate,
  }) async {
    DateTime selectedDate = initialDate ?? DateTime.now();
    final isEditing = wateringId != null;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      enableDrag: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEditing ? 'Изменить полив' : 'Добавить полив',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat('d MMMM y').format(selectedDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: AppTheme.buttonHeight,
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  selectedDate = DateTime.now();
                                });
                              },
                              child: const Text(
                                'Сегодня',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: AppTheme.buttonHeight,
                            child: FilledButton(
                              onPressed: () async {
                                if (isEditing) {
                                  await _service.updateWatering(
                                    plantId: widget.plantId,
                                    wateringId: wateringId,
                                    wateredAt: selectedDate,
                                  );
                                } else {
                                  await _service.addWatering(
                                    plantId: widget.plantId,
                                    wateredAt: selectedDate,
                                  );
                                }
                                if (context.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                              child: const Text(
                                'Сохранить',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(String wateringId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить полив'),
          content: const Text('Удалить эту запись?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _service.deleteWatering(
      plantId: widget.plantId,
      wateringId: wateringId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.7;

    return Material(
      color: AppColors.backgroundSecondary,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: sheetHeight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'История полива',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: AppTheme.buttonHeight,
                      child: FilledButton.icon(
                        onPressed: () => _showWateringEditor(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Добавить',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<List<WateringEntry>>(
                    stream: _service.getWateringHistory(widget.plantId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final items = snapshot.data!;

                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'Пока нет записей о поливе',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final wateringId = item.id;
                          final wateredAt = item.wateredAt;

                          if (wateringId == null) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.dark2,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.water_drop_rounded,
                                  color: AppColors.accentLight,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    DateFormat('d MMMM y').format(wateredAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Изменить',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showWateringEditor(
                                    wateringId: wateringId,
                                    initialDate: wateredAt,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Удалить',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _confirmDelete(wateringId),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
