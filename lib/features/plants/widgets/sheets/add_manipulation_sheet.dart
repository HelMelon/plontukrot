import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/manipulation_entry.dart';
import '../../../../models/manipulation_type.dart';
import '../../../../models/stimulator.dart';
import '../../../../services/manipulation_service.dart';
import '../../../../services/stimulator_service.dart';
import '../selectors/plant_stage_selector.dart';
import 'manage_stimulators_sheet.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

enum _StimulatorMode { saved, custom }

class AddManipulationSheet extends StatefulWidget {
  final String plantId;
  final int plantStage;
  final ManipulationEntry? entry;

  const AddManipulationSheet({
    super.key,
    required this.plantId,
    this.plantStage = 0,
    this.entry,
  });

  factory AddManipulationSheet.forPlant({
    Key? key,
    required String plantId,
    int plantStage = 0,
  }) {
    return AddManipulationSheet(
      key: key,
      plantId: plantId,
      plantStage: plantStage,
    );
  }

  factory AddManipulationSheet.edit({
    Key? key,
    required String plantId,
    required ManipulationEntry entry,
    int plantStage = 0,
  }) {
    return AddManipulationSheet(
      key: key,
      plantId: plantId,
      plantStage: plantStage,
      entry: entry,
    );
  }

  bool get isEditing => entry != null;

  @override
  State<AddManipulationSheet> createState() => _AddManipulationSheetState();
}

class _AddManipulationSheetState extends State<AddManipulationSheet> {
  final _manipulationService = ManipulationService();
  final _stimulatorService = StimulatorService();
  final _noteController = TextEditingController();
  final _customNameController = TextEditingController();
  final _dosageController = TextEditingController();

  late ManipulationType _type;
  late DateTime _selectedDate;
  late _StimulatorMode _stimulatorMode;
  String? _selectedStimulatorId;
  bool _setStageAfter = false;
  int? _stageAfter;
  bool _saving = false;
  String? _stimulatorNameError;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry != null) {
      _type = entry.type;
      _selectedDate = entry.appliedAt;
      _noteController.text = entry.note ?? '';
      _stageAfter = entry.stageAfter;
      _setStageAfter = entry.stageAfter != null;
      if (entry.type == ManipulationType.stimulator) {
        if (entry.stimulatorId != null) {
          _stimulatorMode = _StimulatorMode.saved;
          _selectedStimulatorId = entry.stimulatorId;
        } else {
          _stimulatorMode = _StimulatorMode.custom;
          _customNameController.text = entry.stimulatorName ?? '';
        }
        _dosageController.text = entry.dosage ?? '';
      } else {
        _stimulatorMode = _StimulatorMode.saved;
      }
    } else {
      _type = ManipulationType.pinching;
      _selectedDate = DateTime.now();
      _stimulatorMode = _StimulatorMode.saved;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customNameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openManageStimulators() async {
    await showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => ManageStimulatorsSheet(
        onDeleted: (id) {
          if (_selectedStimulatorId == id) {
            setState(() => _selectedStimulatorId = null);
          }
        },
      ),
    );
  }

  void _applySavedStimulator(Stimulator stimulator) {
    setState(() {
      _selectedStimulatorId = stimulator.id;
      _stimulatorNameError = null;
      if (_dosageController.text.trim().isEmpty &&
          stimulator.defaultDosage != null) {
        _dosageController.text = stimulator.defaultDosage!;
      }
    });
  }

  bool get _canSave {
    if (_type != ManipulationType.stimulator) return true;
    if (_stimulatorMode == _StimulatorMode.saved) {
      return _selectedStimulatorId != null;
    }
    return _customNameController.text.trim().isNotEmpty;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);

    String? stimulatorId;
    String? stimulatorName;
    if (_type == ManipulationType.stimulator) {
      if (_stimulatorMode == _StimulatorMode.saved) {
        if (_selectedStimulatorId == null) {
          setState(() {
            _stimulatorNameError = l10n.manipulationStimulatorNameRequired;
          });
          return;
        }
        final stimulator =
            await _stimulatorService.getStimulator(_selectedStimulatorId!);
        stimulatorId = _selectedStimulatorId;
        stimulatorName = stimulator?.name ?? '';
      } else {
        stimulatorName = _customNameController.text.trim();
        if (stimulatorName.isEmpty) {
          setState(() {
            _stimulatorNameError = l10n.manipulationStimulatorNameRequired;
          });
          return;
        }
      }
    }

    setState(() {
      _saving = true;
      _stimulatorNameError = null;
    });

    try {
      final note = _noteController.text.trim();
      final dosage = _dosageController.text.trim();
      final stageAfter =
          _type == ManipulationType.rerooting && _setStageAfter
              ? _stageAfter
              : null;

      if (widget.isEditing) {
        await _manipulationService.updateManipulation(
          plantId: widget.plantId,
          manipulationId: widget.entry!.id,
          type: _type,
          appliedAt: _selectedDate,
          note: note.isEmpty ? null : note,
          stageBefore: widget.entry!.stageBefore,
          stageAfter: stageAfter,
          stimulatorId: stimulatorId,
          stimulatorName: stimulatorName,
          dosage: dosage.isEmpty ? null : dosage,
        );
      } else {
        await _manipulationService.addManipulation(
          plantId: widget.plantId,
          type: _type,
          appliedAt: _selectedDate,
          note: note.isEmpty ? null : note,
          stageAfter: stageAfter,
          stimulatorId: stimulatorId,
          stimulatorName: stimulatorName,
          dosage: dosage.isEmpty ? null : dosage,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    }
  }

  void _onSavePressed() {
    if (!_canSave) {
      final l10n = AppLocalizations.of(context);
      if (_type == ManipulationType.stimulator) {
        setState(() {
          _stimulatorNameError = l10n.manipulationStimulatorNameRequired;
        });
      }
      return;
    }
    _save();
  }

  Widget _buildTypeSelector(AppLocalizations l10n) {
    final spacing = context.spacing;
    final colors = context.colors;
    final typography = context.typography;

    if (widget.isEditing) {
      return Text(
        l10n.manipulationTypeLabel(_type),
        style: typography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      );
    }

    return Wrap(
      spacing: spacing.xs,
      runSpacing: spacing.xs,
      children: ManipulationType.values.map((type) {
        final selected = _type == type;
        return Semantics(
          label: l10n.manipulationTypeLabel(type),
          selected: selected,
          child: ChoiceChip(
            label: Text(l10n.manipulationTypeLabel(type)),
            selected: selected,
            onSelected: (_) => setState(() {
              _type = type;
              _stimulatorNameError = null;
            }),
            selectedColor: colors.primary,
            backgroundColor: colors.card,
            labelStyle: typography.label.copyWith(
              color: selected ? colors.onPrimary : colors.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(
              color: selected ? colors.primary : colors.outline,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRerootingFields(AppLocalizations l10n) {
    final spacing = context.spacing;
    final typography = context.typography;
    final stageBefore = widget.isEditing
        ? widget.entry!.stageBefore ?? widget.plantStage
        : widget.plantStage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.manipulationRerootingStageBefore(l10n.stageTitle(stageBefore)),
          style: typography.bodySmall,
        ),
        spacing.vSm,
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _setStageAfter,
          onChanged: (value) {
            setState(() {
              _setStageAfter = value ?? false;
              if (_setStageAfter && _stageAfter == null) {
                _stageAfter = stageBefore;
              }
            });
          },
          title: Text(l10n.manipulationRerootingStageOptional),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_setStageAfter) ...[
          spacing.vSm,
          PlantStageSelector(
            selectedStage: _stageAfter ?? stageBefore,
            onChanged: (value) => setState(() => _stageAfter = value),
          ),
        ],
      ],
    );
  }

  Widget _buildStimulatorFields(AppLocalizations l10n) {
    final spacing = context.spacing;
    final typography = context.typography;
    final inputs = context.components.inputs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: spacing.xs,
          runSpacing: spacing.xs,
          children: [
            ChoiceChip(
              label: Text(l10n.manipulationStimulatorModeSaved),
              selected: _stimulatorMode == _StimulatorMode.saved,
              onSelected: (_) {
                setState(() {
                  _stimulatorMode = _StimulatorMode.saved;
                  _stimulatorNameError = null;
                });
              },
            ),
            ChoiceChip(
              label: Text(l10n.manipulationStimulatorModeCustom),
              selected: _stimulatorMode == _StimulatorMode.custom,
              onSelected: (_) {
                setState(() {
                  _stimulatorMode = _StimulatorMode.custom;
                  _selectedStimulatorId = null;
                  _stimulatorNameError = null;
                });
              },
            ),
          ],
        ),
        spacing.vMd,
        if (_stimulatorMode == _StimulatorMode.saved)
          StreamBuilder<List<Stimulator>>(
            stream: _stimulatorService.watchStimulators(),
            builder: (context, snapshot) {
              final stimulators = snapshot.data ?? const <Stimulator>[];

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: AccessibleProgressIndicator());
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: stimulators.any(
                            (s) => s.id == _selectedStimulatorId,
                          )
                              ? _selectedStimulatorId
                              : null,
                          decoration: inputs.decoration(
                            labelText: l10n.manipulationStimulatorSelect,
                            errorText: _stimulatorNameError,
                          ),
                          isExpanded: true,
                          items: stimulators
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    s.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: stimulators.isEmpty
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  final stimulator = stimulators
                                      .firstWhere((s) => s.id == value);
                                  _applySavedStimulator(stimulator);
                                },
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.commonManage,
                        onPressed: _openManageStimulators,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  if (stimulators.isEmpty) ...[
                    spacing.vXs,
                    Text(
                      l10n.emptyStimulators,
                      style: typography.bodySmall,
                    ),
                  ],
                ],
              );
            },
          )
        else
          TextField(
            controller: _customNameController,
            decoration: inputs.decoration(
              labelText: l10n.manipulationStimulatorName,
              hintText: l10n.manipulationStimulatorNameHint,
              errorText: _stimulatorNameError,
            ),
            onChanged: (_) {
              if (_stimulatorNameError != null) {
                setState(() => _stimulatorNameError = null);
              }
            },
          ),
        spacing.vMd,
        TextField(
          controller: _dosageController,
          decoration: inputs.decoration(
            labelText: l10n.manipulationStimulatorDosage,
            hintText: l10n.manipulationStimulatorDosageHint,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final inputs = context.components.inputs;

    return Material(
      color: colors.modal,
      borderRadius: sheets.topBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: spacing.lg,
            right: spacing.lg,
            top: spacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + spacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetDragHandle(),
                spacing.vMd,
                Text(
                  widget.isEditing
                      ? l10n.manipulationEdit
                      : l10n.manipulationAdd,
                  style: typography.titleMedium,
                ),
                spacing.vLg,
                Text(
                  l10n.manipulationTypeField,
                  style: typography.label.copyWith(
                    color: colors.heading,
                  ),
                ),
                spacing.vXs,
                _buildTypeSelector(l10n),
                spacing.vLg,
                Semantics(
                  button: true,
                  label: l10n.a11ySelectDate(
                    DateFormat.yMMMMd().format(_selectedDate),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const ExcludeSemantics(
                      child: Icon(Icons.calendar_today),
                    ),
                    title: Text(DateFormat.yMMMMd().format(_selectedDate)),
                    onTap: _pickDate,
                  ),
                ),
                spacing.vMd,
                TextField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: inputs.decoration(
                    labelText: l10n.manipulationNote,
                    hintText: l10n.manipulationNoteHint,
                  ),
                ),
                if (_type == ManipulationType.rerooting) ...[
                  spacing.vLg,
                  _buildRerootingFields(l10n),
                ],
                if (_type == ManipulationType.stimulator) ...[
                  spacing.vLg,
                  _buildStimulatorFields(l10n),
                ],
                spacing.vLg,
                SizedBox(
                  height: dimensions.buttonHeight,
                  child: FilledButton(
                    onPressed: _saving ? null : _onSavePressed,
                    child: _saving
                        ? SizedBox(
                            width: dimensions.iconLg,
                            height: dimensions.iconLg,
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
        ),
      ),
    );
  }
}
