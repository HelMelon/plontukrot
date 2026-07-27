import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/catalog_component.dart';
import '../../../../models/component.dart';
import '../../../../models/soil.dart';
import '../../../../services/component_service.dart';
import '../../../../services/repotting_service.dart';
import '../../../../services/soil_service.dart';
import '../tags/soil_component_tags.dart';
import '../dialogs/soil_composition_dialog.dart';
import 'manage_components_sheet.dart';

enum _SoilMode { saved, newMix }

class AddRepottingSheet extends StatefulWidget {
  final String plantId;

  const AddRepottingSheet({super.key, required this.plantId});

  @override
  State<AddRepottingSheet> createState() => _AddRepottingSheetState();
}

class _AddRepottingSheetState extends State<AddRepottingSheet> {
  final _repottingService = RepottingService();
  final _soilService = SoilService();
  final _componentService = ComponentService();
  final _mixNameController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  _SoilMode _mode = _SoilMode.newMix;
  String? _selectedSoilId;
  List<SoilComponent> _components = [];
  bool _saveMix = false;
  bool _saving = false;
  List<String> _catalogNames = const [];

  @override
  void initState() {
    super.initState();
    _componentService.ensureDefaultComponents();
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

  Future<void> _addCustomComponent() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: const Text('Add component'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Component name'),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (name == null || name.isEmpty) return;

    final exists = _catalogNames.any(
      (n) => n.toLowerCase() == name.toLowerCase(),
    );
    if (!exists) {
      await _componentService.addComponent(name: name);
    }

    setState(() {
      if (!_components.any((c) => c.component == name)) {
        _components = [
          ..._components,
          SoilComponent(component: name, parts: 1),
        ];
      }
    });
  }

  Future<void> _openManageComponents() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ManageComponentsSheet(
        onRenamed: (oldName, newName) {
          setState(() {
            _components = _components
                .map(
                  (c) => c.component == oldName
                      ? SoilComponent(component: newName, parts: c.parts)
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

  void _applySavedSoil(Soil soil) {
    setState(() {
      _selectedSoilId = soil.id;
      _components = List.from(soil.components);
    });
  }

  Future<void> _showSelectedComposition(List<Soil> soils) async {
    List<SoilComponent> components;
    String title;

    if (_mode == _SoilMode.saved && _selectedSoilId != null) {
      final soil = soils.firstWhere(
        (s) => s.id == _selectedSoilId,
        orElse: () => Soil(id: '', name: 'Soil', components: _components),
      );
      components = soil.components;
      title = soil.name.isEmpty ? 'Soil composition' : soil.name;
    } else {
      components = _components;
      title = _saveMix && _mixNameController.text.trim().isNotEmpty
          ? _mixNameController.text.trim()
          : 'Custom mix';
    }

    await showSoilCompositionDialog(
      context: context,
      title: title,
      components: components,
    );
  }

  bool get _canSave {
    if (_saving) return false;
    if (_mode == _SoilMode.saved) {
      return _selectedSoilId != null && _components.isNotEmpty;
    }
    if (_components.isEmpty) return false;
    if (_saveMix && _mixNameController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() => _saving = true);

    try {
      String? soilId = _mode == _SoilMode.saved ? _selectedSoilId : null;
      String? soilName;

      if (_mode == _SoilMode.saved && soilId != null) {
        final soil = await _soilService.getSoil(soilId);
        soilName = soil?.name;
      }

      if (_mode == _SoilMode.newMix && _saveMix) {
        final name = _mixNameController.text.trim();
        soilId = await _soilService.addSoil(
          name: name,
          components: _components,
        );
        soilName = name;
      }

      await _repottingService.addRepotting(
        plantId: widget.plantId,
        repottedAt: _selectedDate,
        components: _components,
        soilId: soilId,
        soilName: soilName,
      );

      if (!mounted) return;
      Navigator.pop(context);
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
              const Text(
                'Add Repotting',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              SegmentedButton<_SoilMode>(
                segments: const [
                  ButtonSegment(
                    value: _SoilMode.saved,
                    label: Text('Saved soil'),
                    icon: Icon(Icons.bookmark_outline),
                  ),
                  ButtonSegment(
                    value: _SoilMode.newMix,
                    label: Text('New mix'),
                    icon: Icon(Icons.science_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (value) {
                  setState(() {
                    _mode = value.first;
                    if (_mode == _SoilMode.newMix) {
                      _selectedSoilId = null;
                      _saveMix = false;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_mode == _SoilMode.saved)
                StreamBuilder<List<Soil>>(
                  stream: _soilService.getSoils(),
                  builder: (context, snapshot) {
                    final soils = snapshot.data ?? const <Soil>[];

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (soils.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No saved soils yet. Create a new mix.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _mode = _SoilMode.newMix);
                            },
                            child: const Text('Switch to New mix'),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedSoilId,
                            hint: const Text('Select soil'),
                            isExpanded: true,
                            items: soils
                                .map(
                                  (soil) => DropdownMenuItem(
                                    value: soil.id,
                                    child: Text(soil.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              final soil =
                                  soils.firstWhere((s) => s.id == value);
                              _applySavedSoil(soil);
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'View composition',
                          onPressed: _selectedSoilId == null
                              ? null
                              : () => _showSelectedComposition(soils),
                          icon: const Icon(Icons.info_outline),
                        ),
                      ],
                    );
                  },
                ),
              if (_mode == _SoilMode.newMix) ...[
                Row(
                  children: [
                    const Text(
                      'Components',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _openManageComponents,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
                StreamBuilder<List<CatalogComponent>>(
                  stream: _componentService.getComponents(),
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

                    return SoilComponentTags(
                      availableComponents: _catalogNames,
                      selected: _components,
                      onChanged: (next) => setState(() => _components = next),
                      onAddCustom: _addCustomComponent,
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap: +1 part · Long press: ½ part (again removes)',
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
                      hintText: 'e.g. Aroid mix',
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
