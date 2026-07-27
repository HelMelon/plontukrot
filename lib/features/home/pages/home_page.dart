import './../../../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/plant.dart';
import '../../../services/auth_service.dart';
import '../../../services/fertilize_service.dart';
import '../../plants/widgets/sheets/add_plant_sheet.dart';
import '../../../services/plant_service.dart';
import '../../../services/watering_service.dart';
import '../../plants/widgets/cards/plant_card.dart';
import '../../plants/widgets/plant_search_delegate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<String> _selectedPlantIds = {};
  final Set<String> _visiblePlantIds = {};
  late final Stream<DocumentSnapshot> _userDataStream;
  late final Stream<List<Plant>> _plantsStream;

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

  Future<String?> _showAddFertilizerDialog() async {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add fertilizer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final type = typeController.text.trim();
              if (name.isEmpty || type.isEmpty) return;

              final id = await FertilizeService().addFertilizer(
                name: name,
                type: type,
              );
              if (context.mounted) Navigator.pop(context, id);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    nameController.dispose();
    typeController.dispose();
    return result;
  }

  Future<void> _showFertilizingSheet() async {
    var selectedDate = DateTime.now();
    String? selectedFertilizerId;
    final service = FertilizeService();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Fertilize selected plants',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setModalState(() => selectedDate = date);
                    }
                  },
                ),
                StreamBuilder(
                  stream: service.getFertilizers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final fertilizers = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      initialValue: selectedFertilizerId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Fertilizer'),
                      items: fertilizers
                          .map(
                            (fertilizer) => DropdownMenuItem(
                              value: fertilizer.id,
                              child: Text(fertilizer.data()['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() => selectedFertilizerId = value);
                      },
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final fertilizerId = await _showAddFertilizerDialog();
                      if (fertilizerId != null) {
                        setModalState(
                          () => selectedFertilizerId = fertilizerId,
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add fertilizer'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selectedFertilizerId == null
                        ? null
                        : () async {
                            await Future.wait(
                              _selectedPlantIds.map(
                                (plantId) => service.addFertilizing(
                                  plantId: plantId,
                                  fertilizerId: selectedFertilizerId!,
                                  appliedAt: selectedDate,
                                ),
                              ),
                            );
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                            if (mounted) _exitSelectionMode();
                          },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                    _visiblePlantIds
                      ..clear()
                      ..addAll(plants.map((plant) => plant.id));

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
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: plants.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.60,
                              ),
                              itemBuilder: (context, index) {
                                final plant = plants[index];
                                return PlantCard(
                                  plant: plant,
                                  isSelected:
                                      _selectedPlantIds.contains(plant.id),
                                  onTap: _isSelectionMode
                                      ? () => _togglePlantSelection(plant.id)
                                      : null,
                                  onLongPress: () =>
                                      _togglePlantSelection(plant.id),
                                );
                              },
                            ),
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
