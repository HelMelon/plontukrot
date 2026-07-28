import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/propagation_method.dart';
import '../../../../services/propagation_service.dart';

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
      setState(() => _startedAt = picked);
    }
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите количество (минимум 1)')),
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
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Поставить на укоренение',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.parentPlantName,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Способ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PropagationMethod.values.map((method) {
                  final selected = _method == method;
                  return ChoiceChip(
                    label: Text(method.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _method = method),
                    selectedColor: AppColors.goldAccent,
                    backgroundColor: AppColors.dark2,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.dark1
                          : AppColors.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.goldAccent
                          : AppColors.greenDeep,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Количество',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.dark2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.greenDeep),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: AppColors.goldAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dark2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.greenDeep),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.accentLight,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Дата: ${DateFormat('d MMM y').format(_startedAt)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: AppColors.dark1,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.dark1,
                          ),
                        )
                      : const Text(
                          'Сохранить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
