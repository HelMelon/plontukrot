import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/accessible_progress_indicator.dart';
import '../../../../models/propagation.dart';
import '../../../../models/propagation_outcome.dart';
import '../../../../models/propagation_stage_entry.dart';
import '../../../../models/stage_info.dart';
import '../../../../models/wish_list_item.dart';
import '../../../../services/note_service.dart';
import '../../../../services/propagation_service.dart';
import '../../../wish_list/widgets/sheets/select_wish_list_item_sheet.dart';
import '../notes/plant_notes_section.dart';
import 'add_note_sheet.dart';
import 'add_plant_sheet.dart';
import 'change_propagation_stage_sheet.dart';
import 'sell_lose_propagation_sheet.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

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
    await showAppModalBottomSheet(
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
    final result = await showAppModalBottomSheet<MarkPropagationOutcomeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkPropagationOutcomeSheet(
        propagation: current,
        outcome: outcome,
      ),
    );

    if (result == null || !result.success || !result.linkWishList) return;
    if (!context.mounted) return;

    final wishItem = await showAppModalBottomSheet<WishListItem>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (_) => const SelectWishListItemSheet(),
    );

    if (wishItem == null || !context.mounted) return;

    await showAppModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (_) => AddPlantSheet(
        initialTradingName: wishItem.nameAlt,
        wishListItemId: wishItem.id,
      ),
    );
  }

  Future<void> _confirmDeleteStage(
    BuildContext context,
    Propagation current,
    PropagationStageEntry entry, {
    required int historyLength,
  }) async {
    final l10n = AppLocalizations.of(context);
    final entryId = entry.id;
    if (entryId == null) return;

    final deletesStartStage = entry.stage <= 1;
    final deletesEntireBatch = deletesStartStage || historyLength <= 1;

    final String title;
    final String body;
    if (deletesStartStage) {
      title = l10n.propagationDeleteTitle;
      body = l10n.propagationDeleteStartStageBody(l10n.stageTitle(1));
    } else if (deletesEntireBatch) {
      title = l10n.propagationDeleteTitle;
      body = l10n.propagationDeleteLastEntryBody;
    } else {
      title = l10n.propagationDeleteHistoryEntry;
      body = l10n.propagationDeleteStageEntryBody;
    }

    final colors = context.colors;
    final confirmed = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.modal,
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onPrimary,
              ),
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
    if (deletesEntireBatch) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = PropagationService();
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final sheets = context.components.sheets;
    final buttons = context.components.buttons;
    final typography = context.typography;
    final dimensions = context.dimensions;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.modal,
        borderRadius: sheets.topBorderRadius,
      ),
      child: StreamBuilder<Propagation?>(
        stream: service.watchPropagation(propagation.id),
        builder: (context, snapshot) {
          final current = snapshot.data;
          if (snapshot.hasData && current == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) Navigator.pop(context);
            });
            return SizedBox(height: dimensions.buttonHeight * 2);
          }

          final shown = current ?? propagation;
          final stage = _stageInfo(shown.stage);
          final isActive = shown.isActive;
          final startedAtLabel = DateFormat('d MMM y').format(shown.startedAt);

          return Padding(
            padding: sheets.contentPadding.copyWith(bottom: spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: const SheetDragHandle()),
                spacing.vXl,
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shown.parentPlantName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: typography.titleLarge,
                        ),
                        spacing.vXxs,
                        Text(
                          isActive
                              ? '${l10n.propagationAliveWithMethod(shown.quantityAlive, l10n.propagationMethodPlural(shown.method))} · ${l10n.propagationMethodLabel(shown.method)}'
                              : '${l10n.propagationMethodLabel(shown.method)} · ${l10n.propagationStatusLabel(shown.status)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodyLarge.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        spacing.vXxs,
                        Text(
                          isActive
                              ? '${l10n.stageInfoTitle(stage)} · ${l10n.daysCount(shown.daysSinceStart)} · ${l10n.propagationSinceDate(startedAtLabel)}'
                              : '${l10n.stageInfoTitle(stage)} · ${l10n.propagationSinceDate(startedAtLabel)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodyMedium.copyWith(
                            color: colors.icon,
                          ),
                        ),
                        if (shown.soldQuantity > 0 ||
                            shown.giftedQuantity > 0 ||
                            shown.tradedQuantity > 0 ||
                            shown.lostQuantity > 0) ...[
                          spacing.vXxs,
                          Text(
                            [
                              if (shown.soldQuantity > 0)
                                l10n.propagationSoldCountLabel(
                                  shown.soldQuantity,
                                ),
                              if (shown.giftedQuantity > 0)
                                l10n.propagationGiftedCountLabel(
                                  shown.giftedQuantity,
                                ),
                              if (shown.tradedQuantity > 0)
                                l10n.propagationTradedCountLabel(
                                  shown.tradedQuantity,
                                ),
                              if (shown.lostQuantity > 0)
                                l10n.propagationLostCountLabel(
                                  shown.lostQuantity,
                                ),
                              l10n.propagationOfTotal(shown.quantity),
                            ].join(' · '),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: typography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                        spacing.vXl,
                        Text(
                          l10n.propagationTimeline,
                          style: typography.sectionTitle,
                        ),
                        spacing.vSm,
                        StreamBuilder<List<PropagationStageEntry>>(
                          stream: service.watchStageHistory(shown.id),
                          builder: (context, historySnapshot) {
                            if (!historySnapshot.hasData) {
                              return SizedBox(
                                height: dimensions.buttonHeight * 2,
                                child: Center(
                                  child: AccessibleProgressIndicator(
                                    color: colors.primary,
                                  ),
                                ),
                              );
                            }

                            final history = historySnapshot.data!;
                            if (history.isEmpty) {
                              return Text(
                                l10n.propagationTimelineEmpty,
                                style: typography.bodySmall,
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: history.length,
                              separatorBuilder: (_, __) => spacing.vSm,
                              itemBuilder: (context, index) {
                                final entry = history[index];
                                final entryStage = _stageInfo(entry.stage);
                                return Container(
                                  padding: spacing.allMd,
                                  decoration: BoxDecoration(
                                    color: colors.card,
                                    borderRadius:
                                        BorderRadius.circular(radii.md),
                                    border: Border.all(color: colors.outline),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              l10n.stageInfoTitle(entryStage),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: typography.bodyMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          spacing.hXs,
                                          Text(
                                            DateFormat('d MMM y')
                                                .format(entry.changedAt),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: typography.bodySmall,
                                          ),
                                          IconButton(
                                            tooltip: l10n.commonDelete,
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () =>
                                                _confirmDeleteStage(
                                              context,
                                              shown,
                                              entry,
                                              historyLength: history.length,
                                            ),
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (entry.outcome != null) ...[
                                        spacing.vXxs,
                                        Text(
                                          l10n.propagationOutcomeLabel(
                                            entry.outcome!,
                                          ),
                                          style: typography.bodySmall.copyWith(
                                            color: colors.icon,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      if (entry.quantityAlive != null) ...[
                                        spacing.vXxs,
                                        Text(
                                          l10n.propagationQuantityPieces(
                                            entry.quantityAlive!,
                                          ),
                                          style: typography.bodySmall.copyWith(
                                            color: colors.icon,
                                          ),
                                        ),
                                      ],
                                      if (entry.note != null &&
                                          entry.note!.isNotEmpty) ...[
                                        spacing.vXxs,
                                        Text(
                                          entry.note!,
                                          style:
                                              typography.bodyMedium.copyWith(
                                            color: colors.textSecondary,
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
                        spacing.vXl,
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
                                showAppModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  enableDrag: true,
                                  builder: (_) => AddNoteSheet(
                                    parent: NoteParent.propagation(shown.id),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.add,
                                size: dimensions.iconMd,
                              ),
                              label: Text(l10n.commonAdd),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.primary,
                              ),
                            ),
                          ],
                        ),
                        spacing.vXs,
                        PlantNotesSection(
                          parent: NoteParent.propagation(shown.id),
                        ),
                        if (isActive) ...[
                          spacing.vMd,
                          SizedBox(
                            width: double.infinity,
                            height: dimensions.buttonHeight,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _openChangeStage(context, shown),
                              child: Text(l10n.propagationChangeStage),
                            ),
                          ),
                          spacing.vSm,
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
                                    foregroundColor: colors.primary,
                                    side: BorderSide(color: colors.primary),
                                    minimumSize:
                                        Size.fromHeight(buttons.height),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        buttons.radius,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.propagationSell,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              spacing.hSm,
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _openOutcome(
                                    context,
                                    shown,
                                    PropagationOutcome.gifted,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.primary,
                                    side: BorderSide(color: colors.primary),
                                    minimumSize:
                                        Size.fromHeight(buttons.height),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        buttons.radius,
                                      ),
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
                          spacing.vSm,
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
                                    foregroundColor: colors.textSecondary,
                                    side: BorderSide(color: colors.outline),
                                    minimumSize:
                                        Size.fromHeight(buttons.height),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        buttons.radius,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.propagationTrade,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              spacing.hSm,
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _openOutcome(
                                    context,
                                    shown,
                                    PropagationOutcome.lost,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.textSecondary,
                                    side: BorderSide(color: colors.outline),
                                    minimumSize:
                                        Size.fromHeight(buttons.height),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        buttons.radius,
                                      ),
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
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
