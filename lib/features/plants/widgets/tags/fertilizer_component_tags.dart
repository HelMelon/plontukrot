import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/fertilizer_dose.dart';

Future<FertilizerDose?> showFertilizerDoseDialog({
  required BuildContext context,
  required String component,
  FertilizerDose? initial,
}) {
  return showDialog<FertilizerDose>(
    context: context,
    builder: (context) => _FertilizerDoseDialog(
      component: component,
      initial: initial,
    ),
  );
}

class _FertilizerDoseDialog extends StatefulWidget {
  final String component;
  final FertilizerDose? initial;

  const _FertilizerDoseDialog({
    required this.component,
    required this.initial,
  });

  @override
  State<_FertilizerDoseDialog> createState() => _FertilizerDoseDialogState();
}

class _FertilizerDoseDialogState extends State<_FertilizerDoseDialog> {
  late FertilizerDoseUnit _unit;
  late final TextEditingController _amountController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _unit = initial?.unit ?? FertilizerDoseUnit.g;
    _amountController = TextEditingController(
      text: initial == null
          ? ''
          : (initial.amount == initial.amount.roundToDouble()
              ? initial.amount.toInt().toString()
              : initial.amount.toString()),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final raw = _amountController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) {
      setState(() => _errorText = l10n.doseAmountRequired);
      return;
    }
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      setState(() => _errorText = l10n.doseInvalidNumber);
      return;
    }
    Navigator.pop(
      context,
      FertilizerDose(
        component: widget.component,
        amount: amount,
        unit: _unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dialogs = context.components.dialogs;
    final spacing = context.spacing;

    return AlertDialog(
      backgroundColor: dialogs.background,
      title: Text(
        widget.component,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: dialogs.titleStyle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<FertilizerDoseUnit>(
              segments: [
                ButtonSegment(
                  value: FertilizerDoseUnit.g,
                  label: Text(l10n.unitGrams),
                ),
                ButtonSegment(
                  value: FertilizerDoseUnit.ml,
                  label: Text(l10n.unitMl),
                ),
              ],
              selected: {_unit},
              onSelectionChanged: (value) {
                setState(() => _unit = value.first);
              },
            ),
            spacing.vMd,
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (value) {
                if (_errorText != null) setState(() => _errorText = null);
                // After typing 0, append a decimal point so doses like 0.5
                // are easy to enter without switching to the punctuation key.
                if (value == '0') {
                  _amountController.value = const TextEditingValue(
                    text: '0.',
                    selection: TextSelection.collapsed(offset: 2),
                  );
                }
              },
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: _unit == FertilizerDoseUnit.ml
                    ? l10n.milliliters
                    : l10n.grams,
                hintText: l10n.fertilizerDoseHint,
                errorText: _errorText,
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: spacing.xs,
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              FertilizerDose(
                component: widget.component,
                amount: -1,
                unit: _unit,
              ),
            ),
            child: Text(l10n.doseRemove),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class FertilizerComponentTags extends StatelessWidget {
  final List<String> availableComponents;
  final List<FertilizerDose> selected;
  final ValueChanged<List<FertilizerDose>> onChanged;
  final VoidCallback? onAddCustom;

  const FertilizerComponentTags({
    super.key,
    required this.availableComponents,
    required this.selected,
    required this.onChanged,
    this.onAddCustom,
  });

  FertilizerDose? _find(String name) {
    for (final c in selected) {
      if (c.component == name) return c;
    }
    return null;
  }

  Future<void> _onTap(BuildContext context, String name) async {
    final existing = _find(name);
    final dose = await showFertilizerDoseDialog(
      context: context,
      component: name,
      initial: existing,
    );

    if (dose == null) return;

    if (dose.amount < 0) {
      onChanged(selected.where((c) => c.component != name).toList());
      return;
    }

    final next = List<FertilizerDose>.from(selected);
    final index = next.indexWhere((c) => c.component == name);
    if (index >= 0) {
      next[index] = dose;
    } else {
      next.add(dose);
    }
    onChanged(next);
  }

  Widget _addButton(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;
    final typography = context.typography;
    final catalog = context.screens.catalogBuilder;
    final spacing = context.spacing;
    final dimensions = context.dimensions;
    return GestureDetector(
      onTap: onAddCustom,
      child: Container(
        padding: catalog.tagPadding,
        decoration: BoxDecoration(
          color: colors.modal,
          borderRadius: BorderRadius.circular(catalog.tagRadius),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: dimensions.iconSm, color: colors.icon),
            spacing.hXxs,
            Text(
              l10n.commonAdd,
              style: typography.label.copyWith(color: colors.heading),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final catalog = context.screens.catalogBuilder;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chipMaxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return Wrap(
          spacing: spacing.xs,
          runSpacing: spacing.xs,
          children: [
            ...availableComponents.map((name) {
              final selectedDose = _find(name);
              final isSelected = selectedDose != null;

              return GestureDetector(
                onTap: () => _onTap(context, name),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: chipMaxWidth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: catalog.tagPadding,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.25)
                          : colors.outline,
                      borderRadius: BorderRadius.circular(catalog.tagRadius),
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.divider,
                      ),
                    ),
                    child: Text(
                      isSelected
                          ? l10n.fertilizerDoseLabel(selectedDose)
                          : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.label.copyWith(
                        color: isSelected ? colors.primary : colors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (onAddCustom != null) _addButton(context, l10n),
          ],
        );
      },
    );
  }
}
