import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/watering_entry.dart';
import '../../../../services/watering_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

class WateringHistorySheet extends StatefulWidget {
  final String plantId;

  const WateringHistorySheet({super.key, required this.plantId});

  @override
  State<WateringHistorySheet> createState() => _WateringHistorySheetState();
}

class _WateringHistorySheetState extends State<WateringHistorySheet> {
  final WateringService _service = WateringService();
  static const int _pageSize = 40;

  int _limit = _pageSize;
  late Stream<List<WateringEntry>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _service.getWateringHistory(
      widget.plantId,
      limit: _limit,
    );
  }

  void _loadMore() {
    setState(() {
      _limit += _pageSize;
      _historyStream = _service.getWateringHistory(
        widget.plantId,
        limit: _limit,
      );
    });
  }

  Future<void> _showWateringEditor({
    String? wateringId,
    DateTime? initialDate,
  }) async {
    DateTime selectedDate = initialDate ?? DateTime.now();
    final isEditing = wateringId != null;
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    await showAppModalBottomSheet(
      context: context,
      backgroundColor: colors.modal,
      enableDrag: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: spacing.allLg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SheetDragHandle(),
                    spacing.vLg,
                    Text(
                      isEditing ? l10n.wateringEdit : l10n.wateringAdd,
                      style: typography.titleMedium,
                    ),
                    spacing.vLg,
                    Semantics(
                      button: true,
                      label: l10n.a11ySelectDate(
                        DateFormat.yMMMMd().format(selectedDate),
                      ),
                      child: ListTile(
                        leading: const ExcludeSemantics(
                          child: Icon(Icons.calendar_today),
                        ),
                        title: Text(DateFormat.yMMMMd().format(selectedDate)),
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
                    ),
                    spacing.vMd,
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: context.dimensions.buttonHeight,
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  selectedDate = DateTime.now();
                                });
                              },
                              child: Text(
                                l10n.commonToday,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        spacing.hSm,
                        Expanded(
                          child: SizedBox(
                            height: context.dimensions.buttonHeight,
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
                              child: Text(
                                l10n.commonSave,
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.wateringDeleteTitle),
          content: Text(l10n.wateringDeleteConfirm),
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

    await _service.deleteWatering(
      plantId: widget.plantId,
      wateringId: wateringId,
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
                        l10n.wateringHistory,
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
                          onPressed: () => _showWateringEditor(),
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
                  child: StreamBuilder<List<WateringEntry>>(
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
                            l10n.wateringEmpty,
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
                          final wateringId = item.id;
                          final wateredAt = item.wateredAt;

                          if (wateringId == null) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            padding: spacing.allMd,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(context.radii.md),
                              color: colors.card,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.water_drop_rounded,
                                  color: colors.icon,
                                ),
                                spacing.hSm,
                                Expanded(
                                  child: Text(
                                    DateFormat.yMMMMd().format(wateredAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.commonEdit,
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showWateringEditor(
                                    wateringId: wateringId,
                                    initialDate: wateredAt,
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.commonDelete,
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
