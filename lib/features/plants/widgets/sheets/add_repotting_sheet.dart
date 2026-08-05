import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/prompt_text_dialog.dart';
import '../../../../models/catalog_component.dart';
import '../../../../models/component.dart';
import '../../../../models/plant.dart';
import '../../../../models/repotting_entry.dart';
import '../../../../models/soil.dart';
import '../../../../services/component_service.dart';
import '../../../../services/repotting_service.dart';
import '../../../../services/soil_service.dart';
import '../tags/soil_component_tags.dart';
import '../dialogs/soil_composition_dialog.dart';
import 'manage_components_sheet.dart';

enum _SoilMode { saved, newMix }

class AddRepottingSheet extends StatefulWidget {
  final List<String> plantIds;
  final List<Plant> plants;
  final String? title;
  final RepottingEntry? entry;

  const AddRepottingSheet({
    super.key,
    required this.plantIds,
    this.plants = const [],
    this.title,
    this.entry,
  });

  factory AddRepottingSheet.forPlant({
    Key? key,
    required String plantId,
    Plant? plant,
  }) {
    return AddRepottingSheet(
      key: key,
      plantIds: [plantId],
      plants: plant == null ? const [] : [plant],
    );
  }

  factory AddRepottingSheet.edit({
    Key? key,
    required String plantId,
    required RepottingEntry entry,
    Plant? plant,
  }) {
    return AddRepottingSheet(
      key: key,
      plantIds: [plantId],
      plants: plant == null ? const [] : [plant],
      entry: entry,
    );
  }

  bool get isEditing => entry != null;

  @override
  State<AddRepottingSheet> createState() => _AddRepottingSheetState();
}

class _AddRepottingSheetState extends State<AddRepottingSheet> {
  final _repottingService = RepottingService();
  final _soilService = SoilService();
  final _componentService = ComponentService();
  final _mixNameController = TextEditingController();

  late DateTime _selectedDate;
  late _SoilMode _mode;
  String? _selectedSoilId;
  late List<SoilComponent> _components;
  bool _saveMix = false;
  bool _saving = false;
  bool _slowReleaseFertilizer = false;
  List<String> _catalogNames = const [];

  @override
  void initState() {
    super.initState();
    _componentService.ensureDefaultComponents();

    final entry = widget.entry;
    if (entry != null) {
      _selectedDate = entry.repottedAt;
      _components = List.from(entry.components);
      _slowReleaseFertilizer = entry.slowReleaseFertilizer;
      if (entry.soilId != null) {
        _mode = _SoilMode.saved;
        _selectedSoilId = entry.soilId;
      } else {
        _mode = _SoilMode.newMix;
        _selectedSoilId = null;
      }
    } else {
      _selectedDate = DateTime.now();
      _mode = _SoilMode.newMix;
      _components = [];
      _slowReleaseFertilizer = false;
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

  Future<void> _addCustomComponent() async {
    final l10n = AppLocalizations.of(context);
    final name = await showPromptTextDialog(
      context: context,
      title: l10n.componentAddTitle,
      hintText: l10n.componentNameHint,
      confirmLabel: l10n.commonAdd,
    );

    if (name == null || name.isEmpty) return;

    await _componentService.ensureComponent(name: name);

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
    final l10n = AppLocalizations.of(context);
    List<SoilComponent> components;
    String title;

    if (_mode == _SoilMode.saved && _selectedSoilId != null) {
      final soil = soils.firstWhere(
        (s) => s.id == _selectedSoilId,
        orElse: () => Soil(
          id: '',
          name: l10n.repottingSoilFallback,
          components: _components,
        ),
      );
      components = soil.components;
      title = soil.name.isEmpty
          ? l10n.repottingSoilComposition
          : soil.name;
    } else {
      components = _components;
      title = _saveMix && _mixNameController.text.trim().isNotEmpty
          ? _mixNameController.text.trim()
          : l10n.soilCustomMix;
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
      if (_selectedSoilId != null && _components.isNotEmpty) return true;
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
      String? soilId = _mode == _SoilMode.saved ? _selectedSoilId : null;
      String? soilName;
      var components = _components;

      if (_mode == _SoilMode.saved && soilId != null) {
        final soil = await _soilService.getSoil(soilId);
        soilName = soil?.name ?? widget.entry?.soilName;
        if (soil != null) {
          components = List.from(soil.components);
        }
      }

      if (_mode == _SoilMode.newMix && _saveMix) {
        final name = _mixNameController.text.trim();
        soilId = await _soilService.addSoil(
          name: name,
          components: components,
        );
        soilName = name;
      }

      final entry = widget.entry;
      if (entry != null && entry.id != null) {
        await _repottingService.updateRepotting(
          plantId: widget.plantIds.first,
          repottingId: entry.id!,
          repottedAt: _selectedDate,
          components: components,
          soilId: soilId,
          soilName: soilName,
          slowReleaseFertilizer: _slowReleaseFertilizer,
        );
      } else if (widget.plantIds.length > 1) {
        final plantsById = {
          for (final plant in widget.plants) plant.id: plant,
        };
        await _repottingService.addRepottings(
          plantIds: widget.plantIds,
          repottedAt: _selectedDate,
          components: components,
          soilId: soilId,
          soilName: soilName,
          slowReleaseFertilizer: _slowReleaseFertilizer,
          lastRepottedAtByPlantId: {
            for (final id in widget.plantIds)
              id: plantsById[id]?.lastRepottedAt,
          },
        );
      } else {
        await _repottingService.addRepotting(
          plantId: widget.plantIds.first,
          repottedAt: _selectedDate,
          components: components,
          soilId: soilId,
          soilName: soilName,
          slowReleaseFertilizer: _slowReleaseFertilizer,
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
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.85;
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final inputs = context.components.inputs;
    final typography = context.typography;
    final dimensions = context.dimensions;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: colors.modal,
            borderRadius: sheets.topBorderRadius,
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  spacing.vSm,
                  Center(
                    child: Container(
                      width: sheets.handleWidth,
                      height: sheets.handleHeight,
                      decoration: BoxDecoration(
                        color: sheets.handleColor,
                        borderRadius: BorderRadius.circular(sheets.handleRadius),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        spacing.lg,
                        spacing.md,
                        spacing.lg,
                        spacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.title ??
                                (widget.isEditing
                                    ? l10n.repottingEdit
                                    : l10n.repottingAdd),
                            style: typography.titleMedium,
                          ),
                          spacing.vLg,
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today),
                            title: Text(
                                DateFormat('d MMM y').format(_selectedDate)),
                            onTap: _pickDate,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton(
                              onPressed: () => setState(
                                  () => _selectedDate = DateTime.now()),
                              child: Text(l10n.commonToday),
                            ),
                          ),
                          spacing.vMd,
                          Wrap(
                            spacing: spacing.xs,
                            runSpacing: spacing.xs,
                            children: [
                              ChoiceChip(
                                label: Text(l10n.fertilizingSaved),
                                selected: _mode == _SoilMode.saved,
                                onSelected: (_) {
                                  setState(() => _mode = _SoilMode.saved);
                                },
                              ),
                              ChoiceChip(
                                label: Text(l10n.fertilizingNewMix),
                                selected: _mode == _SoilMode.newMix,
                                onSelected: (_) {
                                  setState(() {
                                    _mode = _SoilMode.newMix;
                                    _selectedSoilId = null;
                                    _saveMix = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          spacing.vMd,
                          if (_mode == _SoilMode.saved)
                            StreamBuilder<List<Soil>>(
                              stream: _soilService.getSoils(),
                              builder: (context, snapshot) {
                                final soils = snapshot.data ?? const <Soil>[];

                                if (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    !snapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                if (soils.isEmpty) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.repottingEmptySoils,
                                        style: typography.bodySmall,
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(
                                              () => _mode = _SoilMode.newMix);
                                        },
                                        child: Text(l10n.fertilizingGoToNewMix),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButton<String>(
                                        value: soils.any(
                                                (s) => s.id == _selectedSoilId)
                                            ? _selectedSoilId
                                            : null,
                                        hint: Text(
                                          _selectedSoilId != null &&
                                                  widget.entry != null
                                              ? l10n.soilDisplayName(
                                                  widget.entry!.soilName,
                                                )
                                              : l10n.repottingSelectSoil,
                                        ),
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
                                          final soil = soils
                                              .firstWhere((s) => s.id == value);
                                          _applySavedSoil(soil);
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l10n.fertilizingViewComposition,
                                      onPressed: _selectedSoilId == null &&
                                              _components.isEmpty
                                          ? null
                                          : () =>
                                              _showSelectedComposition(soils),
                                      icon: const Icon(Icons.info_outline),
                                    ),
                                  ],
                                );
                              },
                            ),
                          if (_mode == _SoilMode.newMix) ...[
                            Row(
                              children: [
                                Text(
                                  l10n.commonComposition,
                                  style: typography.label.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _openManageComponents,
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: dimensions.iconMd,
                                  ),
                                  label: Text(l10n.commonManage),
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
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: spacing.md,
                                    ),
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }

                                final catalog = snapshot.data!;
                                _catalogNames =
                                    catalog.map((c) => c.name).toList();

                                return SoilComponentTags(
                                  availableComponents: _catalogNames,
                                  selected: _components,
                                  onChanged: (next) =>
                                      setState(() => _components = next),
                                  onAddCustom: _addCustomComponent,
                                );
                              },
                            ),
                            spacing.vXs,
                            Text(
                              l10n.repottingSoilTapHint,
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
                                  hintText: l10n.repottingMixNameHint,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                          ],
                          spacing.vSm,
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _slowReleaseFertilizer,
                            onChanged: (value) {
                              setState(
                                  () => _slowReleaseFertilizer = value ?? false);
                            },
                            title: Text(l10n.repottingSlowRelease),
                            subtitle: Text(
                              l10n.repottingSlowReleaseSubtitle,
                              style: typography.caption,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          spacing.vLg,
                          FilledButton(
                            onPressed: _canSave ? _save : null,
                            child: _saving
                                ? SizedBox(
                                    width: dimensions.iconLg,
                                    height: dimensions.iconLg,
                                    child: const CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(l10n.commonSave),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}