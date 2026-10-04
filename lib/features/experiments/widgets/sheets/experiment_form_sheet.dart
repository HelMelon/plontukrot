import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/accessible_progress_indicator.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';
import '../../../../models/experiment.dart';
import '../../../../services/experiment_service.dart';
import '../variant_draft.dart';
import '../_variant_draft_row.dart';

/// Create or edit an experiment. Variants are edited inline here; participants
/// and observations are added later from the details page, so a new experiment
/// can be saved with just a title and one variant.
class ExperimentFormSheet extends StatefulWidget {
  final Experiment? experiment;

  const ExperimentFormSheet({super.key, this.experiment});

  @override
  State<ExperimentFormSheet> createState() => _ExperimentFormSheetState();
}

class _ExperimentFormSheetState extends State<ExperimentFormSheet> {
  final _service = ExperimentService();
  final _titleController = TextEditingController();
  final _hypothesisController = TextEditingController();
  final _noteController = TextEditingController();
  final _variants = <VariantDraft>[];

  late DateTime _startedAt = widget.experiment?.startedAt ?? DateTime.now();
  bool _isSaving = false;
  String? _titleError;
  String? _variantError;

  bool get _isEditing => widget.experiment != null;

  @override
  void initState() {
    super.initState();
    final experiment = widget.experiment;
    if (experiment != null) {
      _titleController.text = experiment.title;
      _hypothesisController.text = experiment.hypothesis ?? '';
      _noteController.text = experiment.note ?? '';
      for (final variant in experiment.variants) {
        _variants.add(VariantDraft.fromVariant(variant));
      }
    }
    if (_variants.isEmpty) _variants.add(VariantDraft.empty());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hypothesisController.dispose();
    _noteController.dispose();
    for (final variant in _variants) {
      variant.dispose();
    }
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _startedAt = picked);
  }

  void _addVariant() {
    setState(() {
      _variants.add(VariantDraft.empty());
      _variantError = null;
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index).dispose();
    });
  }

  Future<bool> _confirmDeleteVariant(String label) async {
    final l10n = AppLocalizations.of(context);
    final result = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text(label),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final filledVariants = _variants
        .where((variant) => variant.label.text.trim().isNotEmpty)
        .toList();

    if (title.isEmpty) {
      setState(() => _titleError = l10n.experimentsTitleRequired);
      return;
    }
    if (filledVariants.isEmpty) {
      setState(() => _variantError = l10n.experimentsVariantRequired);
      return;
    }

    setState(() {
      _isSaving = true;
      _titleError = null;
      _variantError = null;
    });

    try {
      if (_isEditing) {
        await _updateExisting(title, filledVariants);
      } else {
        await _service.createExperiment(
          title: title,
          hypothesis: _trimmedOrNull(_hypothesisController.text),
          note: _trimmedOrNull(_noteController.text),
          startedAt: _startedAt,
          variants: filledVariants
              .map((variant) => variant.toCreatePayload())
              .toList(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(error.toString()))),
      );
    }
  }

  /// Persist edits: header + per-variant create/update/delete diffing.
  Future<void> _updateExisting(String title, List<VariantDraft> filled) async {
    final experiment = widget.experiment!;
    await _service.updateExperiment(
      experimentId: experiment.id,
      title: title,
      hypothesis: _hypothesisController.text.trim(),
      note: _noteController.text.trim(),
      startedAt: _startedAt,
    );
    final keptIds = filled.map((variant) => variant.id).toSet();
    for (final variant in filled) {
      if (variant.id == null) {
        await _service.addVariant(
          experimentId: experiment.id,
          label: variant.label.text.trim(),
          description: variant.description.text.trim(),
        );
      } else {
        await _service.updateVariant(
          variantId: variant.id!,
          label: variant.label.text.trim(),
          description: variant.description.text.trim(),
        );
      }
    }
    for (final variant in experiment.variants) {
      if (!keptIds.contains(variant.id)) {
        await _service.deleteVariant(variant.id);
      }
    }
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final inputs = context.components.inputs;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final sheetHeight = (media.size.height - media.padding.top - keyboard) * 0.94;
    final dateLabel = DateFormat('d MMM y').format(_startedAt);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: sheetHeight,
        child: Container(
          decoration: BoxDecoration(
            color: colors.modal,
            borderRadius: sheets.topBorderRadius,
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const SheetDragHandle(),
              Expanded(
                child: ListView(
                  padding: sheets.contentPadding,
                  children: [
                    Text(
                      _isEditing
                          ? l10n.experimentsEditTitle
                          : l10n.experimentsCreateTitle,
                      style: typography.titleLarge.copyWith(letterSpacing: -1),
                    ),
                    spacing.vLg,
                    TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      style: inputs.textStyle,
                      onChanged: (_) {
                        if (_titleError != null) {
                          setState(() => _titleError = null);
                        }
                      },
                      decoration: inputs
                          .decoration(
                            labelText: l10n.experimentsFieldTitle,
                            hintText: l10n.experimentsTitleHint,
                          )
                          .copyWith(errorText: _titleError),
                    ),
                    spacing.vMd,
                    TextField(
                      controller: _hypothesisController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLines: 2,
                      style: inputs.textStyle,
                      decoration: inputs.decoration(
                        labelText: l10n.experimentsFieldHypothesis,
                        hintText: l10n.experimentsHypothesisHint,
                      ),
                    ),
                    spacing.vMd,
                    TextField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      style: inputs.textStyle,
                      decoration: inputs.decoration(
                        labelText: l10n.experimentsFieldNote,
                      ),
                    ),
                    spacing.vMd,
                    Semantics(
                      button: true,
                      label: l10n.a11ySelectDate(dateLabel),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ExcludeSemantics(
                          child: Icon(context.icons.calendar),
                        ),
                        title: Text(l10n.experimentsStartDate),
                        subtitle: Text(dateLabel),
                        onTap: _pickStartDate,
                      ),
                    ),
                    spacing.vLg,
                    Text(
                      l10n.experimentsVariantsSection,
                      style: typography.titleMedium,
                    ),
                    spacing.vXs,
                    Text(
                      l10n.experimentsVariantsHint,
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    spacing.vMd,
                    for (var i = 0; i < _variants.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: spacing.md),
                        child: VariantDraftRow(
                          key: ObjectKey(_variants[i]),
                          draft: _variants[i],
                          index: i,
                          canRemove: _variants.length > 1,
                          onRemove: () => _removeVariant(i),
                          onChanged: () {
                            if (_variantError != null) {
                              setState(() => _variantError = null);
                            }
                          },
                          onRemoveExisting: () async {
                            final label = _variants[i].label.text.trim();
                            return _confirmDeleteVariant(label);
                          },
                        ),
                      ),
                    if (_variantError != null) ...[
                      spacing.vXs,
                      Text(
                        _variantError!,
                        style: inputs.errorStyle,
                      ),
                    ],
                    spacing.vSm,
                    OutlinedButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.experimentsAddVariant),
                    ),
                    spacing.vXl,
                    SizedBox(
                      width: double.infinity,
                      height: dimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? SizedBox(
                                width: dimensions.iconXl,
                                height: dimensions.iconXl,
                                child: AccessibleProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : Text(l10n.commonSave),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
