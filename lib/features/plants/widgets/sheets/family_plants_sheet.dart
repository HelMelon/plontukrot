import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

import '../../../../models/plant.dart';
import '../../../../services/plant_service.dart';
import '../cards/plant_card.dart';

Future<void> showFamilyPlantsSheet({
  required BuildContext context,
  required String family,
  Stream<List<Plant>>? plantsStream,
}) {
  final sheets = context.components.sheets;

  return showAppModalBottomSheet<void>(
    context: context,
    backgroundColor: sheets.background,
    isScrollControlled: true,
    enableDrag: true,
    shape: RoundedRectangleBorder(
      borderRadius: sheets.topBorderRadius,
    ),
    builder: (sheetContext) {
      return FamilyPlantsSheet(
        family: family,
        plantsStream: plantsStream,
      );
    },
  );
}

class FamilyPlantsSheet extends StatefulWidget {
  final String family;
  final Stream<List<Plant>>? plantsStream;

  const FamilyPlantsSheet({
    super.key,
    required this.family,
    this.plantsStream,
  });

  @override
  State<FamilyPlantsSheet> createState() => _FamilyPlantsSheetState();
}

class _FamilyPlantsSheetState extends State<FamilyPlantsSheet> {
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
    final family = widget.family.trim();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.md,
                spacing.sm,
                spacing.md,
                0,
              ),
              child: Column(
                children: [
                  const SheetDragHandle(),
                  spacing.vMd,
                  Text(
                    family.isEmpty
                        ? l10n.plantFamilyFallback
                        : l10n.familyPlantsSheetTitle(family),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleMedium,
                  ),
                  spacing.vMd,
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Plant>>(
                stream: _plantsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(
                      child: AccessibleProgressIndicator(color: colors.primary),
                    );
                  }

                  final plants = (snapshot.data ?? [])
                      .where(
                        (plant) =>
                            (plant.plantFamily ?? '').trim() == family,
                      )
                      .toList();

                  if (plants.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: spacing.allXl,
                        child: Text(
                          l10n.plantEmptyFamily,
                          textAlign: TextAlign.center,
                          style: typography.bodyLarge,
                        ),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          _crossAxisCount(constraints.maxWidth);
                      final isMobile = crossAxisCount <= 2;
                      final childAspectRatio = isMobile ? 0.45 : 0.625;
                      final cellWidth = (constraints.maxWidth -
                              spacing.md * 2 -
                              spacing.sm * (crossAxisCount - 1)) /
                          crossAxisCount;
                      final mainAxisExtent = PlantCard.gridMainAxisExtent(
                        context,
                        cellWidth: cellWidth,
                        compactGrid: isMobile,
                      );

                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                          spacing.md,
                          0,
                          spacing.md,
                          spacing.xl,
                        ),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing.sm,
                          mainAxisSpacing: spacing.md,
                          childAspectRatio: childAspectRatio,
                          mainAxisExtent: mainAxisExtent,
                        ),
                        itemCount: plants.length,
                        itemBuilder: (context, index) {
                          return PlantCard(plant: plants[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
