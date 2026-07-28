import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/propagation.dart';
import '../../../../models/propagation_stage_entry.dart';
import '../../../../models/stage_info.dart';
import '../../../../services/propagation_service.dart';
import 'change_propagation_stage_sheet.dart';
import 'sell_lose_propagation_sheet.dart';

class PropagationDetailsSheet extends StatelessWidget {
  final Propagation propagation;

  const PropagationDetailsSheet({
    super.key,
    required this.propagation,
  });

  static String _daysLabel(int days) {
    if (days == 0) return 'сегодня';
    if (days == 1) return '1 день';
    if (days >= 2 && days <= 4) return '$days дня';
    return '$days дней';
  }

  static StageInfo _stageInfo(int value) {
    return stageInfos.firstWhere(
      (stage) => stage.value == value,
      orElse: () => stageInfos[1],
    );
  }

  Future<void> _openChangeStage(
    BuildContext context,
    Propagation current,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangePropagationStageSheet(propagation: current),
    );
  }

  Future<void> _openSell(BuildContext context, Propagation current) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellPropagationSheet(propagation: current),
    );
  }

  Future<void> _openLose(BuildContext context, Propagation current) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LosePropagationSheet(propagation: current),
    );
  }

  Future<void> _confirmDeleteStage(
    BuildContext context,
    Propagation current,
    PropagationStageEntry entry,
  ) async {
    final entryId = entry.id;
    if (entryId == null) return;

    final isStart = entry.stage <= 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text(
            isStart ? 'Удалить партию?' : 'Удалить стадию?',
          ),
          content: Text(
            isStart
                ? 'Удаление стадии «Старт» удалит всю партию размножения и все остальные стадии.'
                : 'Будет удалена только эта запись стадии. Остальные останутся.',
          ),
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

    await PropagationService().deleteStageEntry(
      propagationId: current.id,
      entryId: entryId,
      stage: entry.stage,
    );

    if (!context.mounted) return;
    if (isStart) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = PropagationService();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: StreamBuilder<Propagation?>(
        stream: service.watchPropagation(propagation.id),
        builder: (context, snapshot) {
          final current = snapshot.data;
          if (snapshot.hasData && current == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) Navigator.pop(context);
            });
            return const SizedBox(height: 120);
          }

          final shown = current ?? propagation;
          final stage = _stageInfo(shown.stage);
          final isActive = shown.isActive;

          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  shown.parentPlantName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isActive
                      ? '${shown.quantityAlive} ${shown.method.pluralLabel} · ${shown.method.label}'
                      : '${shown.method.label} · ${shown.status.label}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? '${stage.title} · ${_daysLabel(shown.daysSinceStart)} · с ${DateFormat('d MMM y').format(shown.startedAt)}'
                      : '${stage.title} · с ${DateFormat('d MMM y').format(shown.startedAt)}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.accentLight,
                  ),
                ),
                if (shown.soldQuantity > 0 || shown.lostQuantity > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (shown.soldQuantity > 0)
                        'Продано: ${shown.soldQuantity}',
                      if (shown.lostQuantity > 0)
                        'Погибло: ${shown.lostQuantity}',
                      'из ${shown.quantity}',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Таймлайн',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<PropagationStageEntry>>(
                    stream: service.watchStageHistory(shown.id),
                    builder: (context, historySnapshot) {
                      if (!historySnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.goldAccent,
                          ),
                        );
                      }

                      final history = historySnapshot.data!;
                      if (history.isEmpty) {
                        return const Text(
                          'Пока нет записей',
                          style: TextStyle(color: AppColors.textSecondary),
                        );
                      }

                      return ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = history[index];
                          final entryStage = _stageInfo(entry.stage);
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.dark2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.greenDeep),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entryStage.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('d MMM y')
                                          .format(entry.changedAt),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Удалить',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _confirmDeleteStage(
                                        context,
                                        shown,
                                        entry,
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (entry.quantityAlive != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${entry.quantityAlive} шт.',
                                    style: const TextStyle(
                                      color: AppColors.accentLight,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                if (entry.note != null &&
                                    entry.note!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    entry.note!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _openChangeStage(context, shown),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldAccent,
                        foregroundColor: AppColors.dark1,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Сменить стадию',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openSell(context, shown),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.goldAccent,
                            side: const BorderSide(color: AppColors.goldAccent),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Продать'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openLose(context, shown),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.greenDeep),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Погибло'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
