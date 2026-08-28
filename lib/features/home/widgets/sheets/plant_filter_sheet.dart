import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';
import 'package:plontukrot/core/widgets/prompt_text_dialog.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/plant.dart';
import '../../../../models/plant_filter_criteria.dart';
import '../../../../models/stage_info.dart';
import '../../../../services/plant_filter_preset_service.dart';

Future<PlantFilterCriteria?> showPlantFilterSheet({
  required BuildContext context,
  required PlantFilterCriteria initial,
  required List<Plant> plants,
  required Map<String, int> batchCounts,
  required Set<String> rerootingIds,
}) {
  return showAppModalBottomSheet<PlantFilterCriteria>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    builder: (_) => PlantFilterSheet(
      initial: initial,
      plants: plants,
      batchCounts: batchCounts,
      rerootingIds: rerootingIds,
    ),
  );
}

class PlantFilterSheet extends StatefulWidget {
  final PlantFilterCriteria initial;
  final List<Plant> plants;
  final Map<String, int> batchCounts;
  final Set<String> rerootingIds;

  const PlantFilterSheet({
    super.key,
    required this.initial,
    required this.plants,
    required this.batchCounts,
    required this.rerootingIds,
  });

  @override
  State<PlantFilterSheet> createState() => _PlantFilterSheetState();
}

class _PlantFilterSheetState extends State<PlantFilterSheet> {
  late PlantFilterCriteria _criteria;
  List<PlantFilterPreset> _presets = const [];

  @override
  void initState() {
    super.initState();
    _criteria = widget.initial;
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final list = await PlantFilterPresetService.instance.loadPresets();
    if (!mounted) return;
    setState(() {
      _presets = list;
    });
  }

  int get _matchingCount {
    return widget.plants
        .where(
          (p) => _criteria.matches(
            p,
            isPropagating: widget.batchCounts.containsKey(p.id),
            isRerooting: widget.rerootingIds.contains(p.id),
          ),
        )
        .length;
  }

  List<String> get _families {
    final families = widget.plants
        .map((p) => (p.plantFamily ?? '').trim())
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return families;
  }

  List<String> get _genera {
    final relevant = _criteria.plantFamily == null || _criteria.plantFamily!.isEmpty
        ? widget.plants
        : widget.plants.where(
            (p) => (p.plantFamily ?? '').trim() == _criteria.plantFamily,
          );
    final genera = relevant
        .map((p) => p.genus.trim())
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return genera;
  }

  List<String> get _cultivars {
    var relevant = widget.plants;
    if (_criteria.plantFamily != null && _criteria.plantFamily!.isNotEmpty) {
      relevant = relevant
          .where((p) => (p.plantFamily ?? '').trim() == _criteria.plantFamily)
          .toList();
    }
    if (_criteria.genus != null && _criteria.genus!.isNotEmpty) {
      relevant = relevant.where((p) => p.genus.trim() == _criteria.genus).toList();
    }
    final cultivars = relevant
        .expand((p) => p.cultivarLabels)
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cultivars;
  }

  List<StageInfo> get _stages {
    final presentValues = widget.plants.map((p) => p.stage).toSet();
    return stageInfos
        .where((stage) => presentValues.contains(stage.value))
        .toList();
  }

  Future<void> _saveAsPreset() async {
    final l10n = AppLocalizations.of(context);
    final name = await showPromptTextDialog(
      context: context,
      title: l10n.homeFilterPresetNameTitle,
      hintText: l10n.homeFilterPresetNameHint,
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final preset = PlantFilterPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      criteria: _criteria,
      createdAt: DateTime.now(),
    );
    await PlantFilterPresetService.instance.savePreset(preset);
    if (!mounted) return;
    setState(() {
      _presets = [preset, ..._presets.where((p) => p.id != preset.id)];
      _criteria = _criteria.copyWith(
        presetId: preset.id,
        presetName: preset.name,
      );
    });
  }

  Future<void> _confirmDeletePreset(PlantFilterPreset preset) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homeFilterDeletePresetTitle),
        content: Text(l10n.homeFilterDeletePresetConfirm(preset.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await PlantFilterPresetService.instance.deletePreset(preset.id);
      if (!mounted) return;
      setState(() {
        _presets = _presets.where((p) => p.id != preset.id).toList();
        if (_criteria.presetId == preset.id) {
          _criteria = _criteria.copyWith(
            clearPresetId: true,
            clearPresetName: true,
          );
        }
      });
    }
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    VoidCallback? onLongPress,
    Widget? avatar,
  }) {
    final chips = context.components.chips;
    final spacing = context.spacing;
    final labelStyle = chips.labelStyle.copyWith(
      color: selected ? chips.selectedForeground : chips.unselectedForeground,
      height: 1.15,
    );

    return Padding(
      padding: EdgeInsets.only(right: spacing.xs),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color:
              selected ? chips.selectedBackground : chips.unselectedBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(chips.radius),
            side: BorderSide(
              color: selected ? chips.selectedBorder : chips.unselectedBorder,
            ),
          ),
          child: InkWell(
            onTap: () => onSelected(!selected),
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(chips.radius),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.sm,
                vertical: spacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (avatar != null) ...[
                    avatar,
                    SizedBox(width: spacing.xs),
                  ],
                  Text(
                    label,
                    softWrap: false,
                    maxLines: 1,
                    style: labelStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalChipRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    final typography = context.typography;
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(
        top: context.spacing.sm,
        bottom: context.spacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: typography.label.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.9;
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final icons = context.icons;
    final matchingCount = _matchingCount;

    final families = _families;
    final genera = _genera;
    final cultivars = _cultivars;
    final stages = _stages;

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
                  // Top Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.lg,
                      spacing.sm,
                      spacing.lg,
                      0,
                    ),
                    child: Column(
                      children: [
                        const Center(child: SheetDragHandle()),
                        spacing.vXs,
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.homeFilters,
                                style: sheets.titleStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_criteria.isActive)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _criteria = PlantFilterCriteria.empty;
                                  });
                                },
                                child: Text(l10n.homeFilterReset),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: sheets.contentPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Custom Presets
                          if (_presets.isNotEmpty || _criteria.isActive) ...[
                            _buildSectionHeader(
                              l10n.homeFilterCustomPresets,
                              trailing: _criteria.isActive
                                  ? TextButton.icon(
                                      onPressed: _saveAsPreset,
                                      icon: Icon(
                                        icons.bookmarkAdd,
                                        size: dimensions.iconSm,
                                      ),
                                      label: Text(
                                        l10n.homeFilterSaveAsPreset,
                                        style: typography.bodySmall,
                                      ),
                                    )
                                  : null,
                            ),
                            if (_presets.isNotEmpty) ...[
                              _buildHorizontalChipRow([
                                for (final preset in _presets)
                                  _buildChip(
                                    label: preset.name,
                                    selected: _criteria.presetId == preset.id,
                                    avatar: Icon(
                                      icons.bookmark,
                                      size: dimensions.iconSm,
                                      color: _criteria.presetId == preset.id
                                          ? context.components.chips.selectedForeground
                                          : colors.icon,
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _criteria = preset.criteria.copyWith(
                                            presetId: preset.id,
                                            presetName: preset.name,
                                          );
                                        } else {
                                          _criteria = PlantFilterCriteria.empty;
                                        }
                                      });
                                    },
                                    onLongPress: () =>
                                        _confirmDeletePreset(preset),
                                  ),
                              ]),
                              spacing.vSm,
                            ],
                          ],

                          // 2. Statuses
                          _buildSectionHeader(l10n.homeFilterStatuses),
                          Wrap(
                            spacing: spacing.xs,
                            runSpacing: spacing.xs,
                            children: [
                              _buildChip(
                                label: l10n.homePropagation,
                                selected: _criteria.propagatingOnly,
                                avatar: HugeIcon(
                                  icon: icons.propagations,
                                  size: dimensions.iconSm,
                                  color: _criteria.propagatingOnly
                                      ? context.components.chips.selectedForeground
                                      : colors.icon,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _criteria = _criteria.copyWith(
                                      propagatingOnly: selected,
                                      clearPresetId: true,
                                      clearPresetName: true,
                                    );
                                  });
                                },
                              ),
                              _buildChip(
                                label: l10n.homeGroups,
                                selected: _criteria.groupsOnly,
                                avatar: Icon(
                                  icons.familyHub,
                                  size: dimensions.iconSm,
                                  color: _criteria.groupsOnly
                                      ? context.components.chips.selectedForeground
                                      : colors.icon,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _criteria = _criteria.copyWith(
                                      groupsOnly: selected,
                                      clearPresetId: true,
                                      clearPresetName: true,
                                    );
                                  });
                                },
                              ),
                              _buildChip(
                                label: l10n.homeReanimation,
                                selected: _criteria.rerootingOnly,
                                avatar: HugeIcon(
                                  icon: icons.rerooting,
                                  size: dimensions.iconSm,
                                  color: _criteria.rerootingOnly
                                      ? context.components.chips.selectedForeground
                                      : colors.icon,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _criteria = _criteria.copyWith(
                                      rerootingOnly: selected,
                                      clearPresetId: true,
                                      clearPresetName: true,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                          spacing.vSm,

                          // 3. Botany - Family
                          if (families.isNotEmpty) ...[
                            _buildSectionHeader(l10n.homeFilterFamily),
                            _buildHorizontalChipRow([
                              _buildChip(
                                label: l10n.homeAllFamilies,
                                selected: _criteria.plantFamily == null,
                                onSelected: (_) {
                                  setState(() {
                                    _criteria = _criteria.copyWith(
                                      clearPlantFamily: true,
                                      clearGenus: true,
                                      clearCultivar: true,
                                      clearPresetId: true,
                                      clearPresetName: true,
                                    );
                                  });
                                },
                              ),
                              for (final family in families)
                                _buildChip(
                                  label: family,
                                  selected: _criteria.plantFamily == family,
                                  onSelected: (selected) {
                                    setState(() {
                                      _criteria = _criteria.copyWith(
                                        plantFamily: selected ? family : null,
                                        clearPlantFamily: !selected,
                                        clearGenus: true,
                                        clearCultivar: true,
                                        clearPresetId: true,
                                        clearPresetName: true,
                                      );
                                    });
                                  },
                                ),
                            ]),
                            spacing.vSm,
                          ],

                          // 4. Botany - Genus
                          if (genera.isNotEmpty) ...[
                            _buildSectionHeader(l10n.homeFilterGenus),
                            _buildHorizontalChipRow([
                              _buildChip(
                                label: l10n.homeFilterAllGenera,
                                selected: _criteria.genus == null,
                                onSelected: (_) {
                                  setState(() {
                                    _criteria = _criteria.copyWith(
                                      clearGenus: true,
                                      clearCultivar: true,
                                      clearPresetId: true,
                                      clearPresetName: true,
                                    );
                                  });
                                },
                              ),
                              for (final genus in genera)
                                _buildChip(
                                  label: genus,
                                  selected: _criteria.genus == genus,
                                  onSelected: (selected) {
                                    setState(() {
                                      _criteria = _criteria.copyWith(
                                        genus: selected ? genus : null,
                                        clearGenus: !selected,
                                        clearCultivar: true,
                                        clearPresetId: true,
                                        clearPresetName: true,
                                      );
                                    });
                                  },
                                ),
                            ]),
                            spacing.vSm,
                          ],

                          // 5. Botany - Cultivar
                          if (cultivars.isNotEmpty) ...[
                            _buildSectionHeader(l10n.homeFilterCultivar),
                            _buildHorizontalChipRow([
                              _buildChip(
                                label: l10n.homeFilterAllCultivars,
                                selected: _criteria.cultivar == null,
                                onSelected: (_) {
                                  setState(() {
                                    _criteria = _criteria.copyWith(
                                      clearCultivar: true,
                                      clearPresetId: true,
                                      clearPresetName: true,
                                    );
                                  });
                                },
                              ),
                              for (final cultivar in cultivars)
                                _buildChip(
                                  label: cultivar,
                                  selected: _criteria.cultivar == cultivar,
                                  onSelected: (selected) {
                                    setState(() {
                                      _criteria = _criteria.copyWith(
                                        cultivar: selected ? cultivar : null,
                                        clearCultivar: !selected,
                                        clearPresetId: true,
                                        clearPresetName: true,
                                      );
                                    });
                                  },
                                ),
                            ]),
                            spacing.vSm,
                          ],

                          // 6. Botany - Stage
                          if (stages.isNotEmpty) ...[
                            _buildSectionHeader(l10n.homeFilterStage),
                            _buildHorizontalChipRow([
                              _buildChip(
                                label: l10n.homeAllStages,
                                selected: _criteria.stage == null,
                                onSelected: (_) {
                                  setState(() {
                                    _criteria = _criteria.copyWith(
                                      clearStage: true,
                                      clearPresetId: true,
                                      clearPresetName: true,
                                    );
                                  });
                                },
                              ),
                              for (final stage in stages)
                                _buildChip(
                                  label: l10n.stageInfoTitle(stage),
                                  selected: _criteria.stage == stage.value,
                                  onSelected: (selected) {
                                    setState(() {
                                      _criteria = _criteria.copyWith(
                                        stage: selected ? stage.value : null,
                                        clearStage: !selected,
                                        clearPresetId: true,
                                        clearPresetName: true,
                                      );
                                    });
                                  },
                                ),
                            ]),
                            spacing.vSm,
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.all(spacing.md),
                    child: SizedBox(
                      height: dimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_criteria),
                        child: Text(l10n.homeFilterApply(matchingCount)),
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
