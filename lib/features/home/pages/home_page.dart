import './../../../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../plants/widgets/add_plant_sheet.dart';
import '../../../services/plant_service.dart';
import '../../plants/widgets/plant_card.dart';

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Plant Journal',
          style: TextStyle(
            color: AppColors.heading,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await authService.signOut();
            },
            icon: const Icon(Icons.logout, color: AppColors.accentLight),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.goldAccent,
        foregroundColor: AppColors.dark1,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.backgroundSecondary,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            builder: (_) {
              return const AddPlantSheet();
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: FirestoreService().getUserData(),
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

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // USER CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark1.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // AVATAR WITH GRADIENT BORDER
                      // AVATAR WITH GUARANTEED GRADIENT BORDER
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.goldAccent,
                              AppColors.accentGreen,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            3.0,
                          ), // 👍 Толщина градиентной обводки
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors
                                  .backgroundSecondary, // 🛡️ ВАЖНО: цвет карточки, создающий контрастную подложку
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                2.0,
                              ), // 🎯 Тонкий внутренний зазор, чтобы фотка не сливалась с градиентом
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.greenDeep,
                                ),
                                child: ClipOval(
                                  child:
                                      user.photoURL != null &&
                                          user.photoURL!.isNotEmpty
                                      ? Image.network(
                                          user.photoURL!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.person,
                                                    color: AppColors.heading,
                                                    size: 35,
                                                  ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: AppColors.heading,
                                          size: 35,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // USER INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.heading,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['email'] ?? '',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // HEADER
                const Text(
                  'My Plants',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.heading,
                  ),
                ),

                const SizedBox(height: 22),

                // PLANTS STREAM
                StreamBuilder(
                  stream: PlantService().getPlants(),
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

                    if (!plantSnapshot.hasData ||
                        plantSnapshot.data!.docs.isEmpty) {
                      // 🌿 Восстановлен оборванный пустой экран
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

                    // Отображаем список карточек растений
                    final plants = plantSnapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: plants.length,
                      itemBuilder: (context, index) {
                        return PlantCard(plant: plants[index]);
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
