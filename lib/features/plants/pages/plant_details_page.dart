import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
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

      await PlantService().updatePlantImage(
        plantId: widget.plantId,
        imageUrl: imageUrl,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.dark2,
          content: Text(
            'Upload error: $e',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('plants')
          .doc(widget.plantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final imageUrl = data['imageUrl'] as String?;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              data['nickname'] ?? 'Plant',
              style: const TextStyle(
                color: AppColors.heading,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              _TopAction(
                icon: Icons.water_drop,
                label: 'Water',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) =>
                        WateringHistorySheet(plantId: widget.plantId),
                  );
                },
              ),
              _TopAction(
                icon: Icons.science_outlined,
                label: 'Fertilize',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        AddFertilizingSheet.forPlant(plantId: widget.plantId),
                  );
                },
              ),
              _TopAction(
                icon: Icons.flaky,
                label: 'Repot',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        AddRepottingSheet(plantId: widget.plantId),
                  );
                },
              ),
              _TopAction(
                icon: Icons.spa_outlined,
                label: 'Propagate',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddPropagationSheet(
                      parentPlantId: widget.plantId,
                      parentPlantName:
                          data['name'] as String? ?? 'Unnamed Plant',
                      parentPlantFamily: data['family'] as String? ?? '',
                    ),
                  );
                },
              ),
              _TopAction(
                icon: Icons.edit_rounded,
                label: 'Edit',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) =>
                        UpdatePlantSheet(plantId: widget.plantId, plant: data),
                  );
                },
              ),
              _TopAction(
                icon: Icons.note_add_outlined,
                label: 'Note',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddNoteSheet(plantId: widget.plantId),
                  );
                },
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
                                  data: data,
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
                                data: data,
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

class _TopAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.goldAccent, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
