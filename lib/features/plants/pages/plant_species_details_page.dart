import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/plant.dart';
import '../../../services/plant_service.dart';
import '../widgets/cards/plant_card.dart';

class PlantSpeciesDetailsPage extends StatefulWidget {
  final String species;

  const PlantSpeciesDetailsPage({super.key, required this.species});

  @override
  State<PlantSpeciesDetailsPage> createState() =>
      _PlantSpeciesDetailsPageState();
}

class _PlantSpeciesDetailsPageState extends State<PlantSpeciesDetailsPage> {
  late final Stream<List<Plant>> _plantsStream;

  @override
  void initState() {
    super.initState();
    _plantsStream = PlantService().getPlants();
  }

  int _crossAxisCount(double width) {
    if (width >= 1100) return 6;
    if (width >= 700) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.species.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.heading),
        title: Text(
          species.isEmpty ? 'Вид' : species,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.heading,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Plant>>(
        stream: _plantsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            );
          }

          final plants = (snapshot.data ?? [])
              .where((plant) => plant.species.trim() == species)
              .toList();

          if (plants.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'В коллекции пока нет растений этого вида',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _crossAxisCount(constraints.maxWidth);
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: plants.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.55,
                ),
                itemBuilder: (context, index) {
                  return PlantCard(plant: plants[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}
