import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/fertilizing_entry.dart';
import '../../../../services/fertilize_service.dart';
import '../dialogs/fertilizer_composition_dialog.dart';
import 'add_fertilizing_sheet.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

class FertilizingHistorySheet extends StatefulWidget {
  final String plantId;

  const FertilizingHistorySheet({super.key, required this.plantId});

  @override
  State<FertilizingHistorySheet> createState() =>
      _FertilizingHistorySheetState();
}

class _FertilizingHistorySheetState extends State<FertilizingHistorySheet> {
  final FertilizeService _service = FertilizeService();
  static const int _pageSize = 40;

  int _limit = _pageSize;
  late Stream<List<FertilizingEntry>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _service.getFertilizingHistory(
      widget.plantId,
      limit: _limit,
    );
  }

  void _loadMore() {
    setState(() {
      _limit += _pageSize;
      _historyStream = _service.getFertilizingHistory(
        widget.plantId,
        limit: _limit,
      );
    });
  }

  Future<void> _showAddSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFertilizingSheet.forPlant(plantId: widget.plantId),
    );
  }

  Future<void> _showEditSheet(FertilizingEntry entry) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFertilizingSheet.edit(
        plantId: widget.plantId,
        entry: entry,
      ),
    );
  }

  Future<void> _confirmDelete(FertilizingEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.fertilizingDeleteTitle),
          content: Text(l10n.fertilizingDeleteConfirm),
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

    await _service.deleteFertilizing(
      plantId: widget.plantId,
      fertilizingId: entry.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sheetHeight = MediaQuery.of(context).size.height * 0.7;
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final typography = context.typography;

    return Material(
      color: colors.modal,
      borderRadius: sheets.topBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: sheetHeight,
          child: Padding(
            padding: spacing.allMd,
            child: Column(
              children: [
                const SheetDragHandle(),
                spacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.fertilizingHistory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.titleMedium,
                      ),
                    ),
                    spacing.hXs,
                    SizedBox(
                      width: context.dimensions.buttonHeight,
                      height: context.dimensions.buttonHeight,
                      child: Tooltip(
                        message: l10n.commonAdd,
                        child: FilledButton(
                          onPressed: _showAddSheet,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(
                              context.dimensions.buttonHeight,
                              context.dimensions.buttonHeight,
                            ),
                            maximumSize: Size(
                              context.dimensions.buttonHeight,
                              context.dimensions.buttonHeight,
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            size: context.dimensions.iconXl,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                spacing.vLg,
                Expanded(
                  child: StreamBuilder<List<FertilizingEntry>>(
                    stream: _historyStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: AccessibleProgressIndicator());
                      }

                      final items = snapshot.data!;

                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.fertilizingEmpty,
                            style: typography.bodySmall,
                          ),
                        );
                      }

                      final canLoadMore = items.length >= _limit;

                      return ListView.separated(
                        itemCount: items.length + (canLoadMore ? 1 : 0),
                        separatorBuilder: (_, __) => spacing.vSm,
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return TextButton(
                              onPressed: _loadMore,
                              child: Text(
                                l10n.commonShowMore,
                                style: typography.link,
                              ),
                            );
                          }

                          final item = items[index];
                          final displayName = l10n.fertilizerDisplayName(
                            storedName: item.fertilizerName,
                            fertilizerId: item.fertilizerId,
                          );
                          final dateLabel =
                              DateFormat.yMMMMd().format(item.appliedAt);
                          final subtitle =
                              '${l10n.applicationMethodLabel(item.applicationMethod)} · $dateLabel';

                          return Semantics(
                            button: true,
                            label: '$displayName. $subtitle',
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(context.radii.md),
                              onTap: () {
                                showFertilizerCompositionDialog(
                                  context: context,
                                  title: displayName,
                                  components: item.components,
                                  waterMl: item.waterMl,
                                );
                              },
                              child: Container(
                                padding: spacing.allMd,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      context.radii.md),
                                  color: colors.card,
                                ),
                                child: Row(
                                  children: [
                                    ExcludeSemantics(
                                      child: Icon(
                                        Icons.science,
                                        color: colors.icon,
                                      ),
                                    ),
                                    spacing.hSm,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                typography.bodyLarge.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          spacing.vXxs,
                                          Text(
                                            subtitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: typography.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l10n.commonEdit,
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _showEditSheet(item),
                                    ),
                                    IconButton(
                                      tooltip: l10n.commonDelete,
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _confirmDelete(item),
                                    ),
                                  ],
                                ),
                              ),
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
