import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/theme/app_colors.dart';
import '../../../models/plant.dart';
import '../../../services/plant_service.dart';
import '../../../services/storage_service.dart';
import '../widgets/sheets/update_plant_sheet.dart';
import '../widgets/sheets/add_note_sheet.dart';
import '../widgets/sheets/add_propagation_sheet.dart';
import '../widgets/sheets/watering_history_sheet.dart';
import '../widgets/sheets/add_repotting_sheet.dart';
import '../widgets/sheets/add_fertilizing_sheet.dart';
import '../widgets/cards/plant_image_card.dart';
import '../widgets/cards/plant_info_card.dart';

class PlantDetailsPage extends StatefulWidget {
  final String plantId;

  const PlantDetailsPage({super.key, required this.plantId});

  @override
  State<PlantDetailsPage> createState() => _PlantDetailsPageState();
}

class _PlantDetailsPageState extends State<PlantDetailsPage> {
  bool isUploading = false;
  late final PlantService _plantService;
  late final Stream<Plant?> _plantStream;

  @override
  void initState() {
    super.initState();
    _plantService = PlantService();
    _plantStream = _plantService.watchPlant(widget.plantId);
  }

  Future<ImageSource?> selectImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.dark2,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Галерея'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Камера'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> pickAndUploadImage() async {
    final source = await selectImageSource();
    if (source == null) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (pickedFile == null) return;

    setState(() => isUploading = true);

    try {
      final Uint8List imageBytes = await pickedFile.readAsBytes();

      final imageUrl = await StorageService().uploadPlantImageWeb(
        imageBytes: imageBytes,
        plantId: widget.plantId,
      );

      await _plantService.updatePlantImage(
        plantId: widget.plantId,
        imageUrl: imageUrl,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.dark2,
          content: Text(
            'Ошибка загрузки: $e',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  void _openWateringHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WateringHistorySheet(plantId: widget.plantId),
    );
  }

  void _openFertilizing() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFertilizingSheet.forPlant(plantId: widget.plantId),
    );
  }

  void _openRepotting() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddRepottingSheet(plantId: widget.plantId),
    );
  }

  void _openPropagation(Plant plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPropagationSheet(
        parentPlantId: widget.plantId,
        parentPlantName: plant.name.isNotEmpty ? plant.name : 'Без названия',
        parentPlantFamily: plant.family,
      ),
    );
  }

  void _openUpdatePlant(Plant plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdatePlantSheet(plantId: widget.plantId, plant: plant),
    );
  }

  void _openAddNote() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddNoteSheet(plantId: widget.plantId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Plant?>(
      stream: _plantStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            ),
          );
        }

        final plant = snapshot.data!;
        final imageUrl = plant.imageUrl;
        final title = plant.nickname.isNotEmpty ? plant.nickname : 'Растение';

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.heading,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Полив',
                onPressed: _openWateringHistory,
                icon: const Icon(Icons.water_drop, color: AppColors.goldAccent),
              ),
              IconButton(
                tooltip: 'Подкормка',
                onPressed: _openFertilizing,
                icon: const Icon(
                  Icons.science_outlined,
                  color: AppColors.goldAccent,
                ),
              ),
              IconButton(
                tooltip: 'Пересадка',
                onPressed: _openRepotting,
                icon: const Icon(Icons.flaky, color: AppColors.goldAccent),
              ),
              PopupMenuButton<_PlantDetailsMenuAction>(
                tooltip: 'Ещё',
                icon: const Icon(Icons.more_vert, color: AppColors.goldAccent),
                onSelected: (action) {
                  switch (action) {
                    case _PlantDetailsMenuAction.propagation:
                      _openPropagation(plant);
                    case _PlantDetailsMenuAction.edit:
                      _openUpdatePlant(plant);
                    case _PlantDetailsMenuAction.note:
                      _openAddNote();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _PlantDetailsMenuAction.propagation,
                    child: Text('Размножение'),
                  ),
                  PopupMenuItem(
                    value: _PlantDetailsMenuAction.edit,
                    child: Text('Изменить'),
                  ),
                  PopupMenuItem(
                    value: _PlantDetailsMenuAction.note,
                    child: Text('Заметка'),
                  ),
                ],
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: PlantImageCard(
                                  imageUrl: imageUrl,
                                  onTap: pickAndUploadImage,
                                  isUploading: isUploading,
                                  aspectRatio: 0.75,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 5,
                                child: PlantInfoCard(
                                  plant: plant,
                                  plantId: widget.plantId,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PlantImageCard(
                                imageUrl: imageUrl,
                                onTap: pickAndUploadImage,
                                isUploading: isUploading,
                                aspectRatio: 1.0,
                              ),
                              const SizedBox(height: 24),
                              PlantInfoCard(
                                plant: plant,
                                plantId: widget.plantId,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

enum _PlantDetailsMenuAction { propagation, edit, note }
