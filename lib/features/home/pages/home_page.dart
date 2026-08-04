import 'dart:async';

import './../../../services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/prompt_text_dialog.dart';
import '../../../models/app_user.dart';
import '../../../models/plant.dart';
import '../../../models/stage_info.dart';
import '../../../services/auth_service.dart';
import '../../plants/widgets/sheets/add_plant_sheet.dart';
import '../../plants/widgets/sheets/add_fertilizing_sheet.dart';
import '../../plants/widgets/sheets/add_repotting_sheet.dart';
import '../../../services/plant_service.dart';
import '../../../services/propagation_service.dart';
import '../../../services/watering_service.dart';
import '../../plants/pages/plant_genus_details_page.dart';
import '../../plants/pages/plant_stage_details_page.dart';
import '../../plants/widgets/cards/plant_card.dart';
import '../../plants/widgets/search/plant_search_delegate.dart';
import '../../propagations/pages/propagations_page.dart';
import '../../settings/pages/settings_page.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:hugeicons/hugeicons.dart';

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

  const HomePage({super.key, required this.user});

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
  bool _careMigrationStarted = false;
  bool _botanicalMigrationStarted = false;
  bool _filterPropagatingOnly = false;
  String? _filterPlantFamily;
  String? _filterGenus;
  int? _filterStage;

  @override
  void initState() {
    super.initState();
    _userDocumentExistsStream = FirestoreService().watchUserDocumentExists();
    _plantsStream = PlantService().getPlants().asBroadcastStream();
    _activeParentPlantIdsStream =
        PropagationService().watchActiveParentPlantIds();
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
    final sortedPlants = plants.toList();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        final isCollapsed = _collapsedLetterGroups.contains(entry.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleGroup(entry.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          titleForKey(entry.key),
                          style: const TextStyle(
                            color: AppColors.heading,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value.length}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isCollapsed
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: AppColors.heading,
                      ),
                    ],
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
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
        builder: (_) => PlantGenusDetailsPage(
          genus: genus,
          plantsStream: _plantsStream,
        ),
      ),
    );
  }

  void _openStagePage(int stage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantStageDetailsPage(
          stage: stage,
          plantsStream: _plantsStream,
        ),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: FilterChip(
          selected: selected,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          label: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
          selectedColor: AppColors.goldAccent,
          checkmarkColor: AppColors.dark1,
          labelStyle: TextStyle(
            fontSize: 13,
            color: selected ? AppColors.dark1 : AppColors.textPrimary,
          ),
          backgroundColor: AppColors.backgroundSecondary,
          side: BorderSide(
            color: selected ? AppColors.goldAccent : AppColors.greenDeep,
          ),
          onSelected: onSelected,
        ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (families.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
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
              ],
            ),
          ),
        if (_filterPlantFamily != null && genusOptions.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
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
              ],
            ),
          ),
        ],
        if (stageOptions.isNotEmpty) ...[
          if (families.isNotEmpty ||
              (_filterPlantFamily != null && genusOptions.isNotEmpty))
            const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
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
              ],
            ),
          ),
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
    final applied = await showModalBottomSheet<bool>(
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
    final applied = await showModalBottomSheet<bool>(
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
    final confirmed = await showDialog<bool>(
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

  AppBar _buildSelectionAppBar(AppLocalizations l10n) {
    final allVisibleSelected = _visiblePlantIds.isNotEmpty &&
        _visiblePlantIds.every(_selectedPlantIds.contains);

    return AppBar(
      backgroundColor: AppColors.background,
      leading: IconButton(
        onPressed: _exitSelectionMode,
        icon: const Icon(Icons.close),
      ),
      title: Text(
        l10n.homeSelectedCount(_selectedPlantIds.length),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                tooltip: allVisibleSelected
                    ? l10n.homeClearSelection
                    : l10n.homeSelectAll,
                onPressed: _selectAll,
                icon: Icon(
                  allVisibleSelected ? Icons.deselect : Icons.select_all,
                ),
              ),
            ),
            Expanded(
              child: IconButton(
                tooltip: l10n.homeWatering,
                onPressed: _addWatering,
                icon: const Icon(Icons.water_drop_outlined),
              ),
            ),
            Expanded(
              child: IconButton(
                tooltip: l10n.homeFertilizing,
                onPressed: _showFertilizingSheet,
                icon: const Icon(Icons.science_outlined),
              ),
            ),
            Expanded(
              child: IconButton(
                tooltip: l10n.homeRepotting,
                onPressed: _showRepottingSheet,
                icon: const Icon(Icons.flaky),
              ),
            ),
            Expanded(
              child: IconButton(
                tooltip: l10n.homeUpdateFamily,
                onPressed: _updateFamily,
                icon: const Icon(Icons.park_outlined),
              ),
            ),
            Expanded(
              child: IconButton(
                tooltip: l10n.commonDelete,
                onPressed: _deletePlants,
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(l10n)
          : AppBar(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              title: Align(
                alignment: Alignment.centerLeft,
                child: AutoSizeText(
                  'Plöntukrot',
                  minFontSize: 18,
                  maxFontSize: 36,
                  style: TextStyle(
                      fontFamily: 'NordicStyle',
                      color: AppColors.heading,
                      fontSize: 36),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(120),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: IconButton(
                            tooltip: l10n.homePropagation,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PropagationsPage(),
                                ),
                              );
                            },
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedEcoLab01,
                              color: AppColors.accentLight,
                            ),
                          ),
                        ),
                        Expanded(
                          child: IconButton(
                            tooltip: l10n.settingsTitle,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SettingsPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.settings,
                              color: AppColors.accentLight,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: ClipOval(
                                child: widget.user.photoUrl != null &&
                                        widget.user.photoUrl!.isNotEmpty
                                    ? Image.network(
                                        widget.user.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.person,
                                          color: AppColors.heading,
                                        ),
                                      )
                                    : const Icon(Icons.person,
                                        color: AppColors.heading),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: IconButton(
                            tooltip: l10n.authSignOut,
                            onPressed: () async {
                              await authService.signOut();
                            },
                            icon: const Icon(Icons.logout,
                                color: AppColors.accentLight),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        bottom: 12.0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          showSearch(
                            context: context,
                            delegate: PlantSearchDelegate(
                              userId: widget.user.uid,
                              plantsStream: _plantsStream,
                              searchFieldLabel: l10n.homeSearchHint,
                            ),
                          );
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: l10n.homeSearchHint,
                              hintStyle: const TextStyle(
                                  color: AppColors.textSecondary),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor:
                                  AppColors.heading.withValues(alpha: 0.05),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              foregroundColor: AppColors.dark1,
              onPressed: () {
                showModalBottomSheet(
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data != true) {
            return Center(
              child: Text(
                l10n.homeNoUserData,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<List<Plant>>(
                  stream: _plantsStream,
                  builder: (context, plantSnapshot) {
                    if (plantSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(
                            color: AppColors.goldAccent,
                          ),
                        ),
                      );
                    }

                    if (!plantSnapshot.hasData || plantSnapshot.data!.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(34),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.greenDeep),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.eco_rounded,
                              size: 48,
                              color: AppColors.accentLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.homeNoPlantsYet,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final plants = plantSnapshot.data!;
                    _latestPlants = plants;
                    if (!_careMigrationStarted &&
                        plants.any((plant) => !plant.careHistoryMigrated)) {
                      _careMigrationStarted = true;
                      unawaited(PlantService().migrateCareDates(plants));
                    }
                    if (!_botanicalMigrationStarted &&
                        plants.any(
                          (plant) => !plant.botanicalFieldsMigrated,
                        )) {
                      _botanicalMigrationStarted = true;
                      unawaited(PlantService().migrateBotanicalFields(plants));
                    }

                    return StreamBuilder<Set<String>>(
                      stream: _activeParentPlantIdsStream,
                      builder: (context, propagatingSnapshot) {
                        final propagatingIds =
                            propagatingSnapshot.data ?? const <String>{};
                        var workingPlants = _filterPropagatingOnly
                            ? plants
                                .where(
                                  (plant) => propagatingIds.contains(plant.id),
                                )
                                .toList()
                            : plants;
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
                                    children: [
                                      Flexible(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FilterChip(
                                            selected: _filterPropagatingOnly,
                                            visualDensity:
                                                VisualDensity.compact,
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
                                              size: 16,
                                              color: _filterPropagatingOnly
                                                  ? AppColors.dark1
                                                  : AppColors.accentLight,
                                            ),
                                            selectedColor: AppColors.goldAccent,
                                            checkmarkColor: AppColors.dark1,
                                            labelStyle: TextStyle(
                                              fontSize: 13,
                                              color: _filterPropagatingOnly
                                                  ? AppColors.dark1
                                                  : AppColors.textPrimary,
                                            ),
                                            backgroundColor:
                                                AppColors.backgroundSecondary,
                                            side: BorderSide(
                                              color: _filterPropagatingOnly
                                                  ? AppColors.goldAccent
                                                  : AppColors.greenDeep,
                                            ),
                                            onSelected: (selected) {
                                              setState(() {
                                                _filterPropagatingOnly =
                                                    selected;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child:
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
                                                            if (_sortField ==
                                                                field)
                                                              Icon(
                                                                _sortAscending
                                                                    ? Icons
                                                                        .arrow_upward
                                                                    : Icons
                                                                        .arrow_downward,
                                                                size: 18,
                                                              )
                                                            else
                                                              const SizedBox(
                                                                  width: 18),
                                                            const SizedBox(
                                                                width: 8),
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
                                              visualDensity:
                                                  VisualDensity.compact,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              avatar: Icon(
                                                _sortAscending
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                size: 16,
                                              ),
                                              label: Text(
                                                _sortLabel(l10n),
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (!_isSelectionMode) ...[
                                  const SizedBox(height: 8),
                                  _buildBotanicalFilters(plants, l10n),
                                  const SizedBox(height: 8),
                                ],
                                if (_filterPropagatingOnly &&
                                    sortedPlants.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundSecondary,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.greenDeep,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.homeNoPropagatingPlants,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                else if (sortedPlants.isEmpty &&
                                    (_filterPlantFamily != null ||
                                        _filterGenus != null ||
                                        _filterStage != null))
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundSecondary,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.greenDeep,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.homeNoPlantsForFilter,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
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
