import 'package:flutter/material.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/theme/theme_context.dart';

import '../../../models/plant.dart';
import '../../../services/plant_service.dart';
import '../widgets/cards/plant_card.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

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
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.icon),
        title: Text(
          l10n.stageTitle(widget.stage),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: typography.titleMedium,
        ),
      ),
      body: StreamBuilder<List<Plant>>(
        stream: _plantsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Center(
              child: AccessibleProgressIndicator(color: colors.primary),
            );
          }

          final plants = (snapshot.data ?? [])
              .where((plant) => plant.stage == widget.stage)
              .toList();

          if (plants.isEmpty) {
            return Center(
              child: Padding(
                padding: spacing.allXl,
                child: Text(
                  l10n.plantEmptyStage,
                  textAlign: TextAlign.center,
                  style: typography.bodyLarge,
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _crossAxisCount(constraints.maxWidth);
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  spacing.md,
                  spacing.xs,
                  spacing.md,
                  spacing.xl,
                ),
                itemCount: plants.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing.sm,
                  mainAxisSpacing: spacing.md,
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
