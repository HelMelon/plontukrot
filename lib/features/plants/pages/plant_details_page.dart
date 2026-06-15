import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/fertilize_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/plant_service.dart';
import '../../../services/storage_service.dart';
import '../widgets/sheets/update_plant_sheet.dart';
import '../../../services/note_service.dart';
import '../../../services/watering_service.dart';
import '../widgets/sheets/add_note_sheet.dart';
import '../widgets/plant_notes_section.dart';
import '../widgets/sheets/watering_history_sheet.dart';
import '../widgets/sheets/fertilizing_history_sheet.dart';
import '../widgets/cards/plant_image_card.dart';
import '../widgets/cards/info_card.dart';
import '../widgets/cards/plant_info_card.dart';

class PlantDetailsPage extends StatefulWidget {
  final QueryDocumentSnapshot plant;

  const PlantDetailsPage({super.key, required this.plant});

  @override
  State<PlantDetailsPage> createState() => _PlantDetailsPageState();
}

class _PlantDetailsPageState extends State<PlantDetailsPage> {
  bool isUploading = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController typeController = TextEditingController();

  String? selectedFertilizerId;

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() => isUploading = true);

    try {
      final Uint8List imageBytes = await pickedFile.readAsBytes();

      final imageUrl = await StorageService().uploadPlantImageWeb(
        imageBytes: imageBytes,
        plantId: widget.plant.id,
      );

      await PlantService().updatePlantImage(
        plantId: widget.plant.id,
        imageUrl: imageUrl,
      );
    } catch (e) {
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

  Future<void> _showAddFertilizerDialog(
    BuildContext context,
    void Function(void Function()) setModalState,
  ) async {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final service = FertilizeService();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Fertilizer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Name'),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: typeController,
                decoration: const InputDecoration(hintText: 'Type'),
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final type = typeController.text.trim();

                  if (name.isEmpty || type.isEmpty) return;

                  final newId = await service.addFertilizer(
                    name: name,
                    type: type,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);

                  setModalState(() {
                    selectedFertilizerId = newId;
                  });
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFertilizeSheet(String plantId) async {
    DateTime selectedDate = DateTime.now();
    String? selectedFertilizerId;

    final service = FertilizeService();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, color: Colors.grey),
                    const SizedBox(height: 16),

                    const Text(
                      'Add Fertilizing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 📅 DATE
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat('d MMM y').format(selectedDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    StreamBuilder(
                      stream: service.getFertilizers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final docs = snapshot.data!.docs;

                        return DropdownButton<String>(
                          value: selectedFertilizerId,
                          hint: const Text('Select fertilizer'),
                          isExpanded: true,
                          items: [
                            ...docs.map((doc) {
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(doc['name']),
                              );
                            }),

                            const DropdownMenuItem(
                              value: 'add_new',
                              child: Text('+ Add new fertilizer'),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == 'add_new') {
                              await _showAddFertilizerDialog(
                                context,
                                setModalState,
                              );
                              return;
                            }

                            setModalState(() {
                              selectedFertilizerId = value;
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    FilledButton(
                      onPressed: selectedFertilizerId == null
                          ? null
                          : () async {
                              await service.addFertilizing(
                                plantId: plantId,
                                fertilizerId: selectedFertilizerId!,
                                appliedAt: selectedDate,
                              );

                              if (mounted) Navigator.pop(context);
                            },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('plants')
          .doc(widget.plant.id)
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
        final hasImage = imageUrl != null && imageUrl.isNotEmpty;

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
                        WateringHistorySheet(plantId: widget.plant.id),
                  );
                },
              ),

              _TopAction(
                icon: Icons.science_outlined,
                label: 'Fertilize',
                onTap: () => _showFertilizeSheet(widget.plant.id),
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
                        UpdatePlantSheet(plantId: widget.plant.id, plant: data),
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
                    builder: (_) => AddNoteSheet(plantId: widget.plant.id),
                  );
                },
              ),
            ], // Конец списка actions
          ),

          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),

                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),

                    child: isWide
                        /// 💻 WEB / TABLET
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Expanded(
                                flex: 3, // 🔥 картинка меньше
                                child: PlantImageCard(
                                  imageUrl: hasImage ? imageUrl! : '',
                                  onTap: pickAndUploadImage,
                                  isUploading: isUploading,
                                ),
                              ),

                              const SizedBox(width: 20),

                              Expanded(
                                flex: 5,
                                child: PlantInfoCard(
                                  data: data,
                                  plantId: widget.plant.id,
                                ),
                              ),
                            ],
                          )
                        /// 📱 MOBILE
                        : Column(
                            children: [
                              PlantImageCard(
                                imageUrl: hasImage ? imageUrl! : '',
                                onTap: pickAndUploadImage,
                                isUploading: isUploading,
                              ),

                              const SizedBox(height: 24),

                              PlantInfoCard(
                                data: data,
                                plantId: widget.plant.id,
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
