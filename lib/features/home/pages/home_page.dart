import 'dart:async';

import './../../../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/plant.dart';
import '../../../services/auth_service.dart';
import '../../plants/widgets/sheets/add_plant_sheet.dart';
import '../../plants/widgets/sheets/add_fertilizing_sheet.dart';
import '../../../services/plant_service.dart';
import '../../../services/watering_service.dart';
import '../../plants/widgets/cards/plant_card.dart';
import '../../plants/widgets/plant_search_delegate.dart';
import 'package:auto_size_text/auto_size_text.dart';

enum _PlantSortField {
  name,
  nickname,
  lastWateredAt,
  lastFertilizedAt,
  createdAt,
  family,
}

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<String> _selectedPlantIds = {};
  final Set<String> _visiblePlantIds = {};
  final Set<String> _collapsedLetterGroups = {};
  late final Stream<DocumentSnapshot> _userDataStream;
  late final Stream<List<Plant>> _plantsStream;
  _PlantSortField _sortField = _PlantSortField.createdAt;
  bool _sortAscending = false;
  bool _careMigrationStarted = false;

  @override
  void initState() {
    super.initState();
    _userDataStream = FirestoreService().getUserData();
    _plantsStream = PlantService().getPlants();
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
      _selectedPlantIds
        ..clear()
        ..addAll(_visiblePlantIds);
    });
  }

  void _setSortField(_PlantSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = switch (field) {
          _PlantSortField.name ||
          _PlantSortField.nickname ||
          _PlantSortField.family =>
            true,
          _ => false,
        };
      }
    });
  }

  String get _sortLabel => switch (_sortField) {
        _PlantSortField.name => 'Name',
        _PlantSortField.nickname => 'Nickname',
        _PlantSortField.lastWateredAt => 'Last watering',
        _PlantSortField.lastFertilizedAt => 'Last fertilizing',
        _PlantSortField.createdAt => 'Date added',
        _PlantSortField.family => 'Family',
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
        _PlantSortField.name =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
        _PlantSortField.nickname =>
          first.nickname.toLowerCase().compareTo(second.nickname.toLowerCase()),
        _PlantSortField.family =>
          first.family.toLowerCase().compareTo(second.family.toLowerCase()),
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
      final trimmedName = plant.name.trim();
      final firstCharacter =
          trimmedName.isEmpty ? null : trimmedName.substring(0, 1);
      final letter = firstCharacter != null &&
              RegExp(r'^[A-Za-zА-Яа-яЁё]$').hasMatch(firstCharacter)
          ? firstCharacter.toUpperCase()
          : '#';
      groups.putIfAbsent(letter, () => []).add(plant);
    }

    return groups;
  }

  void _toggleLetterGroup(String letter) {
    setState(() {
      if (!_collapsedLetterGroups.add(letter)) {
        _collapsedLetterGroups.remove(letter);
      }
    });
  }

  Widget _buildPlantGrid(List<Plant> plants, int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plants.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.60,
      ),
      itemBuilder: (context, index) {
        final plant = plants[index];
        return PlantCard(
          plant: plant,
          isSelected: _selectedPlantIds.contains(plant.id),
          onTap:
              _isSelectionMode ? () => _togglePlantSelection(plant.id) : null,
          onLongPress: () => _togglePlantSelection(plant.id),
        );
      },
    );
  }

  Future<void> _updateFamily() async {
    final controller = TextEditingController();
    final family = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change plant family'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Family'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (family == null) return;

    await PlantService().updatePlantsFamily(
      plantIds: _selectedPlantIds,
      family: family,
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

    final service = WateringService();
    await Future.wait(
      _selectedPlantIds.map(
        (plantId) => service.addWatering(
          plantId: plantId,
          wateredAt: wateredAt,
        ),
      ),
    );
    if (mounted) _exitSelectionMode();
  }

  Future<void> _showFertilizingSheet() async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFertilizingSheet(
        plantIds: _selectedPlantIds.toList(),
        title: 'Fertilize selected plants',
      ),
    );
    if (applied == true && mounted) _exitSelectionMode();
  }

  Future<void> _deletePlants() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected plants?'),
        content: Text(
          'This permanently deletes ${_selectedPlantIds.length} plant(s).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await PlantService().deletePlants(_selectedPlantIds);
    if (mounted) _exitSelectionMode();
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      leading: IconButton(
        onPressed: _exitSelectionMode,
        icon: const Icon(Icons.close),
      ),
      title: Text('${_selectedPlantIds.length} selected'),
      actions: [
        IconButton(
          tooltip: 'Select all',
          onPressed: _selectAll,
          icon: const Icon(Icons.select_all),
        ),
        IconButton(
          tooltip: 'Change family',
          onPressed: _updateFamily,
          icon: const Icon(Icons.family_restroom_outlined),
        ),
        IconButton(
          tooltip: 'Water',
          onPressed: _addWatering,
          icon: const Icon(Icons.water_drop_outlined),
        ),
        IconButton(
          tooltip: 'Fertilize',
          onPressed: _showFertilizingSheet,
          icon: const Icon(Icons.science_outlined),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed: _deletePlants,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: SizedBox(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _isSelectionMode
          ? _buildSelectionAppBar()
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
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: ClipOval(
                          child: widget.user.photoURL != null &&
                                  widget.user.photoURL!.isNotEmpty
                              ? Image.network(
                                  widget.user.photoURL!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    color: AppColors.heading,
                                  ),
                                )
                              : const Icon(Icons.person,
                                  color: AppColors.heading),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          await authService.signOut();
                        },
                        icon: const Icon(Icons.logout,
                            color: AppColors.accentLight),
                      ),
                    ],
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64.0),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 12.0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      showSearch(
                        context: context,
                        delegate: PlantSearchDelegate(userId: widget.user.uid),
                      );
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search plants...',
                          hintStyle:
                              const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.heading.withValues(alpha: 0.05),
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
              ),
            ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.goldAccent,
              foregroundColor: AppColors.dark1,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.backgroundSecondary,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  builder: (_) {
                    return const AddPlantSheet();
                  },
                );
              },
              child: const Icon(Icons.add),
            ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userDataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'No user data',
                style: TextStyle(color: AppColors.textPrimary),
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
                        child: const Column(
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              size: 48,
                              color: AppColors.accentLight,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No plants added yet',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final plants = plantSnapshot.data!;
                    if (!_careMigrationStarted &&
                        plants.any((plant) => !plant.careHistoryMigrated)) {
                      _careMigrationStarted = true;
                      unawaited(PlantService().migrateCareDates(plants));
                    }
                    final sortedPlants = _sortPlants(plants);
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

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_isSelectionMode)
                              Align(
                                alignment: Alignment.centerRight,
                                child: PopupMenuButton<_PlantSortField>(
                                  tooltip: 'Sort plants',
                                  onSelected: _setSortField,
                                  itemBuilder: (context) => _PlantSortField
                                      .values
                                      .map(
                                        (field) => PopupMenuItem(
                                          value: field,
                                          child: Row(
                                            children: [
                                              if (_sortField == field)
                                                Icon(
                                                  _sortAscending
                                                      ? Icons.arrow_upward
                                                      : Icons.arrow_downward,
                                                  size: 18,
                                                )
                                              else
                                                const SizedBox(width: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                switch (field) {
                                                  _PlantSortField.name =>
                                                    'Name',
                                                  _PlantSortField.nickname =>
                                                    'Nickname',
                                                  _PlantSortField
                                                        .lastWateredAt =>
                                                    'Last watering',
                                                  _PlantSortField
                                                        .lastFertilizedAt =>
                                                    'Last fertilizing',
                                                  _PlantSortField.createdAt =>
                                                    'Date added',
                                                  _PlantSortField.family =>
                                                    'Family',
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  child: Chip(
                                    avatar: Icon(
                                      _sortAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 18,
                                    ),
                                    label: Text('Sort: $_sortLabel'),
                                  ),
                                ),
                              ),
                            if (!_isSelectionMode) const SizedBox(height: 8),
                            if (_sortField == _PlantSortField.name)
                              ..._groupPlantsByLetter(
                                sortedPlants,
                              ).entries.map((entry) {
                                final isCollapsed =
                                    _collapsedLetterGroups.contains(entry.key);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () =>
                                            _toggleLetterGroup(entry.key),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  color: AppColors.heading,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${entry.value.length}',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              const Spacer(),
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
                              })
                            else
                              _buildPlantGrid(sortedPlants, crossAxisCount),
                          ],
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
