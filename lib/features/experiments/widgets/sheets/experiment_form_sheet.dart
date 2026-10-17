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
    // Commit the focused field before the list rebuilds. The first variant is
    // the one on screen when the user taps "add", and that rebuild was
    // dropping its description while later rows (typed after the rebuild)
    // kept theirs.
    _commitFocusedField();
    final snapshots = _snapshotVariantText();
    setState(() {
      _variants.add(VariantDraft.empty());
      _variantError = null;
    });
    _restoreVariantText(snapshots);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _restoreVariantText(snapshots);
    });
  }

  /// Unfocus so the IME writes into the controller, then put back any text
  /// that unfocus itself cleared.
  void _commitFocusedField() {
    final title = _titleController.text;
    final hypothesis = _hypothesisController.text;
    final note = _noteController.text;
    final variants = _snapshotVariantText();
    FocusManager.instance.primaryFocus?.unfocus();
    if (title.isNotEmpty && _titleController.text.isEmpty) {
      _titleController.text = title;
    }
    if (hypothesis.isNotEmpty && _hypothesisController.text.isEmpty) {
      _hypothesisController.text = hypothesis;
    }
    if (note.isNotEmpty && _noteController.text.isEmpty) {
      _noteController.text = note;
    }
    _restoreVariantText(variants);
  }

  List<({String label, String description})> _snapshotVariantText() {
    return [
      for (final variant in _variants)
        (label: variant.label.text, description: variant.description.text),
    ];
  }

  void _restoreVariantText(
    List<({String label, String description})> snapshots,
  ) {
    for (var i = 0; i < snapshots.length && i < _variants.length; i++) {
      _variants[i].restoreIfCleared(
        label: snapshots[i].label,
        description: snapshots[i].description,
      );
    }
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
    _commitFocusedField();
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
        final payloads = <Map<String, dynamic>>[];
        for (final variant in filledVariants) {
          // Read the text before the photo upload. The await can rebuild the
          // sheet and wipe the focused field — that was dropping the first
          // variant's description.
          final payload = variant.toCreatePayload();
          final imageUrl = await _imageUrlForSave(variant);
          if (imageUrl != null && imageUrl.trim().isNotEmpty) {
            payload['image_url'] = imageUrl.trim();
          }
          payloads.add(payload);
        }
        await _service.createExperiment(
          title: title,
          hypothesis: _trimmedOrNull(_hypothesisController.text),
          note: _trimmedOrNull(_noteController.text),
          startedAt: _startedAt,
          variants: payloads,
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
    final captured = [
      for (final variant in filled)
        (
          variant: variant,
          label: variant.label.text.trim(),
          description: variant.description.text.trim(),
        ),
    ];
    await _service.updateExperiment(
      experimentId: experiment.id,
      title: title,
      hypothesis: _hypothesisController.text.trim(),
      note: _noteController.text.trim(),
      startedAt: _startedAt,
    );
    final keptIds = filled.map((variant) => variant.id).toSet();
    for (final item in captured) {
      final variant = item.variant;
      final imageUrl = await _imageUrlForSave(variant);
      if (variant.id == null) {
        await _service.addVariant(
          experimentId: experiment.id,
          label: item.label,
          description: item.description,
          imageUrl: imageUrl,
        );
      } else {
        await _service.updateVariant(
          variantId: variant.id!,
          label: item.label,
          description: item.description,
          imageUrl: imageUrl,
          // Only touch image_url when this form changed it. Sending it on
          // every edit would overwrite a photo saved from another device
          // while this form was open.
          updateImage: variant.pickedBytes != null || variant.imageCleared,
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

  /// Upload a newly picked photo, then return the URL that should be stored.
  /// A cleared photo returns null so the variant row drops `image_url`.
  Future<String?> _imageUrlForSave(VariantDraft variant) async {
    String? uploaded;
    if (variant.pickedBytes != null) {
      uploaded = await _service.uploadVariantPhoto(
        imageBytes: variant.pickedBytes!,
      );
    }
    return variant.imageUrlForSave(uploaded);
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
    final sheetHeight =
        (media.size.height - media.padding.top - keyboard) * 0.94;
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
                      child: Material(
                        type: MaterialType.transparency,
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
                        key: ObjectKey(_variants[i]),
                        padding: EdgeInsets.only(bottom: spacing.md),
                        child: VariantDraftRow(
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
