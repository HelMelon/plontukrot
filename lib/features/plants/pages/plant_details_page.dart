import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/growth_event.dart';
import '../../../models/plant.dart';
import '../../../services/growth_event_service.dart';
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
import '../widgets/growth/plant_leaf_counter.dart';
import '../widgets/growth/plant_vine_painter.dart';
import 'package:hugeicons/hugeicons.dart';

class PlantDetailsPage extends StatefulWidget {
  final String plantId;

  const PlantDetailsPage({super.key, required this.plantId});

  @override
  State<PlantDetailsPage> createState() => _PlantDetailsPageState();
}

class _PlantDetailsPageState extends State<PlantDetailsPage> {
  bool isUploading = false;
  bool _growthBusy = false;
  late final PlantService _plantService;
  late final GrowthEventService _growthEventService;
  late final Stream<Plant?> _plantStream;
  late final Stream<List<GrowthEvent>> _growthStream;
  final GlobalKey _growthStatsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _plantService = PlantService();
    _growthEventService = GrowthEventService();
    _plantStream = _plantService.watchPlant(widget.plantId);
    _growthStream = _growthEventService.watchGrowthEvents(widget.plantId);
    _growthEventService.purgeExpired(widget.plantId);
  }

  Future<ImageSource?> selectImageSource() async {
    final l10n = AppLocalizations.of(context);
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
                title: Text(l10n.plantGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.plantCamera),
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

      final upload = await StorageService().uploadPlantImages(
        imageBytes: imageBytes,
        plantId: widget.plantId,
      );

      await _plantService.updatePlantImage(
        plantId: widget.plantId,
        imageUrl: upload.imageUrl,
        imageThumbUrl: upload.imageThumbUrl,
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.dark2,
          content: Text(
            l10n.plantUploadError(e.toString()),
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
      enableDrag: true,
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
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => AddRepottingSheet.forPlant(plantId: widget.plantId),
    );
  }

  void _openPropagation(Plant plant) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPropagationSheet(
        parentPlantId: widget.plantId,
        parentPlantName:
            plant.species.isNotEmpty ? plant.species : l10n.commonUntitled,
        parentPlantFamily: plant.plantFamily ?? '',
      ),
    );
  }

  void _openUpdatePlant(Plant plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
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

  Future<void> _scrollToGrowthStats() async {
    final targetContext = _growthStatsKey.currentContext;
    if (targetContext == null) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _addLeaf() async {
    if (_growthBusy) return;
    setState(() => _growthBusy = true);
    try {
      await _growthEventService.addNewLeaf(widget.plantId);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _growthBusy = false);
    }
  }

  Future<void> _removeLeaf(int displayCount) async {
    if (_growthBusy || displayCount <= 0) return;
    setState(() => _growthBusy = true);
    try {
      await _growthEventService.removeLeaf(
        widget.plantId,
        currentDisplayCount: displayCount,
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _growthBusy = false);
    }
  }

  Widget _buildDetailsBody({
    required Plant plant,
    required List<GrowthEvent> growthEvents,
    required bool isWide,
  }) {
    final displayCount = GrowthEvent.displayLeafCount(
      initialLeafCount: plant.initialLeafCount,
      events: growthEvents,
    );
    final monthlyLeafStats = GrowthEvent.newLeavesByMonth(growthEvents);
    final imageUrl = plant.imageUrl;

    final infoCard = PlantInfoCard(
      plant: plant,
      plantId: widget.plantId,
      growthStatsKey: _growthStatsKey,
      monthlyLeafStats: monthlyLeafStats,
    );

    final counter = PlantLeafCounter(
      count: displayCount,
      busy: _growthBusy,
      onIncrement: _addLeaf,
      onDecrement: () => _removeLeaf(displayCount),
      onScrollToStats: _scrollToGrowthStats,
    );

    final vineAndBelow = PlantVineStrip(
      leafCount: displayCount,
      belowFirstRow: isWide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                counter,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                counter,
                const SizedBox(height: 16),
                infoCard,
              ],
            ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlantImageCard(
                  imageUrl: imageUrl,
                  onTap: pickAndUploadImage,
                  isUploading: isUploading,
                  aspectRatio: 0.75,
                ),
                const SizedBox(height: 8),
                vineAndBelow,
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(flex: 5, child: infoCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlantImageCard(
          imageUrl: imageUrl,
          onTap: pickAndUploadImage,
          isUploading: isUploading,
          aspectRatio: 1.0,
        ),
        const SizedBox(height: 8),
        vineAndBelow,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<Plant?>(
      stream: _plantStream,
      builder: (context, plantSnapshot) {
        if (!plantSnapshot.hasData || plantSnapshot.data == null) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            ),
          );
        }

        final plant = plantSnapshot.data!;
        final title =
            plant.nickname.isNotEmpty ? plant.nickname : l10n.plantDefaultTitle;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.heading,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Row(
                children: [
                  Expanded(
                    child: IconButton(
                      tooltip: l10n.watering,
                      onPressed: _openWateringHistory,
                      icon: const Icon(Icons.water_drop_outlined,
                          color: AppColors.goldAccent),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      tooltip: l10n.fertilizing,
                      onPressed: _openFertilizing,
                      icon: const Icon(
                        Icons.science_outlined,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      tooltip: l10n.repotting,
                      onPressed: _openRepotting,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedShovel,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      tooltip: l10n.plantPropagation,
                      onPressed: () => _openPropagation(plant),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedEcoLab01,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      tooltip: l10n.commonEdit,
                      onPressed: () => _openUpdatePlant(plant),
                      icon: const Icon(Icons.edit, color: AppColors.goldAccent),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      tooltip: l10n.plantNote,
                      onPressed: _openAddNote,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedNoteEdit,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: StreamBuilder<List<GrowthEvent>>(
            stream: _growthStream,
            builder: (context, growthSnapshot) {
              final growthEvents = growthSnapshot.data ?? const <GrowthEvent>[];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: _buildDetailsBody(
                          plant: plant,
                          growthEvents: growthEvents,
                          isWide: isWide,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
