import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/plant_service.dart';
import 'package:flutter/services.dart';

class AddPlantSheet extends StatefulWidget {
  const AddPlantSheet({super.key});

  @override
  State<AddPlantSheet> createState() => _AddPlantSheetState();
}

class _AddPlantSheetState extends State<AddPlantSheet> {
  final nameController = TextEditingController();
  final nickNameController = TextEditingController();
  final wateringFrequencyController = TextEditingController();

  bool isLoading = false;

  Future<void> addPlant() async {
    final name = nameController.text.trim();
    final nickname = nickNameController.text.trim();
    final wateringFrequency = int.tryParse(wateringFrequencyController.text);

    if (name.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    await PlantService().addPlant(name: name, nickname: nickname);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,

        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),

      child: Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // HANDLE
              Center(
                child: Container(
                  width: 50,
                  height: 5,

                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // TITLE
              const Text(
                'Add Plant',

                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,

                  color: AppColors.heading,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Create a new entry for your collection.',

                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,

                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              // NAME FIELD
              TextField(
                controller: nameController,

                style: const TextStyle(color: AppColors.textPrimary),

                decoration: InputDecoration(
                  labelText: 'Plant name',

                  labelStyle: const TextStyle(color: AppColors.textSecondary),

                  filled: true,
                  fillColor: AppColors.dark2,

                  prefixIcon: const Icon(
                    Icons.eco,
                    color: AppColors.accentLight,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),

                    borderSide: const BorderSide(color: AppColors.greenDeep),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),

                    borderSide: const BorderSide(
                      color: AppColors.goldAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
              // NICKNAME FIELD
              TextField(
                controller: nickNameController,

                style: const TextStyle(color: AppColors.textPrimary),

                decoration: InputDecoration(
                  labelText: 'Plant nickname',

                  labelStyle: const TextStyle(color: AppColors.textSecondary),

                  filled: true,
                  fillColor: AppColors.dark2,

                  prefixIcon: const Icon(
                    Icons.local_florist,
                    color: AppColors.accentLight,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),

                    borderSide: const BorderSide(color: AppColors.greenDeep),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),

                    borderSide: const BorderSide(
                      color: AppColors.goldAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
              //wateringFrequency FIELD
              TextField(
                controller: wateringFrequencyController,
                // 1. Показывает клавиатуру с цифрами (на телефонах)
                keyboardType: TextInputType.number,

                // 2. Жестко блокирует ввод любых символов, кроме цифр
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: AppColors.textPrimary),

                decoration: InputDecoration(
                  labelText: 'Watering Frequency',

                  labelStyle: const TextStyle(color: AppColors.textSecondary),

                  filled: true,
                  fillColor: AppColors.dark2,

                  prefixIcon: const Icon(
                    Icons.water_drop,
                    color: AppColors.accentLight,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),

                    borderSide: const BorderSide(color: AppColors.greenDeep),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),

                    borderSide: const BorderSide(
                      color: AppColors.goldAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(
                  onPressed: isLoading ? null : addPlant,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: AppColors.dark1,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.dark1,
                          ),
                        )
                      : const Text(
                          'Save Plant',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
