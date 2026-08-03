import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/fertilizing_entry.dart';
import '../../../../services/fertilize_service.dart';
import '../dialogs/fertilizer_composition_dialog.dart';
import 'add_fertilizing_sheet.dart';

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
                    Expanded(
                      child: Text(
                        l10n.fertilizingHistory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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
                        onPressed: _showAddSheet,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          l10n.commonAdd,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<List<FertilizingEntry>>(
                    stream: _historyStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final items = snapshot.data!;

                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.fertilizingEmpty,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      final canLoadMore = items.length >= _limit;

                      return ListView.separated(
                        itemCount: items.length + (canLoadMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return TextButton(
                              onPressed: _loadMore,
                              child: Text(
                                l10n.commonShowMore,
                                style: const TextStyle(
                                  color: AppColors.goldAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }

                          final item = items[index];
                          final displayName = l10n.fertilizerDisplayName(
                            storedName: item.fertilizerName,
                            fertilizerId: item.fertilizerId,
                          );

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              showFertilizerCompositionDialog(
                                context: context,
                                title: displayName,
                                components: item.components,
                                waterMl: item.waterMl,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: AppColors.dark2,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.science,
                                    color: AppColors.accentLight,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${l10n.applicationMethodLabel(item.applicationMethod)} · ${DateFormat.yMMMMd().format(item.appliedAt)}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
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
