import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/theme/theme_context.dart';

import '../../../models/growth_event.dart';
import '../../../models/plant.dart';
import '../../../models/plant_photo.dart';
import '../../../services/growth_event_service.dart';
import '../../../services/note_service.dart';
import '../../../services/plant_service.dart';
import '../../../services/storage_service.dart';
import '../widgets/sheets/update_plant_sheet.dart';
import '../widgets/sheets/add_note_sheet.dart';
import '../widgets/sheets/add_propagation_sheet.dart';
import '../widgets/sheets/archive_plant_sheet.dart';
import '../widgets/sheets/gift_plant_sheet.dart';
import '../widgets/sheets/watering_history_sheet.dart';
import '../widgets/sheets/add_repotting_sheet.dart';
import '../widgets/sheets/add_fertilizing_sheet.dart';
import '../widgets/cards/plant_image_card.dart';
import '../widgets/cards/plant_info_card.dart';
import '../widgets/growth/plant_leaf_counter.dart';
import '../widgets/growth/plant_vine_painter.dart';
import '../widgets/growth/leaf_removal_reason_sheet.dart';
import 'plant_image_crop_page.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

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
    final sheets = context.components.sheets;
    return showAppModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: sheets.background,
      shape: RoundedRectangleBorder(
        borderRadius: sheets.topBorderRadius,
      ),
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

    final Uint8List sourceBytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    final Uint8List? croppedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => PlantImageCropPage(imageBytes: sourceBytes),
      ),
    );

    if (croppedBytes == null) return;

    setState(() => isUploading = true);

    try {
      final upload = await StorageService().uploadPlantPhoto(
        imageBytes: croppedBytes,
        plantId: widget.plantId,
      );

      await _plantService.addPlantPhoto(
        plantId: widget.plantId,
        photoId: upload.photoId,
        imageUrl: upload.imageUrl,
        imageThumbUrl: upload.imageThumbUrl,
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final colors = context.colors;
      final typography = context.typography;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.card,
          content: Text(
            l10n.plantUploadError(e.toString()),
            style: typography.bodyLarge,
          ),
        ),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> _deleteCurrentPhoto(PlantPhoto photo) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.plantPhotoDeleteTitle),
        content: Text(l10n.plantPhotoDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => isUploading = true);
    try {
      await _plantService.removePlantPhoto(
        plantId: widget.plantId,
        photoId: photo.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void _openWateringHistory() {
    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => WateringHistorySheet(plantId: widget.plantId),
    );
  }

  void _openFertilizing() {
    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFertilizingSheet.forPlant(plantId: widget.plantId),
    );
  }

  void _openRepotting() {
    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => AddRepottingSheet.forPlant(plantId: widget.plantId),
    );
  }

  void _openPropagation(Plant plant) {
    final l10n = AppLocalizations.of(context);
    showAppModalBottomSheet(
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
    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => UpdatePlantSheet(plantId: widget.plantId, plant: plant),
    );
  }

  void _openAddNote() {
    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddNoteSheet(parent: NoteParent.plant(widget.plantId)),
    );
  }

  Future<void> _openDispose(Plant plant) async {
    final archived = await showAppModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArchivePlantSheet(plant: plant),
    );
    if (archived == true && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plantDisposeArchived)),
      );
      Navigator.of(context).pop();
    }
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

  Future<void> _removeLeaf(Plant plant, int displayCount) async {
    if (_growthBusy || displayCount <= 0) return;
    final reason = await showLeafRemovalReasonSheet(context);
    if (reason == null || !mounted) return;

    setState(() => _growthBusy = true);
    try {
      await _growthEventService.removeLeaf(
        widget.plantId,
        currentDisplayCount: displayCount,
        reason: reason,
      );
      if (!mounted) return;
      if (reason == LeafRemovalReason.cutForRooting) {
        _openPropagation(plant);
      }
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
    final spacing = context.spacing;
    final displayCount = GrowthEvent.displayLeafCount(
      initialLeafCount: plant.initialLeafCount,
      events: growthEvents,
    );
    final monthlyLeafStats = GrowthEvent.leafStatsByMonth(growthEvents);
    final photos = plant.galleryPhotos;

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
      onDecrement: () => _removeLeaf(plant, displayCount),
      onScrollToStats: _scrollToGrowthStats,
    );

    final vineAndBelow = PlantVineStrip(
      leafCount: displayCount,
      belowFirstRow: isWide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                spacing.vSm,
                counter,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                spacing.vSm,
                counter,
                spacing.vMd,
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
                  photos: photos,
                  onAdd: pickAndUploadImage,
                  onDelete: _deleteCurrentPhoto,
                  isUploading: isUploading,
                  aspectRatio: 0.75,
                ),
                spacing.vXs,
                vineAndBelow,
              ],
            ),
          ),
          spacing.hLg,
          Expanded(flex: 5, child: infoCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlantImageCard(
          photos: photos,
          onAdd: pickAndUploadImage,
          onDelete: _deleteCurrentPhoto,
          isUploading: isUploading,
          aspectRatio: 1.0,
        ),
        spacing.vXs,
        vineAndBelow,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final plantDetailsTheme = context.screens.plantDetails;
    final actionIconColor = plantDetailsTheme.actionIconColor;

    return StreamBuilder<Plant?>(
      stream: _plantStream,
      builder: (context, plantSnapshot) {
        if (!plantSnapshot.hasData || plantSnapshot.data == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: AccessibleProgressIndicator(color: colors.primary),
            ),
          );
        }

        final plant = plantSnapshot.data!;
        final title =
            plant.nickname.isNotEmpty ? plant.nickname : l10n.plantDefaultTitle;
        final titleStyle = typography.titleSmall;
        final actionsBarHeight = spacing.xxxl + spacing.md;

        final actionButtons = <Widget>[
          IconButton(
            tooltip: l10n.watering,
            onPressed: _openWateringHistory,
            icon: Icon(Icons.water_drop_outlined, color: actionIconColor),
          ),
          IconButton(
            tooltip: l10n.fertilizing,
            onPressed: _openFertilizing,
            icon: Icon(
              Icons.science_outlined,
              color: actionIconColor,
            ),
          ),
          IconButton(
            tooltip: l10n.repotting,
            onPressed: _openRepotting,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShovel,
              color: actionIconColor,
            ),
          ),
          IconButton(
            tooltip: l10n.plantPropagation,
            onPressed: () => _openPropagation(plant),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedEcoLab01,
              color: actionIconColor,
            ),
          ),
          IconButton(
            tooltip: l10n.commonEdit,
            onPressed: () => _openUpdatePlant(plant),
            icon: Icon(Icons.edit, color: actionIconColor),
          ),
          IconButton(
            tooltip: l10n.plantNote,
            onPressed: _openAddNote,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedNoteEdit,
              color: actionIconColor,
            ),
          ),
          if (!plant.isArchived) ...[
            IconButton(
              tooltip: l10n.plantGift,
              onPressed: () => showGiftPlantSheet(context: context, plant: plant),
              icon: Icon(Icons.card_giftcard_outlined, color: actionIconColor),
            ),
            IconButton(
              tooltip: l10n.plantDispose,
              onPressed: () => _openDispose(plant),
              icon: Icon(Icons.archive_outlined, color: actionIconColor),
            ),
          ],
        ];

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
            // Keep actions in a dedicated bar so web/wide layouts do not clip
            // trailing icons (gift/archive) from AppBar.actions.
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(actionsBarHeight),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final usePackedRow = constraints.maxWidth >= 700;
                  if (usePackedRow) {
                    return SizedBox(
                      height: actionsBarHeight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: spacing.sm),
                        child: Row(children: actionButtons),
                      ),
                    );
                  }
                  return SizedBox(
                    height: actionsBarHeight,
                    child: Row(
                      children: [
                        for (final button in actionButtons)
                          Expanded(child: button),
                      ],
                    ),
                  );
                },
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
                    padding: EdgeInsets.all(plantDetailsTheme.sectionGap),
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
