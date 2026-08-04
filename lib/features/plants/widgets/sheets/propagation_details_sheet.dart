import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/propagation.dart';
import '../../../../models/propagation_outcome.dart';
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

  Future<void> _openOutcome(
    BuildContext context,
    Propagation current,
    PropagationOutcome outcome,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkPropagationOutcomeSheet(
        propagation: current,
        outcome: outcome,
      ),
    );
  }

  Future<void> _confirmDeleteStage(
    BuildContext context,
    Propagation current,
    PropagationStageEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final entryId = entry.id;
    if (entryId == null) return;

    final isStart = entry.stage <= 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text(
            isStart
                ? l10n.propagationDeleteTitle
                : l10n.propagationDeleteHistoryEntry,
          ),
          content: Text(
            isStart
                ? l10n.propagationDeleteStartStageBody(l10n.stageTitle(1))
                : l10n.propagationDeleteStageEntryBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete),
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
    final l10n = AppLocalizations.of(context);
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
          final startedAtLabel = DateFormat('d MMM y').format(shown.startedAt);

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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isActive
                      ? '${l10n.propagationAliveWithMethod(shown.quantityAlive, l10n.propagationMethodPlural(shown.method))} · ${l10n.propagationMethodLabel(shown.method)}'
                      : '${l10n.propagationMethodLabel(shown.method)} · ${l10n.propagationStatusLabel(shown.status)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? '${l10n.stageInfoTitle(stage)} · ${l10n.daysCount(shown.daysSinceStart)} · ${l10n.propagationSinceDate(startedAtLabel)}'
                      : '${l10n.stageInfoTitle(stage)} · ${l10n.propagationSinceDate(startedAtLabel)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.accentLight,
                  ),
                ),
                if (shown.soldQuantity > 0 ||
                    shown.giftedQuantity > 0 ||
                    shown.tradedQuantity > 0 ||
                    shown.lostQuantity > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (shown.soldQuantity > 0)
                        l10n.propagationSoldCountLabel(shown.soldQuantity),
                      if (shown.giftedQuantity > 0)
                        l10n.propagationGiftedCountLabel(shown.giftedQuantity),
                      if (shown.tradedQuantity > 0)
                        l10n.propagationTradedCountLabel(shown.tradedQuantity),
                      if (shown.lostQuantity > 0)
                        l10n.propagationLostCountLabel(shown.lostQuantity),
                      l10n.propagationOfTotal(shown.quantity),
                    ].join(' · '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  l10n.propagationTimeline,
                  style: const TextStyle(
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
                        return Text(
                          l10n.propagationTimelineEmpty,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
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
                                        l10n.stageInfoTitle(entryStage),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('d MMM y')
                                          .format(entry.changedAt),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l10n.commonDelete,
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
                                if (entry.outcome != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.propagationOutcomeLabel(entry.outcome!),
                                    style: const TextStyle(
                                      color: AppColors.accentLight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (entry.quantityAlive != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.propagationQuantityPieces(
                                      entry.quantityAlive!,
                                    ),
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
                      child: Text(
                        l10n.propagationChangeStage,
                        style: const TextStyle(
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
                          onPressed: () => _openOutcome(
                            context,
                            shown,
                            PropagationOutcome.sold,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.goldAccent,
                            side: const BorderSide(color: AppColors.goldAccent),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            l10n.propagationSell,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openOutcome(
                            context,
                            shown,
                            PropagationOutcome.gifted,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.goldAccent,
                            side: const BorderSide(color: AppColors.goldAccent),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            l10n.propagationGift,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openOutcome(
                            context,
                            shown,
                            PropagationOutcome.traded,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.greenDeep),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            l10n.propagationTrade,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openOutcome(
                            context,
                            shown,
                            PropagationOutcome.lost,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.greenDeep),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            l10n.propagationLose,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
