import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/prompt_text_dialog.dart';
import '../../../../models/fertilizer.dart';
import '../../../../models/fertilizer_application_method.dart';
import '../../../../models/fertilizer_dose.dart';
import '../../../../models/fertilizer_ingredient.dart';
import '../../../../models/fertilizing_entry.dart';
import '../../../../services/fertilize_service.dart';
import '../tags/fertilizer_component_tags.dart';
import '../dialogs/fertilizer_composition_dialog.dart';
import 'manage_fertilizer_ingredients_sheet.dart';
import 'manage_fertilizers_sheet.dart';

enum _FertilizerMode { saved, newMix }

class AddFertilizingSheet extends StatefulWidget {
  final List<String> plantIds;
  final String title;
  final FertilizingEntry? entry;

  const AddFertilizingSheet({
    super.key,
    required this.plantIds,
    this.title = 'Add Fertilizing',
    this.entry,
  });

  factory AddFertilizingSheet.forPlant({
    Key? key,
    required String plantId,
  }) {
    return AddFertilizingSheet(key: key, plantIds: [plantId]);
  }

  factory AddFertilizingSheet.edit({
    Key? key,
    required String plantId,
    required FertilizingEntry entry,
  }) {
    return AddFertilizingSheet(
      key: key,
      plantIds: [plantId],
      title: 'Edit Fertilizing',
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
    final name = await showPromptTextDialog(
      context: context,
      title: 'Add ingredient',
      hintText: 'Ingredient name',
      confirmLabel: 'Add',
    );

    if (name == null || name.isEmpty) return;

    final exists = _catalogNames.any(
      (n) => n.toLowerCase() == name.toLowerCase(),
    );
    if (!exists) {
      await _service.addIngredient(name: name);
    }

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
    List<FertilizerDose> components;
    String title;
    int waterMl;

    if (_mode == _FertilizerMode.saved && _selectedFertilizerId != null) {
      final fertilizer = fertilizers.firstWhere(
        (f) => f.id == _selectedFertilizerId,
        orElse: () => Fertilizer(
          id: '',
          name: 'Fertilizer',
          waterMl: _waterMl,
          components: _components,
        ),
      );
      components = fertilizer.components;
      waterMl = fertilizer.waterMl;
      title = fertilizer.name.isEmpty ? 'Composition' : fertilizer.name;
    } else {
      components = _components;
      waterMl = _waterMl;
      title = _saveMix && _mixNameController.text.trim().isNotEmpty
          ? _mixNameController.text.trim()
          : 'Custom mix';
    }

    await showFertilizerCompositionDialog(
      context: context,
      title: title,
      components: components,
      waterMl: waterMl,
    );
  }

  Widget _waterVolumePicker({bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Water volume',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (final ml in kWaterVolumesMl)
              ButtonSegment(value: ml, label: Text('${ml}ml')),
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
      } else if (_mode == _FertilizerMode.newMix) {
        fertilizerName = 'Custom mix';
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
      } else {
        await Future.wait(
          widget.plantIds.map(
            (plantId) => _service.addFertilizing(
              plantId: plantId,
              appliedAt: _selectedDate,
              components: components,
              waterMl: waterMl,
              applicationMethod: _applicationMethod,
              fertilizerId: fertilizerId,
              fertilizerName: fertilizerName,
            ),
          ),
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('d MMM y').format(_selectedDate)),
                onTap: _pickDate,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _selectedDate = DateTime.now()),
                  child: const Text('Today'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Способ внесения',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<FertilizerApplicationMethod>(
                segments: const [
                  ButtonSegment(
                    value: FertilizerApplicationMethod.root,
                    label: Text('Корневое'),
                  ),
                  ButtonSegment(
                    value: FertilizerApplicationMethod.foliar,
                    label: Text('Внекорневое'),
                  ),
                ],
                selected: {_applicationMethod},
                onSelectionChanged: (value) {
                  setState(() => _applicationMethod = value.first);
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<_FertilizerMode>(
                segments: const [
                  ButtonSegment(
                    value: _FertilizerMode.saved,
                    label: Text('Saved'),
                    icon: Icon(Icons.bookmark_outline),
                  ),
                  ButtonSegment(
                    value: _FertilizerMode.newMix,
                    label: Text('New mix'),
                    icon: Icon(Icons.science_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (value) {
                  setState(() {
                    _mode = value.first;
                    if (_mode == _FertilizerMode.newMix) {
                      _selectedFertilizerId = null;
                      _saveMix = false;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_mode == _FertilizerMode.saved)
                StreamBuilder<List<Fertilizer>>(
                  stream: _service.getFertilizers(),
                  builder: (context, snapshot) {
                    final fertilizers = snapshot.data ?? const <Fertilizer>[];

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Catalog',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _openManageFertilizers,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Manage'),
                            ),
                          ],
                        ),
                        if (fertilizers.isEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Пока нет удобрений. Добавьте готовое или сохраните микс.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(
                                    () => _mode = _FertilizerMode.newMix,
                                  );
                                },
                                child: const Text('Switch to New mix'),
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
                                        ? widget.entry!.fertilizerName
                                        : 'Select fertilizer',
                                  ),
                                  isExpanded: true,
                                  items: fertilizers
                                      .map(
                                        (f) => DropdownMenuItem(
                                          value: f.id,
                                          child: Text(
                                            '${f.name} · ${f.kind.label} · ${f.waterMl}ml',
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
                                tooltip: 'View composition',
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
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Mix water volume: ${_waterMl}ml',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              if (_mode == _FertilizerMode.newMix) ...[
                _waterVolumePicker(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Ingredients',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _openManageIngredients,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Manage'),
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
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
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
                const SizedBox(height: 8),
                const Text(
                  'Tap an ingredient to set amount (g or ml)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _saveMix,
                  onChanged: (value) {
                    setState(() => _saveMix = value ?? false);
                  },
                  title: const Text('Save this mix'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_saveMix)
                  TextField(
                    controller: _mixNameController,
                    decoration: const InputDecoration(
                      labelText: 'Mix name',
                      hintText: 'e.g. Grow formula',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _canSave ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
