import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/fertilizer.dart';
import '../../../../models/fertilizer_dose.dart';
import '../../../../services/fertilize_service.dart';

class ManageFertilizersSheet extends StatefulWidget {
  final void Function(String fertilizerId)? onDeleted;

  const ManageFertilizersSheet({
    super.key,
    this.onDeleted,
  });

  @override
  State<ManageFertilizersSheet> createState() => _ManageFertilizersSheetState();
}

class _ManageFertilizersSheetState extends State<ManageFertilizersSheet> {
  final _service = FertilizeService();

  Future<void> _addPurchased() async {
    final result = await showDialog<_FertilizerFormResult>(
      context: context,
      builder: (_) => const _FertilizerFormDialog(
        title: 'Готовое удобрение',
        confirmLabel: 'Добавить',
        initialKind: FertilizerKind.purchased,
      ),
    );
    if (result == null) return;

    await _service.addFertilizer(
      name: result.name,
      kind: result.kind,
      waterMl: result.waterMl,
      components: result.components,
    );
  }

  Future<void> _edit(Fertilizer fertilizer) async {
    final result = await showDialog<_FertilizerFormResult>(
      context: context,
      builder: (_) => _FertilizerFormDialog(
        title: 'Изменить удобрение',
        confirmLabel: 'Сохранить',
        initialName: fertilizer.name,
        initialKind: fertilizer.kind,
        initialWaterMl: fertilizer.waterMl,
        initialComponents: fertilizer.components,
      ),
    );
    if (result == null) return;

    await _service.updateFertilizer(
      fertilizerId: fertilizer.id,
      name: result.name,
      kind: result.kind,
      waterMl: result.waterMl,
      components: result.components,
    );
  }

  Future<void> _delete(Fertilizer fertilizer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: const Text('Удалить удобрение'),
          content: Text(
            'Удалить «${fertilizer.name}» из каталога?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await _service.deleteFertilizer(fertilizer.id);
    widget.onDeleted?.call(fertilizer.id);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Удобрения',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _addPurchased,
                  icon: const Icon(Icons.add),
                  label: const Text('Готовое'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Миксы сохраняются из «Новый микс». Вид можно менять: готовое ↔ микс.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: StreamBuilder<List<Fertilizer>>(
                stream: _service.getFertilizers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Пока нет удобрений'),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final doseLabel = item.components.isEmpty
                          ? null
                          : item.components.map((c) => c.label).join(', ');

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            item.kind.label,
                            '${item.waterMl} мл',
                            if (doseLabel != null) doseLabel,
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Изменить',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(item),
                            ),
                            IconButton(
                              tooltip: 'Удалить',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(item),
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
    );
  }
}

class _FertilizerFormResult {
  final String name;
  final FertilizerKind kind;
  final int waterMl;
  final List<FertilizerDose> components;

  const _FertilizerFormResult({
    required this.name,
    required this.kind,
    required this.waterMl,
    required this.components,
  });
}

class _FertilizerFormDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialName;
  final FertilizerKind initialKind;
  final int initialWaterMl;
  final List<FertilizerDose> initialComponents;

  const _FertilizerFormDialog({
    required this.title,
    required this.confirmLabel,
    this.initialName = '',
    this.initialKind = FertilizerKind.purchased,
    this.initialWaterMl = 250,
    this.initialComponents = const [],
  });

  @override
  State<_FertilizerFormDialog> createState() => _FertilizerFormDialogState();
}

class _FertilizerFormDialogState extends State<_FertilizerFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late FertilizerKind _kind;
  late int _waterMl;
  late FertilizerDoseUnit _doseUnit;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _kind = widget.initialKind;
    _waterMl = normalizeWaterMl(widget.initialWaterMl);

    final firstDose = widget.initialComponents.isNotEmpty
        ? widget.initialComponents.first
        : null;
    _doseUnit = firstDose?.unit ?? FertilizerDoseUnit.g;
    _doseController = TextEditingController(
      text: firstDose == null
          ? ''
          : (firstDose.amount == firstDose.amount.roundToDouble()
              ? firstDose.amount.toInt().toString()
              : firstDose.amount.toString()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Укажите название');
      return;
    }

    final doseRaw = _doseController.text.trim().replaceAll(',', '.');
    final components = <FertilizerDose>[];
    final showSimpleDose = _kind == FertilizerKind.purchased ||
        widget.initialComponents.length <= 1;

    if (showSimpleDose) {
      if (doseRaw.isNotEmpty) {
        final amount = double.tryParse(doseRaw);
        if (amount == null || amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Некорректная доза')),
          );
          return;
        }
        components.add(
          FertilizerDose(
            component: _kind == FertilizerKind.purchased
                ? 'Доза'
                : (widget.initialComponents.isNotEmpty
                    ? widget.initialComponents.first.component
                    : 'Доза'),
            amount: amount,
            unit: _doseUnit,
          ),
        );
      }
    } else {
      components.addAll(widget.initialComponents);
    }

    Navigator.pop(
      context,
      _FertilizerFormResult(
        name: name,
        kind: _kind,
        waterMl: _waterMl,
        components: components,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPurchased = _kind == FertilizerKind.purchased;
    final showSimpleDose = isPurchased || widget.initialComponents.length <= 1;

    return AlertDialog(
      backgroundColor: AppColors.backgroundSecondary,
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                labelText: 'Название',
                hintText:
                    isPurchased ? 'напр. Pokon Universal' : 'Название микса',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Вид',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<FertilizerKind>(
              segments: const [
                ButtonSegment(
                  value: FertilizerKind.purchased,
                  label: Text('Готовое'),
                ),
                ButtonSegment(
                  value: FertilizerKind.mix,
                  label: Text('Микс'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) {
                setState(() => _kind = value.first);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Вода для разведения',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                for (final ml in kWaterVolumesMl)
                  ButtonSegment(value: ml, label: Text('$ml мл')),
              ],
              selected: {_waterMl},
              onSelectionChanged: (value) {
                setState(() => _waterMl = value.first);
              },
            ),
            if (showSimpleDose) ...[
              const SizedBox(height: 16),
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
                selected: {_doseUnit},
                onSelectionChanged: (value) {
                  setState(() => _doseUnit = value.first);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _doseController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: isPurchased
                      ? 'Доза на $_waterMl мл (необязательно)'
                      : 'Доза (необязательно)',
                  hintText: 'напр. 2',
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Состав микса: ${widget.initialComponents.map((c) => c.label).join(', ')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
