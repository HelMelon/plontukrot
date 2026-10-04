import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/accessible_progress_indicator.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';
import '../../../../models/experiment_subject.dart';
import '../../../../models/plant.dart';
import '../../../../models/propagation.dart';
import '../../../../services/experiment_service.dart';
import '../../../../services/plant_service.dart';
import '../../../../services/propagation_service.dart';

/// Pick participants for one variant. The user chooses from their own plants
/// (archived ones excluded) or active propagation batches, already-added
/// subjects filtered out, with a text search across both lists.
class AddSubjectsSheet extends StatefulWidget {
  final String variantId;
  final Set<String> existingSubjectIds;

  const AddSubjectsSheet({
    super.key,
    required this.variantId,
    this.existingSubjectIds = const {},
  });

  @override
  State<AddSubjectsSheet> createState() => _AddSubjectsSheetState();
}

class _AddSubjectsSheetState extends State<AddSubjectsSheet> {
  final _service = ExperimentService();
  final _searchController = TextEditingController();

  List<Plant> _plants = const [];
  List<Propagation> _propagations = const [];
  bool _isLoading = true;
  String? _error;
  final _selected = <_PickerEntry>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final plants = await PlantService().getPlants().first;
      final propagations =
          await PropagationService().watchActivePropagations().first;
      if (!mounted) return;
      setState(() {
        _plants = plants.where((plant) => !plant.isArchived).toList();
        _propagations =
            propagations.where((batch) => batch.quantityAlive > 0).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  bool _isAlreadyAdded(ExperimentSubjectType type, String id) =>
      widget.existingSubjectIds.contains('${type.code}:$id');

  String _plantName(Plant plant) {
    final nickname = plant.nickname.trim();
    if (nickname.isNotEmpty) return nickname;
    final trading = plant.tradingName.trim();
    if (trading.isNotEmpty) return trading;
    final species = plant.species.trim();
    return species.isEmpty ? plant.id : species;
  }

  String _plantSubtitle(Plant plant) {
    final parts = [plant.genus, plant.cultivar ?? '']
        .where((part) => part.trim().isNotEmpty)
        .toList();
    return parts.join(' · ');
  }

  String _propagationName(Propagation batch) {
    final parent = batch.parentPlantName.trim();
    return parent.isEmpty ? batch.parentPlantFamily : parent;
  }

  void _toggle(_PickerEntry entry) {
    setState(() {
      final index = _selected.indexWhere(
        (item) => item.type == entry.type && item.id == entry.id,
      );
      if (index >= 0) {
        _selected.removeAt(index);
      } else {
        _selected.add(entry);
      }
    });
  }

  bool _isSelected(_PickerEntry entry) => _selected.any(
        (item) => item.type == entry.type && item.id == entry.id,
      );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_selected.isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      for (final entry in _selected) {
        await _service.addSubject(
          variantId: widget.variantId,
          subjectType: entry.type,
          subjectId: entry.id,
          subjectName: entry.name,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
    final query = _searchController.text.trim().toLowerCase();

    final plantEntries = _plants
        .map((plant) => _PickerEntry(
              type: ExperimentSubjectType.plant,
              id: plant.id,
              name: _plantName(plant),
              subtitle: _plantSubtitle(plant),
              imageUrl: plant.listImageUrl,
            ))
        .where((entry) =>
            query.isEmpty || entry.name.toLowerCase().contains(query))
        .toList();
    final propagationEntries = _propagations
        .map((batch) => _PickerEntry(
              type: ExperimentSubjectType.propagation,
              id: batch.id,
              name: _propagationName(batch),
              subtitle: '${batch.quantityAlive}',
            ))
        .where((entry) =>
            query.isEmpty || entry.name.toLowerCase().contains(query))
        .toList();

    return SizedBox(
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
              child: Padding(
                padding: sheets.contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.experimentsAddSubjectTitle,
                      style: typography.titleLarge.copyWith(letterSpacing: -1),
                    ),
                    spacing.vXs,
                    Text(
                      l10n.experimentsSubjectsHint,
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    spacing.vMd,
                    TextField(
                      controller: _searchController,
                      style: inputs.textStyle,
                      onChanged: (_) => setState(() {}),
                      decoration: inputs.decoration(
                        labelText: l10n.experimentsSearchSubject,
                        prefixIcon: Icon(context.icons.search),
                      ),
                    ),
                    spacing.vMd,
                    Expanded(child: _buildList(
                      l10n: l10n,
                      plantEntries: plantEntries,
                      propagationEntries: propagationEntries,
                    )),
                    spacing.vSm,
                    SizedBox(
                      width: double.infinity,
                      height: dimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        child: _isLoading
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList({
    required AppLocalizations l10n,
    required List<_PickerEntry> plantEntries,
    required List<_PickerEntry> propagationEntries,
  }) {
    if (_error != null) {
      return Center(
        child: SelectableText.rich(
          TextSpan(
            text: _error,
            style: TextStyle(color: context.colors.error),
          ),
        ),
      );
    }
    if (_isLoading) {
      return const Center(child: AccessibleProgressIndicator());
    }
    if (plantEntries.isEmpty && propagationEntries.isEmpty) {
      return Center(
        child: Text(
          l10n.experimentsEmpty,
          style: context.typography.bodyLarge
              .copyWith(color: context.colors.textSecondary),
        ),
      );
    }
    return ListView(
      children: [
        if (plantEntries.isNotEmpty) ...[
          _SectionHeader(text: l10n.experimentsFilterSubjectPlant),
          for (final entry in plantEntries) _tile(entry),
        ],
        if (propagationEntries.isNotEmpty) ...[
          _SectionHeader(text: l10n.experimentsFilterSubjectPropagation),
          for (final entry in propagationEntries) _tile(entry),
        ],
      ],
    );
  }

  Widget _tile(_PickerEntry entry) {
    final colors = context.colors;
    final added = _isAlreadyAdded(entry.type, entry.id);
    final selected = _isSelected(entry);
    return CheckboxListTile(
      value: added || selected,
      onChanged: added ? null : (_) => _toggle(entry),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        entry.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: added ? colors.textSecondary : colors.textPrimary,
        ),
      ),
      subtitle: entry.subtitle.isEmpty
          ? null
          : Text(
              entry.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(top: spacing.sm, bottom: spacing.xs),
      child: Text(
        text,
        style: typography.titleSmall.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

class _PickerEntry {
  final ExperimentSubjectType type;
  final String id;
  final String name;
  final String subtitle;
  final String? imageUrl;

  const _PickerEntry({
    required this.type,
    required this.id,
    required this.name,
    this.subtitle = '',
    this.imageUrl,
  });
}
