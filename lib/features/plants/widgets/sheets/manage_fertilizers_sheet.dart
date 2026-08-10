import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/fertilizer.dart';
import '../../../../models/fertilizer_dose.dart';
import '../../../../services/fertilize_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

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
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<_FertilizerFormResult>(
      context: context,
      builder: (_) => _FertilizerFormDialog(
        title: l10n.fertilizerPurchasedAddTitle,
        confirmLabel: l10n.commonAdd,
        initialKind: FertilizerKind.purchased,
      ),
    );
    if (result == null) return;

    final existing = await _service.findFertilizerByName(result.name);
    if (existing != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.catalogItemAlreadyExists(result.name))),
      );
      return;
    }

    await _service.addFertilizer(
      name: result.name,
      kind: result.kind,
      waterMl: result.waterMl,
      components: result.components,
    );
  }

  Future<void> _edit(Fertilizer fertilizer) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<_FertilizerFormResult>(
      context: context,
      builder: (_) => _FertilizerFormDialog(
        title: l10n.fertilizerEditTitle,
        confirmLabel: l10n.commonSave,
        initialName: fertilizer.name,
        initialKind: fertilizer.kind,
        initialWaterMl: fertilizer.waterMl,
        initialComponents: fertilizer.components,
      ),
    );
    if (result == null) return;

    final existing = await _service.findFertilizerByName(result.name);
    if (existing != null && existing.id != fertilizer.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.catalogItemAlreadyExists(result.name))),
      );
      return;
    }

    await _service.updateFertilizer(
      fertilizerId: fertilizer.id,
      name: result.name,
      kind: result.kind,
      waterMl: result.waterMl,
      components: result.components,
    );
  }

  Future<void> _delete(Fertilizer fertilizer) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.modal,
          title: Text(l10n.fertilizerDeleteTitle),
          content: Text(l10n.catalogItemDeleteConfirm(fertilizer.name)),
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
    await _service.deleteFertilizer(fertilizer.id);
    widget.onDeleted?.call(fertilizer.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    return SafeArea(
      child: Padding(
        padding: spacing.allLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetDragHandle(),
            spacing.vMd,
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.manageFertilizersTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleMedium,
                  ),
                ),
                spacing.hXs,
                FilledButton.icon(
                  onPressed: _addPurchased,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.fertilizerKindPurchased),
                ),
              ],
            ),
            spacing.vXs,
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.manageFertilizersHint,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: typography.caption.copyWith(color: colors.textSecondary),
              ),
            ),
            spacing.vSm,
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: StreamBuilder<List<Fertilizer>>(
                stream: _service.getFertilizers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: AccessibleProgressIndicator());
                  }

                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Center(child: Text(l10n.emptyFertilizers));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final doseLabel = item.components.isEmpty
                          ? null
                          : item.components
                              .map((c) => l10n.fertilizerDoseLabel(c))
                              .join(', ');

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            l10n.fertilizerKindLabel(item.kind),
                            l10n.unitMlWithValue(item.waterMl),
                            if (doseLabel != null) doseLabel,
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.commonEdit,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(item),
                            ),
                            IconButton(
                              tooltip: l10n.commonDelete,
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
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.fieldRequired);
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
            SnackBar(content: Text(l10n.fertilizerInvalidDose)),
          );
          return;
        }
        components.add(
          FertilizerDose(
            component: _kind == FertilizerKind.purchased
                ? 'dose'
                : (widget.initialComponents.isNotEmpty
                    ? widget.initialComponents.first.component
                    : 'dose'),
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
    final l10n = AppLocalizations.of(context);
    final isPurchased = _kind == FertilizerKind.purchased;
    final showSimpleDose = isPurchased || widget.initialComponents.length <= 1;
    final spacing = context.spacing;
    final inputs = context.components.inputs;
    final typography = context.typography;

    return AlertDialog(
      backgroundColor: context.colors.modal,
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
              decoration: inputs
                  .decoration(
                    labelText: l10n.fertilizerNameLabel,
                    hintText: isPurchased
                        ? l10n.fertilizerNameHint
                        : l10n.fertilizingMixNameHint,
                  )
                  .copyWith(errorText: _nameError),
            ),
            spacing.vMd,
            Text(
              l10n.fertilizerKindSection,
              style: typography.label.copyWith(fontWeight: FontWeight.w600),
            ),
            spacing.vXs,
            SegmentedButton<FertilizerKind>(
              segments: [
                ButtonSegment(
                  value: FertilizerKind.purchased,
                  label: Text(l10n.fertilizerKindPurchased),
                ),
                ButtonSegment(
                  value: FertilizerKind.mix,
                  label: Text(l10n.fertilizerKindMix),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) {
                setState(() => _kind = value.first);
              },
            ),
            spacing.vMd,
            Text(
              l10n.fertilizerWaterForDilution,
              style: typography.label.copyWith(fontWeight: FontWeight.w600),
            ),
            spacing.vXs,
            SegmentedButton<int>(
              segments: [
                for (final ml in kWaterVolumesMl)
                  ButtonSegment(
                    value: ml,
                    label: Text(l10n.unitMlWithValue(ml)),
                  ),
              ],
              selected: {_waterMl},
              onSelectionChanged: (value) {
                setState(() => _waterMl = value.first);
              },
            ),
            if (showSimpleDose) ...[
              spacing.vMd,
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
                selected: {_doseUnit},
                onSelectionChanged: (value) {
                  setState(() => _doseUnit = value.first);
                },
              ),
              spacing.vSm,
              TextField(
                controller: _doseController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: inputs.decoration(
                  labelText: isPurchased
                      ? l10n.fertilizerDoseOnWaterOptional(_waterMl)
                      : l10n.fertilizerDoseOptional,
                  hintText: l10n.fertilizerDoseHint,
                ),
              ),
            ] else ...[
              spacing.vSm,
              Text(
                l10n.fertilizerMixComposition(
                  widget.initialComponents
                      .map((c) => l10n.fertilizerDoseLabel(c))
                      .join(', '),
                ),
                style: typography.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
