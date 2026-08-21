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

class ChangePropagationStageSheet extends StatefulWidget {
  final Propagation propagation;

  const ChangePropagationStageSheet({
    super.key,
    required this.propagation,
  });

  @override
  State<ChangePropagationStageSheet> createState() =>
      _ChangePropagationStageSheetState();
}

class _ChangePropagationStageSheetState
    extends State<ChangePropagationStageSheet> {
  final _service = PropagationService();
  final _noteController = TextEditingController();
  late final TextEditingController _quantityController;

  late int _stage;
  DateTime _changedAt = DateTime.now();
  bool _saving = false;

  static final _stages = stageInfos.where((stage) => stage.value >= 1).toList();

  @override
  void initState() {
    super.initState();
    _stage = widget.propagation.stage.clamp(1, 4);
    _quantityController = TextEditingController(
      text: '${widget.propagation.quantityAlive}',
    );
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
      initialDate: _changedAt,
      firstDate: widget.propagation.startedAt,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _changedAt = dateWithCurrentTime(picked));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final quantityAlive = int.tryParse(_quantityController.text.trim());
    if (quantityAlive == null || quantityAlive < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.propagationAliveRequired)),
      );
      return;
    }
    if (quantityAlive > widget.propagation.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.propagationQuantityExceedsOriginal(
              widget.propagation.quantity,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.changeStage(
        propagationId: widget.propagation.id,
        stage: _stage,
        changedAt: _changedAt,
        quantityAlive: quantityAlive,
        note: _noteController.text.trim(),
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
                    l10n.propagationChangeStage,
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
                      labelText: l10n.propagationAliveNow,
                    ),
                  ),
                  spacing.vMd,
                  Semantics(
                    button: true,
                    label: l10n.a11ySelectDate(
                      DateFormat('d MMM y').format(_changedAt),
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
                                  DateFormat('d MMM y').format(_changedAt),
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
                              child: AccessibleProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                            )
                          : Text(l10n.commonSave),
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
