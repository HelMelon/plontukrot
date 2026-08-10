import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/prompt_text_dialog.dart';
import '../../../../models/fertilizer.dart';
import '../../../../models/fertilizer_application_method.dart';
import '../../../../models/fertilizer_dose.dart';
import '../../../../models/fertilizer_ingredient.dart';
import '../../../../models/fertilizing_entry.dart';
import '../../../../models/plant.dart';
import '../../../../services/fertilize_service.dart';
import '../tags/fertilizer_component_tags.dart';
import '../dialogs/fertilizer_composition_dialog.dart';
import 'manage_fertilizer_ingredients_sheet.dart';
import 'manage_fertilizers_sheet.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

enum _FertilizerMode { saved, newMix }

class AddFertilizingSheet extends StatefulWidget {
  final List<String> plantIds;
  final List<Plant> plants;
  final String? title;
  final FertilizingEntry? entry;

  const AddFertilizingSheet({
    super.key,
    required this.plantIds,
    this.plants = const [],
    this.title,
    this.entry,
  });

  factory AddFertilizingSheet.forPlant({
    Key? key,
    required String plantId,
    Plant? plant,
  }) {
    return AddFertilizingSheet(
      key: key,
      plantIds: [plantId],
      plants: plant == null ? const [] : [plant],
    );
  }

  factory AddFertilizingSheet.edit({
    Key? key,
    required String plantId,
    required FertilizingEntry entry,
    Plant? plant,
  }) {
    return AddFertilizingSheet(
      key: key,
      plantIds: [plantId],
      plants: plant == null ? const [] : [plant],
      entry: entry,
    );
  }

  bool get isEditing => entry != null;

  @override
  State<AddFertilizingSheet> createState() => _AddFertilizingSheetState();
}

class _AddFertilizingSheetState extends State<AddFertilizingSheet> {
  final _service = FertilizeService();
  final _mixNameController = TextEditingController();

  late DateTime _selectedDate;
  late _FertilizerMode _mode;
  String? _selectedFertilizerId;
  late List<FertilizerDose> _components;
  late int _waterMl;
  late FertilizerApplicationMethod _applicationMethod;
  bool _saveMix = false;
  bool _saving = false;
  List<String> _catalogNames = const [];

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry != null) {
      _selectedDate = entry.appliedAt;
      _components = List.from(entry.components);
      _waterMl = entry.waterMl;
      _applicationMethod = entry.applicationMethod;
      if (entry.fertilizerId != null) {
        _mode = _FertilizerMode.saved;
        _selectedFertilizerId = entry.fertilizerId;
      } else {
        _mode = _FertilizerMode.newMix;
        _selectedFertilizerId = null;
      }
    } else {
      _selectedDate = DateTime.now();
      _mode = _FertilizerMode.saved;
      _components = [];
      _waterMl = 250;
      _applicationMethod = FertilizerApplicationMethod.root;
    }
  }

  @override
  void dispose() {
    _mixNameController.dispose();
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

  Future<void> _addCustomIngredient() async {
    final l10n = AppLocalizations.of(context);
    final name = await showPromptTextDialog(
      context: context,
      title: l10n.fertilizingAddIngredient,
      hintText: l10n.fertilizingIngredientNameHint,
      confirmLabel: l10n.commonAdd,
    );

    if (name == null || name.isEmpty) return;

    await _service.ensureIngredient(name: name);

    if (!mounted) return;

    final dose = await showFertilizerDoseDialog(
      context: context,
      component: name,
    );
    if (dose == null || dose.amount < 0) return;

    setState(() {
      final next = List<FertilizerDose>.from(_components);
      final index = next.indexWhere((c) => c.component == name);
      if (index >= 0) {
        next[index] = dose;
      } else {
        next.add(dose);
      }
      _components = next;
    });
  }

  Future<void> _openManageIngredients() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ManageFertilizerIngredientsSheet(
        onRenamed: (oldName, newName) {
          setState(() {
            _components = _components
                .map(
                  (c) => c.component == oldName
                      ? FertilizerDose(
                          component: newName,
                          amount: c.amount,
                          unit: c.unit,
                        )
                      : c,
                )
                .toList();
          });
        },
        onDeleted: (name) {
          setState(() {
            _components =
                _components.where((c) => c.component != name).toList();
          });
        },
      ),
    );
  }

  Future<void> _openManageFertilizers() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ManageFertilizersSheet(
        onDeleted: (fertilizerId) {
          if (_selectedFertilizerId == fertilizerId) {
            setState(() {
              _selectedFertilizerId = null;
              _components = [];
            });
          }
        },
      ),
    );
  }

  void _applySavedFertilizer(Fertilizer fertilizer) {
    setState(() {
      _selectedFertilizerId = fertilizer.id;
      _components = List.from(fertilizer.components);
      _waterMl = fertilizer.waterMl;
    });
  }

  Future<void> _showSelectedComposition(List<Fertilizer> fertilizers) async {
    final l10n = AppLocalizations.of(context);
    List<FertilizerDose> components;
    String title;
    int waterMl;

    if (_mode == _FertilizerMode.saved && _selectedFertilizerId != null) {
      final fertilizer = fertilizers.firstWhere(
        (f) => f.id == _selectedFertilizerId,
        orElse: () => Fertilizer(
          id: '',
          name: l10n.fertilizerFallbackName,
          waterMl: _waterMl,
          components: _components,
        ),
      );
      components = fertilizer.components;
      waterMl = fertilizer.waterMl;
      title = fertilizer.name.isEmpty
          ? l10n.commonComposition
          : fertilizer.name;
    } else {
      components = _components;
      waterMl = _waterMl;
      title = _saveMix && _mixNameController.text.trim().isNotEmpty
          ? _mixNameController.text.trim()
          : l10n.fertilizerCustomMix;
    }

    await showFertilizerCompositionDialog(
      context: context,
      title: title,
      components: components,
      waterMl: waterMl,
    );
  }

  Widget _waterVolumePicker(AppLocalizations l10n, {bool enabled = true}) {
    final spacing = context.spacing;
    final typography = context.typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fertilizingWaterVolume,
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
          onSelectionChanged: enabled
              ? (value) => setState(() => _waterMl = value.first)
              : null,
        ),
      ],
    );
  }

  bool get _canSave {
    if (_saving) return false;
    if (_mode == _FertilizerMode.saved) {
      if (_selectedFertilizerId != null) return true;
      // Editing a saved mix that no longer exists in catalog.
      return widget.isEditing && _components.isNotEmpty;
    }
    if (_components.isEmpty) return false;
    if (_saveMix && _mixNameController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() => _saving = true);

    try {
      String? fertilizerId =
          _mode == _FertilizerMode.saved ? _selectedFertilizerId : null;
      String? fertilizerName;
      var components = _components;
      var waterMl = _waterMl;

      if (_mode == _FertilizerMode.saved && fertilizerId != null) {
        final fertilizer = await _service.getFertilizer(fertilizerId);
        fertilizerName = fertilizer?.name;
        if (fertilizer != null) {
          components = fertilizer.components;
          waterMl = fertilizer.waterMl;
        } else if (widget.entry != null) {
          fertilizerName = widget.entry!.fertilizerName;
          components = widget.entry!.components;
          waterMl = widget.entry!.waterMl;
        }
      }

      if (_mode == _FertilizerMode.newMix && _saveMix) {
        final name = _mixNameController.text.trim();
        fertilizerId = await _service.addFertilizer(
          name: name,
          kind: FertilizerKind.mix,
          waterMl: _waterMl,
          components: _components,
        );
        fertilizerName = name;
      }

      final entry = widget.entry;
      if (entry != null) {
        await _service.updateFertilizing(
          plantId: widget.plantIds.first,
          fertilizingId: entry.id,
          appliedAt: _selectedDate,
          components: components,
          waterMl: waterMl,
          applicationMethod: _applicationMethod,
          fertilizerId: fertilizerId,
          fertilizerName: fertilizerName,
        );
      } else if (widget.plantIds.length > 1 || widget.plants.isNotEmpty) {
        final plantsById = {
          for (final plant in widget.plants) plant.id: plant,
        };
        await _service.addFertilizings(
          plantIds: widget.plantIds,
          appliedAt: _selectedDate,
          components: components,
          waterMl: waterMl,
          applicationMethod: _applicationMethod,
          fertilizerId: fertilizerId,
          fertilizerName: fertilizerName,
          lastFertilizedAtByPlantId: {
            for (final id in widget.plantIds)
              id: plantsById[id]?.lastFertilizedAt,
          },
          lastWateredAtByPlantId: {
            for (final id in widget.plantIds) id: plantsById[id]?.lastWateredAt,
          },
          wateringFrequencyByPlantId: {
            for (final id in widget.plantIds)
              id: plantsById[id]?.wateringFrequency,
          },
        );
      } else {
        await _service.addFertilizing(
          plantId: widget.plantIds.first,
          appliedAt: _selectedDate,
          components: components,
          waterMl: waterMl,
          applicationMethod: _applicationMethod,
          fertilizerId: fertilizerId,
          fertilizerName: fertilizerName,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final title = widget.title ??
        (widget.isEditing ? l10n.fertilizingEdit : l10n.fertilizingAdd);
    final colors = context.colors;
    final spacing = context.spacing;
    final inputs = context.components.inputs;
    final typography = context.typography;
    final dimensions = context.dimensions;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: spacing.allLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: const SheetDragHandle()),
              spacing.vMd,
              Text(
                title,
                style: typography.titleMedium,
              ),
              spacing.vLg,
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const ExcludeSemantics(
                  child: Icon(Icons.calendar_today),
                ),
                title: Text(DateFormat('d MMM y').format(_selectedDate)),
                onTap: _pickDate,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _selectedDate = DateTime.now()),
                  child: Text(l10n.commonToday),
                ),
              ),
              spacing.vMd,
              Text(
                l10n.fertilizingApplicationMethod,
                style: typography.label.copyWith(fontWeight: FontWeight.w600),
              ),
              spacing.vXs,
              Wrap(
                spacing: spacing.xs,
                runSpacing: spacing.xs,
                children: [
                  ChoiceChip(
                    label: Text(l10n.applicationMethodLabel(
                      FertilizerApplicationMethod.root,
                    )),
                    selected:
                        _applicationMethod == FertilizerApplicationMethod.root,
                    onSelected: (_) {
                      setState(
                        () => _applicationMethod =
                            FertilizerApplicationMethod.root,
                      );
                    },
                  ),
                  ChoiceChip(
                    label: Text(l10n.applicationMethodLabel(
                      FertilizerApplicationMethod.foliar,
                    )),
                    selected: _applicationMethod ==
                        FertilizerApplicationMethod.foliar,
                    onSelected: (_) {
                      setState(
                        () => _applicationMethod =
                            FertilizerApplicationMethod.foliar,
                      );
                    },
                  ),
                ],
              ),
              spacing.vMd,
              Wrap(
                spacing: spacing.xs,
                runSpacing: spacing.xs,
                children: [
                  ChoiceChip(
                    label: Text(l10n.fertilizingSaved),
                    selected: _mode == _FertilizerMode.saved,
                    onSelected: (_) {
                      setState(() => _mode = _FertilizerMode.saved);
                    },
                  ),
                  ChoiceChip(
                    label: Text(l10n.fertilizingNewMix),
                    selected: _mode == _FertilizerMode.newMix,
                    onSelected: (_) {
                      setState(() {
                        _mode = _FertilizerMode.newMix;
                        _selectedFertilizerId = null;
                        _saveMix = false;
                      });
                    },
                  ),
                ],
              ),
              spacing.vMd,
              if (_mode == _FertilizerMode.saved)
                StreamBuilder<List<Fertilizer>>(
                  stream: _service.getFertilizers(),
                  builder: (context, snapshot) {
                    final fertilizers = snapshot.data ?? const <Fertilizer>[];

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: AccessibleProgressIndicator());
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.fertilizingCatalog,
                              style: typography.label.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _openManageFertilizers,
                              icon: Icon(
                                Icons.edit_outlined,
                                size: dimensions.iconMd,
                              ),
                              label: Text(l10n.commonManage),
                            ),
                          ],
                        ),
                        if (fertilizers.isEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.fertilizingEmptyCatalog,
                                style: typography.bodySmall,
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(
                                    () => _mode = _FertilizerMode.newMix,
                                  );
                                },
                                child: Text(l10n.fertilizingGoToNewMix),
                              ),
                            ],
                          )
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButton<String>(
                                  value: fertilizers.any(
                                    (f) => f.id == _selectedFertilizerId,
                                  )
                                      ? _selectedFertilizerId
                                      : null,
                                  hint: Text(
                                    _selectedFertilizerId != null &&
                                            widget.entry != null
                                        ? l10n.fertilizerDisplayName(
                                            storedName:
                                                widget.entry!.fertilizerName,
                                            fertilizerId:
                                                widget.entry!.fertilizerId,
                                          )
                                        : l10n.fertilizingSelectFertilizer,
                                  ),
                                  isExpanded: true,
                                  items: fertilizers
                                      .map(
                                        (f) => DropdownMenuItem(
                                          value: f.id,
                                          child: Text(
                                            l10n.fertilizerWithMeta(
                                              f.name,
                                              l10n.fertilizerKindLabel(f.kind),
                                              f.waterMl,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    final fertilizer = fertilizers
                                        .firstWhere((f) => f.id == value);
                                    _applySavedFertilizer(fertilizer);
                                  },
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.fertilizingViewComposition,
                                onPressed: _selectedFertilizerId == null &&
                                        _components.isEmpty
                                    ? null
                                    : () =>
                                        _showSelectedComposition(fertilizers),
                                icon: const Icon(Icons.info_outline),
                              ),
                            ],
                          ),
                          if (_selectedFertilizerId != null ||
                              _components.isNotEmpty) ...[
                            spacing.vSm,
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n.fertilizingMixWaterVolume(_waterMl),
                                style: typography.bodySmall,
                              ),
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              if (_mode == _FertilizerMode.newMix) ...[
                _waterVolumePicker(l10n),
                spacing.vMd,
                Row(
                  children: [
                    Text(
                      l10n.fertilizingIngredients,
                      style: typography.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _openManageIngredients,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: dimensions.iconMd,
                      ),
                      label: Text(l10n.commonManage),
                    ),
                  ],
                ),
                StreamBuilder<List<FertilizerIngredient>>(
                  stream: _service.getIngredients(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    }
                    if (!snapshot.hasData) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: spacing.md),
                        child: const Center(child: AccessibleProgressIndicator()),
                      );
                    }

                    final catalog = snapshot.data!;
                    _catalogNames = catalog.map((c) => c.name).toList();

                    return FertilizerComponentTags(
                      availableComponents: _catalogNames,
                      selected: _components,
                      onChanged: (next) => setState(() => _components = next),
                      onAddCustom: _addCustomIngredient,
                    );
                  },
                ),
                spacing.vXs,
                Text(
                  l10n.fertilizingTapIngredientHint,
                  style: typography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                spacing.vSm,
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _saveMix,
                  onChanged: (value) {
                    setState(() => _saveMix = value ?? false);
                  },
                  title: Text(l10n.fertilizingSaveThisMix),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_saveMix)
                  TextField(
                    controller: _mixNameController,
                    decoration: inputs.decoration(
                      labelText: l10n.fertilizingMixName,
                      hintText: l10n.fertilizingMixNameHint,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
              ],
              spacing.vLg,
              FilledButton(
                onPressed: _canSave ? _save : null,
                child: _saving
                    ? SizedBox(
                        width: dimensions.iconLg,
                        height: dimensions.iconLg,
                        child: AccessibleProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
