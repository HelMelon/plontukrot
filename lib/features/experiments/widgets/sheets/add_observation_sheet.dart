import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/accessible_progress_indicator.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';
import '../../../../models/experiment_observation.dart';
import '../../../../models/experiment_subject.dart';
import '../../../../services/experiment_service.dart';
import '../../../plants/widgets/common/pick_and_crop_plant_photo.dart';

/// Log one observation for a single participant: date, free-text note, optional
/// photo, and the numeric readings the user chose to measure. All numeric or
/// text fields may be left empty as long as the note is present.
class AddObservationSheet extends StatefulWidget {
  final ExperimentSubject subject;
  final ExperimentObservation? observation;

  const AddObservationSheet({super.key, required this.subject, this.observation});

  @override
  State<AddObservationSheet> createState() => _AddObservationSheetState();
}

class _AddObservationSheetState extends State<AddObservationSheet> {
  final _service = ExperimentService();
  final _noteController = TextEditingController();
  final _heightController = TextEditingController();
  final _leavesController = TextEditingController();
  final _moistureController = TextEditingController();

  late DateTime _observedAt = widget.observation?.observedAt ?? DateTime.now();
  Uint8List? _pickedBytes;
  String? _existingImageUrl;
  bool _isSaving = false;
  String? _noteError;

  bool get _isEditing => widget.observation != null;

  @override
  void initState() {
    super.initState();
    final observation = widget.observation;
    if (observation != null) {
      _noteController.text = observation.note ?? '';
      _existingImageUrl = observation.imageUrl;
      if (observation.heightCm != null) {
        _heightController.text = _formatNumber(observation.heightCm!);
      }
      if (observation.leafCount != null) {
        _leavesController.text = observation.leafCount!.toString();
      }
      if (observation.moisture != null) {
        _moistureController.text = _formatNumber(observation.moisture!);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _heightController.dispose();
    _leavesController.dispose();
    _moistureController.dispose();
    super.dispose();
  }

  /// Trims trailing `.0` so an integer measurement reads "12", not "12.0".
  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  double? _parseDouble(String text) {
    final trimmed = text.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  int? _parseInt(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _observedAt.isAfter(now) ? now : _observedAt,
      firstDate: DateTime(2015),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _observedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _observedAt.hour,
        _observedAt.minute,
      );
    });
  }

  Future<void> _pickPhoto() async {
    final bytes = await pickAndCropPlantPhoto(context);
    if (bytes == null || !mounted) return;
    setState(() {
      _pickedBytes = bytes;
      _existingImageUrl = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final note = _noteController.text.trim();
    final height = _parseDouble(_heightController.text);
    final leaves = _parseInt(_leavesController.text);
    final moisture = _parseDouble(_moistureController.text);
    final hasPhoto = _pickedBytes != null || _existingImageUrl != null;

    if (_isEditing) {
      // Editing keeps it simple: delete + re-add so the nested log stays
      // authoritative on the server without a dedicated PATCH route.
      await _replaceExisting(
        note: note,
        height: height,
        leaves: leaves,
        moisture: moisture,
      );
      return;
    }

    if (note.isEmpty && !hasPhoto && height == null && leaves == null &&
        moisture == null) {
      setState(() => _noteError = l10n.notesCannotBeEmpty);
      return;
    }

    setState(() {
      _isSaving = true;
      _noteError = null;
    });
    try {
      var imageUrl = _existingImageUrl;
      if (_pickedBytes != null) {
        imageUrl = await _service.uploadObservationPhoto(
          subjectId: widget.subject.id,
          imageBytes: _pickedBytes!,
        );
      }
      await _service.addObservation(
        subjectId: widget.subject.id,
        observedAt: _observedAt,
        note: note,
        imageUrl: imageUrl,
        heightCm: height,
        leafCount: leaves,
        moisture: moisture,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(error.toString()))),
      );
    }
  }

  Future<void> _replaceExisting({
    required String note,
    required double? height,
    required int? leaves,
    required double? moisture,
  }) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      var imageUrl = _existingImageUrl;
      if (_pickedBytes != null) {
        imageUrl = await _service.uploadObservationPhoto(
          subjectId: widget.subject.id,
          imageBytes: _pickedBytes!,
        );
      }
      await _service.deleteObservation(widget.observation!.id);
      await _service.addObservation(
        subjectId: widget.subject.id,
        observedAt: _observedAt,
        note: note,
        imageUrl: imageUrl,
        heightCm: height,
        leafCount: leaves,
        moisture: moisture,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(error.toString()))),
      );
    }
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
    final dateLabel = DateFormat('d MMM y').format(_observedAt);
    final hasPhoto = _pickedBytes != null || _existingImageUrl != null;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: sheetHeight,
        child: Material(
          color: colors.modal,
          borderRadius: sheets.topBorderRadius,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const SheetDragHandle(),
              Expanded(
                child: ListView(
                  padding: sheets.contentPadding,
                  children: [
                    Text(
                      l10n.experimentsObservationTitle,
                      style: typography.titleLarge.copyWith(letterSpacing: -1),
                    ),
                    spacing.vXs,
                    Text(
                      widget.subject.displayName,
                      style: typography.bodyLarge.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        title: Text(l10n.experimentsObservationDate),
                        subtitle: Text(dateLabel),
                        onTap: _pickDate,
                      ),
                    ),
                    spacing.vSm,
                    _PhotoPickerTile(
                      hasPhoto: hasPhoto,
                      bytes: _pickedBytes,
                      imageUrl: _existingImageUrl,
                      label: l10n.experimentsObservationPhoto,
                      onPick: _pickPhoto,
                      onClear: () => setState(() {
                        _pickedBytes = null;
                        _existingImageUrl = null;
                      }),
                    ),
                    spacing.vMd,
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      style: inputs.textStyle,
                      onChanged: (_) {
                        if (_noteError != null) {
                          setState(() => _noteError = null);
                        }
                      },
                      decoration: inputs
                          .decoration(
                            labelText: l10n.experimentsObservationNote,
                          )
                          .copyWith(errorText: _noteError),
                    ),
                    spacing.vMd,
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: inputs.textStyle,
                            decoration: inputs.decoration(
                              labelText: l10n.experimentsObservationHeight,
                            ),
                          ),
                        ),
                        spacing.hMd,
                        Expanded(
                          child: TextField(
                            controller: _leavesController,
                            keyboardType: TextInputType.number,
                            style: inputs.textStyle,
                            decoration: inputs.decoration(
                              labelText: l10n.experimentsObservationLeaves,
                            ),
                          ),
                        ),
                      ],
                    ),
                    spacing.vMd,
                    TextField(
                      controller: _moistureController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: inputs.textStyle,
                      decoration: inputs.decoration(
                        labelText: l10n.experimentsObservationMoisture,
                      ),
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

/// Photo row: tap to pick/crop, shows a thumbnail, and offers a clear action.
class _PhotoPickerTile extends StatelessWidget {
  final bool hasPhoto;
  final Uint8List? bytes;
  final String? imageUrl;
  final String label;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _PhotoPickerTile({
    required this.hasPhoto,
    required this.bytes,
    required this.imageUrl,
    required this.label,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final typography = context.typography;

    return Row(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(radii.lg),
              border: Border.all(color: colors.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? (bytes != null
                    ? Image.memory(bytes!, fit: BoxFit.cover)
                    : Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          context.icons.image,
                          color: colors.textSecondary,
                        ),
                      ))
                : Icon(context.icons.addPhotoOutlined,
                    color: colors.textSecondary),
          ),
        ),
        spacing.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: typography.bodyLarge),
              if (hasPhoto)
                TextButton(
                  onPressed: onClear,
                  child: Text(AppLocalizations.of(context).commonClear),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
