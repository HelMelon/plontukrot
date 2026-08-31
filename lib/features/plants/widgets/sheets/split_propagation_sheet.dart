import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/date_time_utils.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../models/propagation.dart';
import '../../../../models/stage_info.dart';
import '../../../../services/propagation_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

class SplitPropagationSheet extends StatefulWidget {
  final Propagation propagation;

  const SplitPropagationSheet({
    super.key,
    required this.propagation,
  });

  @override
  State<SplitPropagationSheet> createState() => _SplitPropagationSheetState();
}

class _SplitPropagationSheetState extends State<SplitPropagationSheet> {
  final _service = PropagationService();
  final _noteController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  late int _stage;
  DateTime _splitAt = DateTime.now();
  bool _saving = false;

  static final _stages = stageInfos.where((stage) => stage.value >= 1).toList();

  static StageInfo _stageInfo(int value) {
    return stageInfos.firstWhere(
      (stage) => stage.value == value,
      orElse: () => stageInfos[1],
    );
  }

  @override
  void initState() {
    super.initState();
    _stage = (widget.propagation.stage < 4
            ? widget.propagation.stage + 1
            : widget.propagation.stage)
        .clamp(1, 4);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _splitAt,
      firstDate: widget.propagation.startedAt,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _splitAt = dateWithCurrentTime(picked));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final countToSplit = int.tryParse(_quantityController.text.trim());
    if (countToSplit == null || countToSplit < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.propagationSplitQuantityMin)),
      );
      return;
    }

    final maxSplit = widget.propagation.quantityAlive - 1;
    if (countToSplit > maxSplit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.propagationSplitQuantityMax(maxSplit)),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final userNote = _noteController.text.trim();
      final stageTitle = l10n.stageInfoTitle(_stageInfo(_stage));
      final sourceNote = userNote.isNotEmpty
          ? '${l10n.propagationSplitSourceNote(countToSplit, stageTitle)} · $userNote'
          : l10n.propagationSplitSourceNote(countToSplit, stageTitle);
      final batchDate = DateFormat('d MMM y').format(widget.propagation.startedAt);
      final newBatchNote = userNote.isNotEmpty
          ? '${l10n.propagationSplitNewBatchNote(batchDate)} · $userNote'
          : l10n.propagationSplitNewBatchNote(batchDate);

      await _service.splitPropagation(
        sourcePropagationId: widget.propagation.id,
        countToSplit: countToSplit,
        newStage: _stage,
        splitAt: _splitAt,
        sourceNote: sourceNote,
        newBatchNote: newBatchNote,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final maxHeight =
        (media.size.height - keyboard - 72).clamp(160.0, media.size.height);
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final sheets = context.components.sheets;
    final inputs = context.components.inputs;
    final typography = context.typography;
    final dimensions = context.dimensions;

    return Container(
      decoration: BoxDecoration(
        color: colors.modal,
        borderRadius: sheets.topBorderRadius,
      ),
      child: SafeArea(
        child: Padding(
          padding: sheets.contentPadding.copyWith(
            bottom: spacing.xl + keyboard,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: const SheetDragHandle()),
                  spacing.vXxl,
                  Text(
                    l10n.propagationSplitTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleLarge.copyWith(
                      letterSpacing: -1,
                    ),
                  ),
                  spacing.vXs,
                  Text(
                    '${l10n.propagationAliveWithMethod(widget.propagation.quantityAlive, l10n.propagationMethodPlural(widget.propagation.method))} · ${widget.propagation.parentPlantName}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodyLarge.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  spacing.vXl,
                  Text(
                    l10n.propagationSplitNewStage,
                    style: typography.label.copyWith(color: colors.heading),
                  ),
                  spacing.vXs,
                  ..._stages.map((stage) {
                    final selected = _stage == stage.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        selected
                            ? context.icons.radioChecked
                            : context.icons.radioUnchecked,
                        color: selected ? colors.primary : colors.textSecondary,
                      ),
                      title: Text(
                        l10n.stageInfoTitle(stage),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.bodyLarge.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onTap: () => setState(() => _stage = stage.value),
                    );
                  }),
                  spacing.vXs,
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: inputs.textStyle,
                    decoration: inputs.decoration(
                      labelText: l10n.propagationSplitQuantity,
                    ),
                  ),
                  spacing.vMd,
                  Semantics(
                    button: true,
                    label: l10n.a11ySelectDate(
                      DateFormat('d MMM y').format(_splitAt),
                    ),
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(radii.lg),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.md,
                          vertical: spacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(radii.lg),
                          border: Border.all(color: colors.outline),
                        ),
                        child: Row(
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                context.icons.calendarOutlined,
                                color: colors.icon,
                                size: dimensions.iconLg,
                              ),
                            ),
                            spacing.hSm,
                            Expanded(
                              child: Text(
                                l10n.propagationDate(
                                  DateFormat('d MMM y').format(_splitAt),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.bodyLarge.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  spacing.vMd,
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    style: inputs.textStyle,
                    decoration: inputs.decoration(
                      labelText: l10n.notesOptional,
                    ),
                  ),
                  spacing.vXxxl,
                  SizedBox(
                    width: double.infinity,
                    height: dimensions.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? SizedBox(
                              width: dimensions.iconXl,
                              height: dimensions.iconXl,
                              child: AccessibleProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Text(l10n.propagationSplit),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
