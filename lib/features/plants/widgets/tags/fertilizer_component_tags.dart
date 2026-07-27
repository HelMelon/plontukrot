import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/fertilizer_dose.dart';

Future<FertilizerDose?> showFertilizerDoseDialog({
  required BuildContext context,
  required String component,
  FertilizerDose? initial,
}) async {
  var unit = initial?.unit ?? FertilizerDoseUnit.g;
  final amountController = TextEditingController(
    text: initial == null
        ? ''
        : (initial.amount == initial.amount.roundToDouble()
            ? initial.amount.toInt().toString()
            : initial.amount.toString()),
  );

  final result = await showDialog<FertilizerDose>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.backgroundSecondary,
            title: Text(component),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<FertilizerDoseUnit>(
                  segments: const [
                    ButtonSegment(
                      value: FertilizerDoseUnit.g,
                      label: Text('g'),
                    ),
                    ButtonSegment(
                      value: FertilizerDoseUnit.ml,
                      label: Text('ml'),
                    ),
                  ],
                  selected: {unit},
                  onSelectionChanged: (value) {
                    setDialogState(() => unit = value.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: unit == FertilizerDoseUnit.ml
                        ? 'Milliliters'
                        : 'Grams',
                    hintText: 'e.g. 2',
                  ),
                ),
              ],
            ),
            actions: [
              if (initial != null)
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    FertilizerDose(
                      component: component,
                      amount: -1,
                      unit: unit,
                    ),
                  ),
                  child: const Text('Remove'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final raw =
                      amountController.text.trim().replaceAll(',', '.');
                  final amount = double.tryParse(raw);
                  if (amount == null || amount <= 0) return;
                  Navigator.pop(
                    context,
                    FertilizerDose(
                      component: component,
                      amount: amount,
                      unit: unit,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  amountController.dispose();
  return result;
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

  Widget _addButton() {
    return GestureDetector(
      onTap: onAddCustom,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.sage),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: AppColors.heading),
            SizedBox(width: 4),
            Text('Add', style: TextStyle(color: AppColors.heading)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...availableComponents.map((name) {
          final selectedDose = _find(name);
          final isSelected = selectedDose != null;

          return GestureDetector(
            onTap: () => _onTap(context, name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.goldAccent.withValues(alpha: 0.25)
                    : AppColors.greenDeep,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppColors.goldAccent : AppColors.greenSoft,
                ),
              ),
              child: Text(
                isSelected ? selectedDose.label : name,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
        if (onAddCustom != null) _addButton(),
      ],
    );
  }
}
