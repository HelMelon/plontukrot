import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/manipulation_entry.dart';
import '../../../../models/manipulation_type.dart';
import '../../../../services/manipulation_service.dart';
import 'add_manipulation_sheet.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

class ManipulationsHistorySheet extends StatefulWidget {
  final String plantId;
  final int plantStage;

  const ManipulationsHistorySheet({
    super.key,
    required this.plantId,
    this.plantStage = 0,
  });

  @override
  State<ManipulationsHistorySheet> createState() =>
      _ManipulationsHistorySheetState();
}

class _ManipulationsHistorySheetState extends State<ManipulationsHistorySheet> {
  final ManipulationService _service = ManipulationService();
  static const int _pageSize = 40;

  int _limit = _pageSize;
  late Stream<List<ManipulationEntry>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _service.getManipulationHistory(
      widget.plantId,
      limit: _limit,
    );
  }

  void _loadMore() {
    setState(() {
      _limit += _pageSize;
      _historyStream = _service.getManipulationHistory(
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
      builder: (_) => AddManipulationSheet.forPlant(
        plantId: widget.plantId,
        plantStage: widget.plantStage,
      ),
    );
  }

  Future<void> _showEditSheet(ManipulationEntry entry) async {
    await showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => AddManipulationSheet.edit(
        plantId: widget.plantId,
        plantStage: widget.plantStage,
        entry: entry,
      ),
    );
  }

  Future<void> _confirmDelete(ManipulationEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.manipulationDeleteTitle),
          content: Text(l10n.manipulationDeleteConfirm),
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

    await _service.deleteManipulation(
      plantId: widget.plantId,
      manipulationId: entry.id,
    );
  }

  IconData _iconForType(ManipulationType type) {
    return switch (type) {
      ManipulationType.pinching => Icons.content_cut_outlined,
      ManipulationType.rerooting => Icons.healing_outlined,
      ManipulationType.stimulator => Icons.biotech_outlined,
    };
  }

  String _titleForEntry(ManipulationEntry entry, AppLocalizations l10n) {
    return switch (entry.type) {
      ManipulationType.stimulator =>
        entry.stimulatorName?.trim().isNotEmpty == true
            ? entry.stimulatorName!.trim()
            : l10n.manipulationTypeStimulator,
      _ => l10n.manipulationTypeLabel(entry.type),
    };
  }

  String _subtitleForEntry(ManipulationEntry entry, AppLocalizations l10n) {
    final parts = <String>[
      DateFormat.yMMMMd().format(entry.appliedAt),
    ];

    if (entry.type == ManipulationType.rerooting &&
        entry.stageBefore != null &&
        entry.stageAfter != null) {
      parts.add(
        l10n.manipulationRerootingStageChange(
          l10n.stageTitle(entry.stageBefore!),
          l10n.stageTitle(entry.stageAfter!),
        ),
      );
    } else if (entry.type == ManipulationType.stimulator &&
        entry.dosage != null &&
        entry.dosage!.trim().isNotEmpty) {
      parts.add(entry.dosage!.trim());
    }

    final note = entry.note?.trim();
    if (note != null && note.isNotEmpty) {
      parts.add(note);
    }

    return parts.join(' · ');
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
                        l10n.manipulationsHistory,
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
                  child: StreamBuilder<List<ManipulationEntry>>(
                    stream: _historyStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: AccessibleProgressIndicator(),
                        );
                      }

                      final items = snapshot.data!;

                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.manipulationEmpty,
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
                          final title = _titleForEntry(item, l10n);
                          final subtitle = _subtitleForEntry(item, l10n);

                          return Semantics(
                            label: '$title. $subtitle',
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
                                    child: Icon(
                                      _iconForType(item.type),
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
                                          subtitle,
                                          maxLines: 3,
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
