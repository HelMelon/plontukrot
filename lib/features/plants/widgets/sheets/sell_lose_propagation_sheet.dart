import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/propagation.dart';
import '../../../../services/propagation_service.dart';

class SellPropagationSheet extends StatefulWidget {
  final Propagation propagation;

  const SellPropagationSheet({super.key, required this.propagation});

  @override
  State<SellPropagationSheet> createState() => _SellPropagationSheetState();
}

class _SellPropagationSheetState extends State<SellPropagationSheet> {
  final _service = PropagationService();
  final _noteController = TextEditingController();
  late final TextEditingController _quantityController;

  DateTime _soldAt = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: '${widget.propagation.quantityAlive}',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _soldAt,
      firstDate: widget.propagation.startedAt,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _soldAt = picked);
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите количество для продажи')),
      );
      return;
    }
    if (quantity > widget.propagation.quantityAlive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не больше ${widget.propagation.quantityAlive} живых',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.sell(
        propagationId: widget.propagation.id,
        quantity: quantity,
        soldAt: _soldAt,
        note: _noteController.text.trim(),
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
    return _QuantityActionSheet(
      title: 'Продать',
      subtitle:
          '${widget.propagation.quantityAlive} живых · ${widget.propagation.parentPlantName}',
      quantityController: _quantityController,
      quantityLabel: 'Сколько продать',
      date: _soldAt,
      onPickDate: _pickDate,
      noteController: _noteController,
      saving: _saving,
      onSave: _save,
      buttonLabel: 'Продать',
    );
  }
}

class LosePropagationSheet extends StatefulWidget {
  final Propagation propagation;

  const LosePropagationSheet({super.key, required this.propagation});

  @override
  State<LosePropagationSheet> createState() => _LosePropagationSheetState();
}

class _LosePropagationSheetState extends State<LosePropagationSheet> {
  final _service = PropagationService();
  final _noteController = TextEditingController();
  late final TextEditingController _quantityController;

  DateTime _lostAt = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: '${widget.propagation.quantityAlive}',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lostAt,
      firstDate: widget.propagation.startedAt,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _lostAt = picked);
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите количество')),
      );
      return;
    }
    if (quantity > widget.propagation.quantityAlive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не больше ${widget.propagation.quantityAlive} живых',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.markLost(
        propagationId: widget.propagation.id,
        quantity: quantity,
        lostAt: _lostAt,
        note: _noteController.text.trim(),
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
    return _QuantityActionSheet(
      title: 'Погибло',
      subtitle:
          '${widget.propagation.quantityAlive} живых · ${widget.propagation.parentPlantName}',
      quantityController: _quantityController,
      quantityLabel: 'Сколько погибло',
      date: _lostAt,
      onPickDate: _pickDate,
      noteController: _noteController,
      saving: _saving,
      onSave: _save,
      buttonLabel: 'Списать',
    );
  }
}

class _QuantityActionSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController quantityController;
  final String quantityLabel;
  final DateTime date;
  final VoidCallback onPickDate;
  final TextEditingController noteController;
  final bool saving;
  final VoidCallback onSave;
  final String buttonLabel;

  const _QuantityActionSheet({
    required this.title,
    required this.subtitle,
    required this.quantityController,
    required this.quantityLabel,
    required this.date,
    required this.onPickDate,
    required this.noteController,
    required this.saving,
    required this.onSave,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final maxHeight =
        (media.size.height - keyboard - 72).clamp(160.0, media.size.height);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 22, 22, 24 + keyboard),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
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
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: quantityLabel,
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.dark2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: AppColors.greenDeep),
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
                    onTap: onPickDate,
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
                          Expanded(
                            child: Text(
                              'Дата: ${DateFormat('d MMM y').format(date)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Заметка (необязательно)',
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.dark2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: AppColors.greenDeep),
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
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: AppTheme.buttonHeight,
                    child: ElevatedButton(
                      onPressed: saving ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldAccent,
                        foregroundColor: AppColors.dark1,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.dark1,
                              ),
                            )
                          : Text(
                              buttonLabel,
                              style: const TextStyle(
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
        ),
      ),
    );
  }
}
