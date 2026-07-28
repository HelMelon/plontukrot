import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
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
    final raw = _amountController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) {
      setState(() => _errorText = 'Укажите количество');
      return;
    }
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Некорректное число');
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
    return AlertDialog(
      backgroundColor: AppColors.backgroundSecondary,
      title: Text(widget.component),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<FertilizerDoseUnit>(
            segments: const [
              ButtonSegment(
                value: FertilizerDoseUnit.g,
                label: Text('г'),
              ),
              ButtonSegment(
                value: FertilizerDoseUnit.ml,
                label: Text('мл'),
              ),
            ],
            selected: {_unit},
            onSelectionChanged: (value) {
              setState(() => _unit = value.first);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText:
                  _unit == FertilizerDoseUnit.ml ? 'Миллилитры' : 'Граммы',
              hintText: 'напр. 2',
              errorText: _errorText,
            ),
          ),
        ],
      ),
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
            child: const Text('Убрать'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Сохранить'),
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
            Text('Добавить', style: TextStyle(color: AppColors.heading)),
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
