import 'package:flutter/material.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/plant.dart';
import '../../../services/plant_service.dart';
import '../widgets/cards/plant_card.dart';

class PlantStageDetailsPage extends StatefulWidget {
  final int stage;
  final Stream<List<Plant>>? plantsStream;

  const PlantStageDetailsPage({
    super.key,
    required this.stage,
    this.plantsStream,
  });

  @override
  State<PlantStageDetailsPage> createState() => _PlantStageDetailsPageState();
}

class _PlantStageDetailsPageState extends State<PlantStageDetailsPage> {
  late final Stream<List<Plant>> _plantsStream;

  @override
  void initState() {
    super.initState();
    _plantsStream = widget.plantsStream ?? PlantService().getPlants();
  }

  int _crossAxisCount(double width) {
    if (width >= 1100) return 6;
    if (width >= 700) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.heading),
        title: Text(
          l10n.stageTitle(widget.stage),
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
              .where((plant) => plant.stage == widget.stage)
              .toList();

          if (plants.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.plantEmptyStage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
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
