import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/stimulator.dart';
import '../../../../services/stimulator_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

class ManageStimulatorsSheet extends StatefulWidget {
  final void Function(String stimulatorId)? onDeleted;

  const ManageStimulatorsSheet({
    super.key,
    this.onDeleted,
  });

  @override
  State<ManageStimulatorsSheet> createState() => _ManageStimulatorsSheetState();
}

class _StimulatorFormResult {
  final String name;
  final String? defaultDosage;

  const _StimulatorFormResult({
    required this.name,
    this.defaultDosage,
  });
}

class _ManageStimulatorsSheetState extends State<ManageStimulatorsSheet> {
  final _service = StimulatorService();

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final result = await showAppDialog<_StimulatorFormResult>(
      context: context,
      builder: (_) => _StimulatorFormDialog(
        title: l10n.stimulatorAddTitle,
        confirmLabel: l10n.commonAdd,
      ),
    );
    if (result == null) return;

    final existing = await _service.findStimulatorByName(result.name);
    if (existing != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.catalogItemAlreadyExists(result.name))),
      );
      return;
    }

    await _service.addStimulator(
      name: result.name,
      defaultDosage: result.defaultDosage,
    );
  }

  Future<void> _edit(Stimulator stimulator) async {
    final l10n = AppLocalizations.of(context);
    final result = await showAppDialog<_StimulatorFormResult>(
      context: context,
      builder: (_) => _StimulatorFormDialog(
        title: l10n.stimulatorEditTitle,
        confirmLabel: l10n.commonSave,
        initialName: stimulator.name,
        initialDefaultDosage: stimulator.defaultDosage,
      ),
    );
    if (result == null) return;

    final existing = await _service.findStimulatorByName(result.name);
    if (existing != null && existing.id != stimulator.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.catalogItemAlreadyExists(result.name))),
      );
      return;
    }

    await _service.updateStimulator(
      stimulatorId: stimulator.id,
      name: result.name,
      defaultDosage: result.defaultDosage,
    );
  }

  Future<void> _delete(Stimulator stimulator) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.modal,
          title: Text(l10n.manipulationDeleteTitle),
          content: Text(l10n.catalogItemDeleteConfirm(stimulator.name)),
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
    await _service.deleteStimulator(stimulator.id);
    widget.onDeleted?.call(stimulator.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final sheetHeight = MediaQuery.of(context).size.height * 0.7;

    return Material(
      color: colors.modal,
      borderRadius: context.components.sheets.topBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: sheetHeight,
          child: Padding(
            padding: spacing.allMd,
            child: Column(
              children: [
                const SheetDragHandle(),
                spacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.manageStimulatorsTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.titleMedium,
                      ),
                    ),
                    spacing.hXs,
                    FilledButton.icon(
                      onPressed: _add,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.commonAdd),
                    ),
                  ],
                ),
                spacing.vLg,
                Expanded(
                  child: StreamBuilder<List<Stimulator>>(
                    stream: _service.watchStimulators(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: AccessibleProgressIndicator(),
                        );
                      }

                      final items = snapshot.data!;
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.emptyStimulators,
                            style: typography.bodySmall,
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => spacing.vSm,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            padding: spacing.allMd,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(context.radii.md),
                              color: colors.card,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: typography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (item.defaultDosage != null) ...[
                                        spacing.vXxs,
                                        Text(
                                          item.defaultDosage!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: typography.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.commonEdit,
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _edit(item),
                                ),
                                IconButton(
                                  tooltip: l10n.commonDelete,
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
        ),
      ),
    );
  }
}

class _StimulatorFormDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String? initialName;
  final String? initialDefaultDosage;

  const _StimulatorFormDialog({
    required this.title,
    required this.confirmLabel,
    this.initialName,
    this.initialDefaultDosage,
  });

  @override
  State<_StimulatorFormDialog> createState() => _StimulatorFormDialogState();
}

class _StimulatorFormDialogState extends State<_StimulatorFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _dosageController = TextEditingController(
      text: widget.initialDefaultDosage ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      _StimulatorFormResult(
        name: name,
        defaultDosage: _dosageController.text.trim().isEmpty
            ? null
            : _dosageController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inputs = context.components.inputs;

    return AlertDialog(
      backgroundColor: context.colors.modal,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: inputs.decoration(
              labelText: l10n.manipulationStimulatorName,
              hintText: l10n.manipulationStimulatorNameHint,
            ),
            textInputAction: TextInputAction.next,
          ),
          context.spacing.vSm,
          TextField(
            controller: _dosageController,
            decoration: inputs.decoration(
              labelText: l10n.stimulatorDefaultDosage,
              hintText: l10n.manipulationStimulatorDosageHint,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty ? null : _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
