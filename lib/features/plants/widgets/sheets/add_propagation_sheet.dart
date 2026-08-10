import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/date_time_utils.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../models/propagation_initial_stage.dart';
import '../../../../models/propagation_method.dart';
import '../../../../services/propagation_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

class AddPropagationSheet extends StatefulWidget {
  final String parentPlantId;
  final String parentPlantName;
  final String parentPlantFamily;

  const AddPropagationSheet({
    super.key,
    required this.parentPlantId,
    required this.parentPlantName,
    required this.parentPlantFamily,
  });

  @override
  State<AddPropagationSheet> createState() => _AddPropagationSheetState();
}

class _AddPropagationSheetState extends State<AddPropagationSheet> {
  final _quantityController = TextEditingController(text: '1');
  final _service = PropagationService();

  PropagationMethod _method = PropagationMethod.leaf;
  int _divisionStage = propagationStageBaby;
  DateTime _startedAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startedAt = dateWithCurrentTime(picked));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.propagationQuantityMin)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.addPropagation(
        parentPlantId: widget.parentPlantId,
        parentPlantName: widget.parentPlantName,
        parentPlantFamily: widget.parentPlantFamily,
        method: _method,
        quantity: quantity,
        startedAt: _startedAt,
        divisionStage:
            requiresInitialStageChoice(_method) ? _divisionStage : null,
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
    final showDivisionStage = requiresInitialStageChoice(_method);
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
      child: Padding(
        padding: sheets.contentPadding.copyWith(
          bottom: MediaQuery.of(context).viewInsets.bottom + spacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: const SheetDragHandle()),
              spacing.vXxl,
              Text(
                l10n.propagationStartRooting,
                style: typography.titleLarge.copyWith(
                  letterSpacing: -1,
                ),
              ),
              spacing.vXs,
              Text(
                widget.parentPlantName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typography.bodyLarge.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              spacing.vXxl,
              Text(
                l10n.propagationMethodField,
                style: typography.label.copyWith(color: colors.heading),
              ),
              spacing.vXs,
              Wrap(
                spacing: spacing.xs,
                runSpacing: spacing.xs,
                children: PropagationMethod.values.map((method) {
                  final selected = _method == method;
                  return ChoiceChip(
                    label: Text(l10n.propagationMethodLabel(method)),
                    selected: selected,
                    onSelected: (_) => setState(() => _method = method),
                    selectedColor: colors.primary,
                    backgroundColor: colors.card,
                    labelStyle: typography.label.copyWith(
                      color: selected ? colors.onPrimary : colors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: selected ? colors.primary : colors.outline,
                    ),
                  );
                }).toList(),
              ),
              if (showDivisionStage) ...[
                spacing.vXl,
                Text(
                  l10n.propagationInitialStage,
                  style: typography.label.copyWith(color: colors.heading),
                ),
                spacing.vXxs,
                for (final stage in [
                  propagationStageBaby,
                  propagationStageJuvenile,
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _divisionStage == stage
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _divisionStage == stage
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                    title: Text(
                      l10n.stageTitle(stage),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodyLarge.copyWith(
                        fontWeight: _divisionStage == stage
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: () => setState(() => _divisionStage = stage),
                  ),
              ],
              spacing.vXl,
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: inputs.textStyle,
                decoration: inputs.decoration(
                  labelText: l10n.propagationQuantity,
                ),
              ),
              spacing.vMd,
              Semantics(
                button: true,
                label: l10n.propagationDate(
                  DateFormat('d MMM y').format(_startedAt),
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
                            Icons.calendar_today_outlined,
                            color: colors.icon,
                            size: dimensions.iconLg,
                          ),
                        ),
                        spacing.hSm,
                        Expanded(
                          child: Text(
                            l10n.propagationDate(
                              DateFormat('d MMM y').format(_startedAt),
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
    );
  }
}
