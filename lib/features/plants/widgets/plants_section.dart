import 'package:flutter/material.dart';
import '../widgets/cards/plant_card.dart';
import '../../../services/plant_service.dart';

class PlantsSection extends StatelessWidget {
  final String searchQuery;

  const PlantsSection({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: PlantService().getPlants(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final plants = snapshot.data!.docs;

        final filtered = plants.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final name = (data['name'] ?? '').toString().toLowerCase();
          final nick = (data['nickname'] ?? '').toString().toLowerCase();

          if (searchQuery.isEmpty) return true;

          return name.contains(searchQuery) || nick.contains(searchQuery);
        }).toList();

        // if (filtered.isEmpty) {
        //   return const EmptyPlants();
        // }

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
