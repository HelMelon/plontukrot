import 'package:flutter/material.dart';

import '../../../models/plant.dart';
import '../widgets/cards/plant_card.dart';
import '../../../services/plant_service.dart';

class PlantsSection extends StatelessWidget {
  final String searchQuery;

  const PlantsSection({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Plant>>(
      stream: PlantService().getPlants(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final plants = snapshot.data!;

        final filtered = plants.where((plant) {
          final name = plant.name.toLowerCase();
          final nick = plant.nickname.toLowerCase();

          if (searchQuery.isEmpty) return true;

          return name.contains(searchQuery) || nick.contains(searchQuery);
        }).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return PlantCard(plant: filtered[index]);
          },
        );
      },
    );
  }
}
