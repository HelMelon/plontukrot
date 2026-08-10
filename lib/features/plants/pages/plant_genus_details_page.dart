import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/theme/theme_context.dart';

import '../../../models/plant.dart';
import '../../../services/plant_service.dart';
import '../widgets/cards/plant_card.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

class PlantGenusDetailsPage extends StatefulWidget {
  final String genus;
  final Stream<List<Plant>>? plantsStream;

  const PlantGenusDetailsPage({
    super.key,
    required this.genus,
    this.plantsStream,
  });

  @override
  State<PlantGenusDetailsPage> createState() => _PlantGenusDetailsPageState();
}

class _PlantGenusDetailsPageState extends State<PlantGenusDetailsPage> {
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
    final genus = widget.genus.trim();

    return Scaffold(
      backgroundColor: colors.screen,
      appBar: AppBar(
        backgroundColor: colors.screen,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.icon),
        title: Text(
          genus.isEmpty ? l10n.plantGenusFallback : genus,
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
              .where((plant) => plant.genus.trim() == genus)
              .toList();

          if (plants.isEmpty) {
            return Center(
              child: Padding(
                padding: spacing.allXl,
                child: Text(
                  l10n.plantEmptyGenus,
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
