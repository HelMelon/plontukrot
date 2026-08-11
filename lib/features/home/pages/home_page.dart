import 'dart:async';

import './../../../services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/core/theme/tokens/app_color_tokens.dart';
import 'package:plontukrot/core/theme/tokens/app_dimension_tokens.dart';
import 'package:plontukrot/core/theme/tokens/app_radii_tokens.dart';
import 'package:plontukrot/core/theme/tokens/app_spacing_tokens.dart';
import 'package:plontukrot/core/theme/tokens/app_typography_tokens.dart';
import 'package:plontukrot/core/theme/screens/app_screen_themes.dart';
import '../../../core/widgets/app_bar_chrome_actions.dart';
import '../../../core/widgets/prompt_text_dialog.dart';
import '../../../models/app_user.dart';
import '../../../models/plant.dart';
import '../../../models/stage_info.dart';
import '../../plants/widgets/sheets/add_plant_sheet.dart';
import '../../plants/widgets/sheets/add_fertilizing_sheet.dart';
import '../../plants/widgets/sheets/add_repotting_sheet.dart';
import '../../plants/widgets/sheets/merge_plant_sheet.dart';
import '../../../services/plant_service.dart';
import '../../../services/propagation_service.dart';
import '../../../services/startup_warmup_service.dart';
import '../../../services/watering_service.dart';
import '../../plants/pages/plant_archive_page.dart';
import '../../plants/pages/plant_genus_details_page.dart';
import '../../plants/pages/plant_stage_details_page.dart';
import '../../plants/widgets/cards/plant_card.dart';
import '../../finances/pages/finances_page.dart';
import '../../propagations/pages/propagations_page.dart';
import '../../wish_list/pages/wish_list_page.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

enum _PlantSortField {
  species,
  nickname,
  lastWateredAt,
  lastFertilizedAt,
  createdAt,
  plantFamily,
}

class HomePage extends StatefulWidget {
  final AppUser user;

  /// Fired once when the first Home content (grid or empty) is loaded,
  /// images are precached, and at least one frame has been painted.
  /// Used by cold-start splash to reveal only a ready Home.
  final VoidCallback? onFirstContentReady;

  const HomePage({
    super.key,
    required this.user,
    this.onFirstContentReady,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<String> _selectedPlantIds = {};
  final Set<String> _visiblePlantIds = {};
  final Set<String> _collapsedLetterGroups = {};
  late final Stream<bool> _userDocumentExistsStream;
  late final Stream<List<Plant>> _plantsStream;
  late final Stream<Set<String>> _activeParentPlantIdsStream;
  List<Plant> _latestPlants = const [];
  _PlantSortField _sortField = _PlantSortField.createdAt;
  bool _sortAscending = false;
  bool _filterPropagatingOnly = false;
  bool _filterGroupsOnly = false;
  String? _filterPlantFamily;
  String? _filterGenus;
  int? _filterStage;
  bool _firstContentReadySignaled = false;

  bool get _coverLoadingUi => widget.onFirstContentReady != null;

  AppColorTokens get _colors => context.colors;
  AppSpacingTokens get _spacing => context.spacing;
  AppRadiiTokens get _radii => context.radii;
  AppTypographyTokens get _typography => context.typography;
  AppDimensionTokens get _dimensions => context.dimensions;
  HomeScreenTheme get _homeTheme => context.screens.home;

  @override
  void initState() {
    super.initState();
    _userDocumentExistsStream = FirestoreService().watchUserDocumentExists();
    // Single-subscription stream for this page only. Search / genus / stage
    // open their own PlantService().getPlants() listeners — sharing a
    // broadcast without per-listener replay left them on an infinite spinner.
    _plantsStream = PlantService().getPlants();
    _activeParentPlantIdsStream =
        PropagationService().watchActiveParentPlantIds();
  }

  Future<void> _signalFirstContentReady(List<Plant> plants) async {
    if (_firstContentReadySignaled || widget.onFirstContentReady == null) {
      return;
    }
    _firstContentReadySignaled = true;
    await StartupWarmupService().precacheHomeContent(
      context,
      plants: plants,
      avatarUrl: widget.user.photoUrl,
    );
    if (!mounted) return;
    // Let PlantCard CachedNetworkImages resolve from cache and paint.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    widget.onFirstContentReady?.call();
  }

  Widget _loadingPlaceholder({required Color color}) {
    if (_coverLoadingUi) {
      return const SizedBox.shrink();
    }
    return Center(
      child: AccessibleProgressIndicator(color: color),
    );
  }

  bool get _isSelectionMode => _selectedPlantIds.isNotEmpty;

  void _togglePlantSelection(String plantId) {
    setState(() {
      if (!_selectedPlantIds.add(plantId)) {
        _selectedPlantIds.remove(plantId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(_selectedPlantIds.clear);
  }

  void _selectAll() {
    setState(() {
      final allVisibleSelected = _visiblePlantIds.isNotEmpty &&
          _visiblePlantIds.every(_selectedPlantIds.contains);
      if (allVisibleSelected) {
        _selectedPlantIds.clear();
      } else {
        _selectedPlantIds
          ..clear()
          ..addAll(_visiblePlantIds);
      }
    });
  }

  void _setSortField(_PlantSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = switch (field) {
          _PlantSortField.species ||
          _PlantSortField.nickname ||
          _PlantSortField.plantFamily =>
            true,
          _ => false,
        };
      }
    });
  }

  String _sortLabel(AppLocalizations l10n) => switch (_sortField) {
        _PlantSortField.species => l10n.homeSortSpecies,
        _PlantSortField.nickname => l10n.homeSortNickname,
        _PlantSortField.lastWateredAt => l10n.homeSortWatering,
        _PlantSortField.lastFertilizedAt => l10n.homeSortFertilizing,
        _PlantSortField.createdAt => l10n.homeSortDate,
        _PlantSortField.plantFamily => l10n.homeSortFamily,
      };

  String _sortMenuLabel(_PlantSortField field, AppLocalizations l10n) =>
      switch (field) {
        _PlantSortField.species => l10n.homeSortSpecies,
        _PlantSortField.nickname => l10n.homeSortNickname,
        _PlantSortField.lastWateredAt => l10n.homeSortLastWatered,
        _PlantSortField.lastFertilizedAt => l10n.homeSortLastFertilized,
        _PlantSortField.createdAt => l10n.homeSortDateAdded,
        _PlantSortField.plantFamily => l10n.homeSortFamily,
      };

  List<Plant> _sortPlants(Iterable<Plant> plants) {
    // Sorting by last fertilizing is only meaningful for plants that have
    // fertilizing data — skip the rest instead of dumping them at the end.
    final sortedPlants = (_sortField == _PlantSortField.lastFertilizedAt
            ? plants.where((plant) => plant.lastFertilizedAt != null)
            : plants)
        .toList();
    sortedPlants.sort((first, second) {
      if (_sortField == _PlantSortField.nickname) {
        final firstHasNickname = first.nickname.trim().isNotEmpty;
        final secondHasNickname = second.nickname.trim().isNotEmpty;

        if (firstHasNickname && !secondHasNickname) return -1;
        if (!firstHasNickname && secondHasNickname) return 1;
      }

      final dates = switch (_sortField) {
        _PlantSortField.lastWateredAt => (
            first.lastWateredAt,
            second.lastWateredAt,
          ),
        _PlantSortField.lastFertilizedAt => (
            first.lastFertilizedAt,
            second.lastFertilizedAt,
          ),
        _PlantSortField.createdAt => (first.createdAt, second.createdAt),
        _ => null,
      };
      if (dates != null && dates.$1 != null && dates.$2 == null) return -1;
      if (dates != null && dates.$1 == null && dates.$2 != null) return 1;

      var comparison = switch (_sortField) {
        _PlantSortField.species =>
          first.species.toLowerCase().compareTo(second.species.toLowerCase()),
        _PlantSortField.nickname =>
          first.nickname.toLowerCase().compareTo(second.nickname.toLowerCase()),
        _PlantSortField.plantFamily => (first.plantFamily ?? '')
            .toLowerCase()
            .compareTo((second.plantFamily ?? '').toLowerCase()),
        _PlantSortField.lastWateredAt =>
          _compareDates(first.lastWateredAt, second.lastWateredAt),
        _PlantSortField.lastFertilizedAt =>
          _compareDates(first.lastFertilizedAt, second.lastFertilizedAt),
        _PlantSortField.createdAt => _compareDates(
            first.createdAt,
            second.createdAt,
          ),
      };

      if (comparison == 0) comparison = first.id.compareTo(second.id);
      return _sortAscending ? comparison : -comparison;
    });
    return sortedPlants;
  }

  int _compareDates(DateTime? first, DateTime? second) {
    if (first == null && second == null) return 0;
    if (first == null) return 1;
    if (second == null) return -1;
    return first.compareTo(second);
  }

  Map<String, List<Plant>> _groupPlantsByLetter(Iterable<Plant> plants) {
    final groups = <String, List<Plant>>{};

    for (final plant in plants) {
      final trimmedSpecies = plant.species.trim();
      final firstCharacter =
          trimmedSpecies.isEmpty ? null : trimmedSpecies.substring(0, 1);
      final letter = firstCharacter != null &&
              RegExp(r'^[A-Za-zА-Яа-яЁё]$').hasMatch(firstCharacter)
          ? firstCharacter.toUpperCase()
          : '#';
      groups.putIfAbsent(letter, () => []).add(plant);
    }

    return groups;
  }

  Map<String, List<Plant>> _groupPlantsByFamily(Iterable<Plant> plants) {
    final groups = <String, List<Plant>>{};

    for (final plant in plants) {
      final family = (plant.plantFamily ?? '').trim();
      final key = family.isEmpty ? '' : family;
      groups.putIfAbsent(key, () => []).add(plant);
    }

    final entries = groups.entries.toList()
      ..sort((a, b) {
        if (a.key.isEmpty) return 1;
        if (b.key.isEmpty) return -1;
        final comparison = a.key.toLowerCase().compareTo(b.key.toLowerCase());
        return _sortAscending ? comparison : -comparison;
      });

    return Map.fromEntries(entries);
  }

  Map<String, List<Plant>> _groupPlantsByCareDate(
    Iterable<Plant> plants, {
    required DateTime? Function(Plant plant) dateOf,
    required String noDateLabel,
  }) {
    final groups = <String, List<Plant>>{};
    final formatter = DateFormat.yMMMMd();

    for (final plant in plants) {
      final date = dateOf(plant);
      final key = date == null
          ? noDateLabel
          : formatter.format(DateTime(date.year, date.month, date.day));
      groups.putIfAbsent(key, () => []).add(plant);
    }

    return groups;
  }

  void _toggleGroup(String key) {
    setState(() {
      if (!_collapsedLetterGroups.add(key)) {
        _collapsedLetterGroups.remove(key);
      }
    });
  }

  Widget _buildGroupedPlants(
    Map<String, List<Plant>> groups,
    int crossAxisCount, {
    required String Function(String key) titleForKey,
  }) {
    final colors = _colors;
    final spacing = _spacing;
    final radii = _radii;
    final typography = _typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        final isCollapsed = _collapsedLetterGroups.contains(entry.key);
        return Padding(
          padding: EdgeInsets.only(bottom: spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                expanded: !isCollapsed,
                label:
                    '${titleForKey(entry.key)}, ${entry.value.length}',
                child: InkWell(
                  borderRadius: radii.smAll,
                  onTap: () => _toggleGroup(entry.key),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.xxs,
                      vertical: spacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            titleForKey(entry.key),
                            style: typography.titleMedium,
                          ),
                        ),
                        spacing.hXs,
                        Text(
                          '${entry.value.length}',
                          style: typography.bodyMedium
                              .copyWith(color: colors.textSecondary),
                        ),
                        spacing.hXs,
                        ExcludeSemantics(
                          child: Icon(
                            isCollapsed
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                            color: colors.icon,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isCollapsed)
                _buildPlantGrid(
                  entry.value,
                  crossAxisCount,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlantGrid(List<Plant> plants, int crossAxisCount) {
    final preferSpeciesAsTitle = _sortField == _PlantSortField.species ||
        _sortField == _PlantSortField.plantFamily;
    final showLastFertilizer = _sortField == _PlantSortField.lastFertilizedAt;
    final childAspectRatio = showLastFertilizer ? 0.48 : 0.55;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plants.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: _spacing.sm,
        mainAxisSpacing: _spacing.md,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final plant = plants[index];
        return PlantCard(
          plant: plant,
          isSelected: _selectedPlantIds.contains(plant.id),
          preferSpeciesAsTitle: preferSpeciesAsTitle,
          showLastFertilizer: showLastFertilizer,
          onTap:
              _isSelectionMode ? () => _togglePlantSelection(plant.id) : null,
          onLongPress: () => _togglePlantSelection(plant.id),
        );
      },
    );
  }

  List<String> _uniquePlantFamilies(Iterable<Plant> plants) {
    final families = plants
        .map((plant) => (plant.plantFamily ?? '').trim())
        .where((family) => family.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return families;
  }

  List<String> _uniqueGeneraForFamily(
    Iterable<Plant> plants,
    String plantFamily,
  ) {
    final genera = plants
        .where((plant) => (plant.plantFamily ?? '').trim() == plantFamily)
        .map((plant) => plant.genus.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return genera;
  }

  List<Plant> _applyBotanicalFilters(Iterable<Plant> plants) {
    return plants.where((plant) {
      if (_filterPlantFamily != null &&
          (plant.plantFamily ?? '').trim() != _filterPlantFamily) {
        return false;
      }
      if (_filterGenus != null && plant.genus.trim() != _filterGenus) {
        return false;
      }
      if (_filterStage != null && plant.stage != _filterStage) {
        return false;
      }
      return true;
    }).toList();
  }

  void _openGenusPage(String genus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantGenusDetailsPage(genus: genus),
      ),
    );
  }

  void _openStagePage(int stage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantStageDetailsPage(stage: stage),
      ),
    );
  }

  List<StageInfo> _stagesPresentIn(Iterable<Plant> plants) {
    final presentValues = plants.map((plant) => plant.stage).toSet();
    return stageInfos
        .where((stage) => presentValues.contains(stage.value))
        .toList();
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    VoidCallback? onLongPress,
  }) {
    final chips = context.components.chips;
    final spacing = _spacing;
    final labelStyle = chips.labelStyle.copyWith(
      color: selected
          ? chips.selectedForeground
          : chips.unselectedForeground,
      height: 1.15,
    );

    // Custom chip: FilterChip's Flexible label truncates text in nested
    // horizontal scroll on web. Size to intrinsic label width instead.
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
              child: Text(
                label,
                softWrap: false,
                maxLines: 1,
                style: labelStyle,
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

  Widget _buildBotanicalFilters(List<Plant> plants, AppLocalizations l10n) {
    final families = _uniquePlantFamilies(plants);
    final genusOptions = _filterPlantFamily == null
        ? const <String>[]
        : _uniqueGeneraForFamily(plants, _filterPlantFamily!);
    final stageOptions = _stagesPresentIn(plants);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (families.isNotEmpty)
          _buildHorizontalChipRow([
            _buildFilterChip(
              label: l10n.homeAllFamilies,
              selected: _filterPlantFamily == null,
              onSelected: (_) {
                setState(() {
                  _filterPlantFamily = null;
                  _filterGenus = null;
                });
              },
            ),
            ...families.map(
              (family) => _buildFilterChip(
                label: family,
                selected: _filterPlantFamily == family,
                onSelected: (_) {
                  setState(() {
                    if (_filterPlantFamily == family) {
                      _filterPlantFamily = null;
                      _filterGenus = null;
                    } else {
                      _filterPlantFamily = family;
                      _filterGenus = null;
                    }
                  });
                },
              ),
            ),
          ]),
        if (_filterPlantFamily != null && genusOptions.isNotEmpty) ...[
          _spacing.vXs,
          _buildHorizontalChipRow([
            _buildFilterChip(
              label: l10n.homeAllGenera,
              selected: _filterGenus == null,
              onSelected: (_) {
                setState(() => _filterGenus = null);
              },
            ),
            ...genusOptions.map(
              (genus) => _buildFilterChip(
                label: genus,
                selected: _filterGenus == genus,
                onSelected: (selected) {
                  if (_filterGenus == genus) {
                    _openGenusPage(genus);
                    return;
                  }
                  setState(() {
                    _filterGenus = selected ? genus : null;
                  });
                },
                onLongPress: () => _openGenusPage(genus),
              ),
            ),
          ]),
        ],
        if (stageOptions.isNotEmpty) ...[
          if (families.isNotEmpty ||
              (_filterPlantFamily != null && genusOptions.isNotEmpty))
            _spacing.vXs,
          _buildHorizontalChipRow([
            _buildFilterChip(
              label: l10n.homeAllStages,
              selected: _filterStage == null,
              onSelected: (_) {
                setState(() => _filterStage = null);
              },
            ),
            ...stageOptions.map(
              (stage) => _buildFilterChip(
                label: l10n.stageInfoTitle(stage),
                selected: _filterStage == stage.value,
                onSelected: (selected) {
                  if (_filterStage == stage.value) {
                    _openStagePage(stage.value);
                    return;
                  }
                  setState(() {
                    _filterStage = selected ? stage.value : null;
                  });
                },
                onLongPress: () => _openStagePage(stage.value),
              ),
            ),
          ]),
        ],
      ],
    );
  }

  Future<void> _updateFamily() async {
    final l10n = AppLocalizations.of(context);
    final family = await showPromptTextDialog(
      context: context,
      title: l10n.homeUpdateFamilyTitle,
      labelText: l10n.homeFamilyLabel,
      allowEmpty: true,
    );

    if (family == null) return;

    await PlantService().updatePlantsPlantFamily(
      plantIds: _selectedPlantIds,
      plantFamily: family,
    );
    if (mounted) _exitSelectionMode();
  }

  Future<void> _addWatering() async {
    final wateredAt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (wateredAt == null) return;

    final selected = _latestPlants
        .where((plant) => _selectedPlantIds.contains(plant.id))
        .toList();
    final frequencyById = {
      for (final plant in selected) plant.id: plant.wateringFrequency,
    };
    final lastWateredById = {
      for (final plant in selected) plant.id: plant.lastWateredAt,
    };

    await WateringService().addWaterings(
      plantIds: _selectedPlantIds,
      wateredAt: wateredAt,
      wateringFrequencyByPlantId: frequencyById,
      lastWateredAtByPlantId: lastWateredById,
    );
    if (mounted) _exitSelectionMode();
  }

  Future<void> _showFertilizingSheet() async {
    final l10n = AppLocalizations.of(context);
    final selectedPlants = _latestPlants
        .where((plant) => _selectedPlantIds.contains(plant.id))
        .toList();
    final applied = await showAppModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFertilizingSheet(
        plantIds: _selectedPlantIds.toList(),
        plants: selectedPlants,
        title: l10n.homeFertilizeSelectedTitle,
      ),
    );
    if (applied == true && mounted) _exitSelectionMode();
  }

  Future<void> _showRepottingSheet() async {
    final l10n = AppLocalizations.of(context);
    final selectedPlants = _latestPlants
        .where((plant) => _selectedPlantIds.contains(plant.id))
        .toList();
    final applied = await showAppModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => AddRepottingSheet(
        plantIds: _selectedPlantIds.toList(),
        plants: selectedPlants,
        title: l10n.homeRepotSelectedTitle,
      ),
    );
    if (applied == true && mounted) _exitSelectionMode();
  }

  Future<void> _deletePlants() async {
    final l10n = AppLocalizations.of(context);
    final count = _selectedPlantIds.length;
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.homeDeleteSelectedTitle),
        content: Text(l10n.homeDeleteSelectedBodyPlural(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await PlantService().deletePlants(_selectedPlantIds);
    if (mounted) _exitSelectionMode();
  }

  Future<void> _mergePlants() async {
    final l10n = AppLocalizations.of(context);
    final selected = _latestPlants
        .where((plant) => _selectedPlantIds.contains(plant.id))
        .toList();

    if (selected.length < 2 || selected.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeMergeNeedCount)),
      );
      return;
    }

    final genera =
        selected.map((p) => p.genus.trim().toLowerCase()).toSet();
    if (genera.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeMergeNeedSameGenus)),
      );
      return;
    }

    final merged = await showAppModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MergePlantSheet(sources: selected),
    );
    if (merged == true && mounted) _exitSelectionMode();
  }

  static const double _wideBreakpoint = 700;

  AppBar _buildSelectionAppBar(AppLocalizations l10n, {required bool isWide}) {
    final allVisibleSelected = _visiblePlantIds.isNotEmpty &&
        _visiblePlantIds.every(_selectedPlantIds.contains);

    final actionButtons = <Widget>[
      IconButton(
        tooltip:
            allVisibleSelected ? l10n.homeClearSelection : l10n.homeSelectAll,
        onPressed: _selectAll,
        icon: Icon(
          allVisibleSelected ? Icons.deselect : Icons.select_all,
        ),
      ),
      IconButton(
        tooltip: l10n.homeWatering,
        onPressed: _addWatering,
        icon: const Icon(Icons.water_drop_outlined),
      ),
      IconButton(
        tooltip: l10n.homeFertilizing,
        onPressed: _showFertilizingSheet,
        icon: const Icon(Icons.science_outlined),
      ),
      IconButton(
        tooltip: l10n.homeRepotting,
        onPressed: _showRepottingSheet,
        icon: const Icon(Icons.flaky),
      ),
      IconButton(
        tooltip: l10n.homeUpdateFamily,
        onPressed: _updateFamily,
        icon: const Icon(Icons.park_outlined),
      ),
      IconButton(
        tooltip: l10n.homeMerge,
        onPressed: _mergePlants,
        icon: const Icon(Icons.merge_type),
      ),
      IconButton(
        tooltip: l10n.commonDelete,
        onPressed: _deletePlants,
        icon: const Icon(Icons.delete_outline),
      ),
    ];

    return AppBar(
      backgroundColor: _colors.screen,
      leading: IconButton(
        tooltip: l10n.a11yExitSelection,
        onPressed: _exitSelectionMode,
        icon: const Icon(Icons.close),
      ),
      title: Text(
        l10n.homeSelectedCount(_selectedPlantIds.length),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: isWide ? actionButtons : null,
      bottom: isWide
          ? null
          : PreferredSize(
              preferredSize:
                  Size.fromHeight(_spacing.xxxl + _spacing.md),
              child: Row(
                children: [
                  for (final button in actionButtons) Expanded(child: button),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildHomeHubActions(AppLocalizations l10n) {
    final colors = _colors;

    return [
      IconButton(
        tooltip: l10n.homePropagation,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PropagationsPage(),
            ),
          );
        },
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedEcoLab01,
          color: colors.icon,
        ),
      ),
      IconButton(
        tooltip: l10n.homeArchive,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PlantArchivePage(),
            ),
          );
        },
        icon: Icon(Icons.inventory_2_outlined, color: colors.icon),
      ),
      IconButton(
        tooltip: l10n.homeWishList,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const WishListPage(),
            ),
          );
        },
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedBookHeart,
          color: colors.icon,
        ),
      ),
      IconButton(
        tooltip: l10n.homeFinances,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const FinancesPage(),
            ),
          );
        },
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedCoins01,
          color: colors.icon,
        ),
      ),
    ];
  }

  AppBar _buildHomeAppBar(
    AppLocalizations l10n, {
    required bool isWide,
  }) {
    final hubActions = _buildHomeHubActions(l10n);
    final trailingActions = buildAppBarChromeActions(
      context,
      user: widget.user,
    );

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Align(
        alignment: Alignment.centerLeft,
        child: AutoSizeText(
          'Plöntukrot',
          minFontSize: 18,
          maxFontSize: 36,
          style: _homeTheme.brandStyle,
        ),
      ),
      // Title left; search + avatar (and hubs on wide) opposite side.
      actions: [
        if (isWide) ...hubActions,
        ...trailingActions,
      ],
      bottom: isWide
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(_spacing.xxxl + _spacing.md),
              child: Row(
                children: [
                  for (final action in hubActions) Expanded(child: action),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final colors = _colors;
    final spacing = _spacing;
    final radii = _radii;
    final typography = _typography;
    final dimensions = _dimensions;
    final chips = context.components.chips;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(l10n, isWide: isWide)
          : _buildHomeAppBar(l10n, isWide: isWide),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              tooltip: l10n.plantAdd,
              foregroundColor: colors.onPrimary,
              onPressed: () {
                showAppModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  enableDrag: true,
                  builder: (_) {
                    return const AddPlantSheet();
                  },
                );
              },
              child: const Icon(Icons.add),
            ),
      body: StreamBuilder<bool>(
        stream: _userDocumentExistsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingPlaceholder(color: colors.primary);
          }

          if (!snapshot.hasData || snapshot.data != true) {
            unawaited(_signalFirstContentReady(const []));
            return Center(
              child: Text(
                l10n.homeNoUserData,
                style: typography.bodyLarge,
              ),
            );
          }

          return SingleChildScrollView(
            padding: spacing.allLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<List<Plant>>(
                  stream: _plantsStream,
                  builder: (context, plantSnapshot) {
                    if (plantSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(spacing.xxxl),
                          child: _coverLoadingUi
                              ? SizedBox(
                                  height: dimensions.avatar * 3,
                                )
                              : AccessibleProgressIndicator(
                                  color: colors.primary,
                                ),
                        ),
                      );
                    }

                    if (!plantSnapshot.hasData || plantSnapshot.data!.isEmpty) {
                      unawaited(_signalFirstContentReady(const []));
                      final homeTheme = context.screens.home;
                      return Container(
                        width: double.infinity,
                        padding: homeTheme.emptyStatePadding,
                        decoration: BoxDecoration(
                          color: colors.modal,
                          borderRadius: BorderRadius.circular(
                            homeTheme.emptyStateRadius,
                          ),
                          border: Border.all(color: colors.outline),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              size: dimensions.avatar + spacing.xs,
                              color: colors.icon,
                            ),
                            spacing.vSm,
                            Text(
                              l10n.homeNoPlantsYet,
                              style: typography.bodyLarge
                                  .copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    final plants = plantSnapshot.data!;
                    _latestPlants = plants;
                    unawaited(_signalFirstContentReady(plants));

                    return StreamBuilder<Set<String>>(
                      stream: _activeParentPlantIdsStream,
                      builder: (context, propagatingSnapshot) {
                        final propagatingIds =
                            propagatingSnapshot.data ?? const <String>{};
                        var workingPlants = plants;
                        if (_filterPropagatingOnly) {
                          workingPlants = workingPlants
                              .where(
                                (plant) => propagatingIds.contains(plant.id),
                              )
                              .toList();
                        }
                        if (_filterGroupsOnly) {
                          workingPlants = workingPlants
                              .where((plant) => plant.isGroup)
                              .toList();
                        }
                        workingPlants = _applyBotanicalFilters(workingPlants);
                        final sortedPlants = _sortPlants(workingPlants);
                        _visiblePlantIds
                          ..clear()
                          ..addAll(sortedPlants.map((plant) => plant.id));

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final double screenWidth =
                                MediaQuery.of(context).size.width;

                            int crossAxisCount = 2;
                            if (screenWidth >= 1000) {
                              crossAxisCount = 6;
                            } else if (screenWidth >= 600) {
                              crossAxisCount = 4;
                            }

                            String groupTitle(String key) =>
                                key.isEmpty ? l10n.homeNoFamily : key;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isSelectionMode)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: spacing.xs,
                                          runSpacing: spacing.xs,
                                          children: [
                                            FilterChip(
                                              selected: _filterPropagatingOnly,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              label: Text(
                                                l10n.homePropagation,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              avatar: HugeIcon(
                                                icon: HugeIcons
                                                    .strokeRoundedEcoLab01,
                                                size: dimensions.iconSm,
                                                color: _filterPropagatingOnly
                                                    ? chips.selectedForeground
                                                    : colors.icon,
                                              ),
                                              selectedColor:
                                                  chips.selectedBackground,
                                              checkmarkColor: chips.checkmark,
                                              labelStyle:
                                                  chips.labelStyle.copyWith(
                                                color: _filterPropagatingOnly
                                                    ? chips.selectedForeground
                                                    : chips
                                                        .unselectedForeground,
                                                height: 1.1,
                                              ),
                                              backgroundColor:
                                                  chips.unselectedBackground,
                                              side: BorderSide(
                                                color: _filterPropagatingOnly
                                                    ? chips.selectedBorder
                                                    : chips.unselectedBorder,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  chips.radius,
                                                ),
                                              ),
                                              onSelected: (selected) {
                                                setState(() {
                                                  _filterPropagatingOnly =
                                                      selected;
                                                });
                                              },
                                            ),
                                            FilterChip(
                                              selected: _filterGroupsOnly,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              label: Text(
                                                l10n.homeGroups,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              avatar: Icon(
                                                Icons.hub_outlined,
                                                size: dimensions.iconSm,
                                                color: _filterGroupsOnly
                                                    ? chips.selectedForeground
                                                    : colors.icon,
                                              ),
                                              selectedColor:
                                                  chips.selectedBackground,
                                              checkmarkColor: chips.checkmark,
                                              labelStyle:
                                                  chips.labelStyle.copyWith(
                                                color: _filterGroupsOnly
                                                    ? chips.selectedForeground
                                                    : chips
                                                        .unselectedForeground,
                                                height: 1.1,
                                              ),
                                              backgroundColor:
                                                  chips.unselectedBackground,
                                              side: BorderSide(
                                                color: _filterGroupsOnly
                                                    ? chips.selectedBorder
                                                    : chips.unselectedBorder,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  chips.radius,
                                                ),
                                              ),
                                              onSelected: (selected) {
                                                setState(() {
                                                  _filterGroupsOnly = selected;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      spacing.hXs,
                                      PopupMenuButton<_PlantSortField>(
                                        tooltip: l10n.homeSort,
                                        onSelected: _setSortField,
                                        itemBuilder: (context) =>
                                            _PlantSortField.values
                                                .map(
                                                  (field) => PopupMenuItem(
                                                    value: field,
                                                    child: Row(
                                                      children: [
                                                        if (_sortField == field)
                                                          Icon(
                                                            _sortAscending
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward,
                                                            size: dimensions
                                                                .iconLg,
                                                          )
                                                        else
                                                          SizedBox(
                                                              width: dimensions
                                                                  .iconLg),
                                                        spacing.hXs,
                                                        Text(
                                                          _sortMenuLabel(
                                                            field,
                                                            l10n,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        child: Chip(
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          avatar: Icon(
                                            _sortAscending
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            size: dimensions.iconSm,
                                          ),
                                          label: Text(
                                            _sortLabel(l10n),
                                            overflow: TextOverflow.ellipsis,
                                            style: typography.bodySmall
                                                .copyWith(height: 1.1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (!_isSelectionMode) ...[
                                  spacing.vXs,
                                  _buildBotanicalFilters(plants, l10n),
                                  spacing.vXs,
                                ],
                                if (_filterPropagatingOnly &&
                                    !_filterGroupsOnly &&
                                    sortedPlants.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(spacing.xl),
                                    decoration: BoxDecoration(
                                      color: colors.modal,
                                      borderRadius: radii.lgAll,
                                      border: Border.all(
                                        color: colors.outline,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.homeNoPropagatingPlants,
                                      textAlign: TextAlign.center,
                                      style: typography.bodyMedium
                                          .copyWith(color: colors.textSecondary),
                                    ),
                                  )
                                else if (_filterGroupsOnly &&
                                    sortedPlants.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(spacing.xl),
                                    decoration: BoxDecoration(
                                      color: colors.modal,
                                      borderRadius: radii.lgAll,
                                      border: Border.all(
                                        color: colors.outline,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.homeNoGroupPlants,
                                      textAlign: TextAlign.center,
                                      style: typography.bodyMedium
                                          .copyWith(color: colors.textSecondary),
                                    ),
                                  )
                                else if (sortedPlants.isEmpty &&
                                    (_filterPlantFamily != null ||
                                        _filterGenus != null ||
                                        _filterStage != null))
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(spacing.xl),
                                    decoration: BoxDecoration(
                                      color: colors.modal,
                                      borderRadius: radii.lgAll,
                                      border: Border.all(
                                        color: colors.outline,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.homeNoPlantsForFilter,
                                      textAlign: TextAlign.center,
                                      style: typography.bodyMedium
                                          .copyWith(color: colors.textSecondary),
                                    ),
                                  )
                                else if (_sortField == _PlantSortField.species)
                                  _buildGroupedPlants(
                                    _groupPlantsByLetter(sortedPlants),
                                    crossAxisCount,
                                    titleForKey: (key) => key,
                                  )
                                else if (_sortField ==
                                    _PlantSortField.plantFamily)
                                  _buildGroupedPlants(
                                    _groupPlantsByFamily(sortedPlants),
                                    crossAxisCount,
                                    titleForKey: groupTitle,
                                  )
                                else if (_sortField ==
                                    _PlantSortField.lastWateredAt)
                                  _buildGroupedPlants(
                                    _groupPlantsByCareDate(
                                      sortedPlants,
                                      dateOf: (plant) => plant.lastWateredAt,
                                      noDateLabel: l10n.commonNoDate,
                                    ),
                                    crossAxisCount,
                                    titleForKey: (key) => key,
                                  )
                                else if (_sortField ==
                                    _PlantSortField.lastFertilizedAt)
                                  _buildGroupedPlants(
                                    _groupPlantsByCareDate(
                                      sortedPlants,
                                      dateOf: (plant) => plant.lastFertilizedAt,
                                      noDateLabel: l10n.commonNoDate,
                                    ),
                                    crossAxisCount,
                                    titleForKey: (key) => key,
                                  )
                                else
                                  _buildPlantGrid(
                                    sortedPlants,
                                    crossAxisCount,
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
