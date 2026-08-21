import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/repotting_entry.dart';
import '../../../../services/repotting_service.dart';
import '../dialogs/soil_composition_dialog.dart';
import 'add_repotting_sheet.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

class RepottingHistorySheet extends StatefulWidget {
  final String plantId;

  const RepottingHistorySheet({super.key, required this.plantId});

  @override
  State<RepottingHistorySheet> createState() => _RepottingHistorySheetState();
}

class _RepottingHistorySheetState extends State<RepottingHistorySheet> {
  final RepottingService _service = RepottingService();
  static const int _pageSize = 40;

  int _limit = _pageSize;
  late Stream<List<RepottingEntry>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _service.getRepottingHistory(
      widget.plantId,
      limit: _limit,
    );
  }

  void _loadMore() {
    setState(() {
      _limit += _pageSize;
      _historyStream = _service.getRepottingHistory(
        widget.plantId,
        limit: _limit,
      );
    });
  }

  Future<void> _showAddSheet() async {
    await showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => AddRepottingSheet.forPlant(plantId: widget.plantId),
    );
  }

  Future<void> _showEditSheet(RepottingEntry entry) async {
    await showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => AddRepottingSheet.edit(
        plantId: widget.plantId,
        entry: entry,
      ),
    );
  }

  Future<void> _confirmDelete(String repottingId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.repottingDeleteTitle),
          content: Text(l10n.repottingDeleteConfirm),
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

    await _service.deleteRepotting(
      plantId: widget.plantId,
      repottingId: repottingId,
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
                        l10n.repottingHistory,
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
                            context.icons.add,
                            size: context.dimensions.iconXl,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                spacing.vLg,
                Expanded(
                  child: StreamBuilder<List<RepottingEntry>>(
                    stream: _historyStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                            child: AccessibleProgressIndicator());
                      }

                      final items = snapshot.data!;

                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.repottingEmpty,
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
                          final repottingId = item.id!;
                          final title = l10n.soilDisplayName(item.soilName);
                          final dateLabel =
                              DateFormat.yMMMMd().format(item.repottedAt);
                          final semanticsLabel = item.slowReleaseFertilizer
                              ? '$title. $dateLabel. ${l10n.repottingSlowRelease}'
                              : '$title. $dateLabel';

                          return Semantics(
                            button: true,
                            label: semanticsLabel,
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(context.radii.md),
                              onTap: () {
                                showSoilCompositionDialog(
                                  context: context,
                                  title: title,
                                  components: item.components,
                                );
                              },
                              child: Container(
                                padding: spacing.allMd,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(context.radii.md),
                                  color: colors.card,
                                ),
                                child: Row(
                                  children: [
                                    ExcludeSemantics(
                                      child: HugeIcon(
                                        icon: context.icons.repottingAction,
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
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                typography.bodyLarge.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          spacing.vXxs,
                                          Text(
                                            dateLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: typography.bodySmall,
                                          ),
                                          if (item.slowReleaseFertilizer) ...[
                                            spacing.vXxs,
                                            Text(
                                              l10n.repottingSlowRelease,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  typography.bodySmall.copyWith(
                                                color: colors.icon,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l10n.commonEdit,
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(context.icons.editOutlined),
                                      onPressed: () => _showEditSheet(item),
                                    ),
                                    IconButton(
                                      tooltip: l10n.commonDelete,
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(context.icons.delete),
                                      onPressed: () =>
                                          _confirmDelete(repottingId),
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
