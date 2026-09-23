import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/features/feature_flags.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/core/widgets/app_bar_chrome_actions.dart';

import '../../../models/plant.dart';
import '../widgets/cards/family_care_guide_card.dart';
import '../widgets/sheets/family_plants_sheet.dart';

class PlantFamilyDetailsPage extends StatelessWidget {
  final String family;
  final Stream<List<Plant>>? plantsStream;

  const PlantFamilyDetailsPage({
    super.key,
    required this.family,
    this.plantsStream,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final familyName = family.trim();
    final careEnabled =
        FeatureFlagsController.instance.isEnabled(FeatureFlag.genusCare);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.icon),
        title: Text(
          familyName.isEmpty ? l10n.plantFamilyFallback : familyName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: typography.titleMedium,
        ),
        actions: buildAppBarChromeActions(context),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          spacing.md,
          spacing.xs,
          spacing.md,
          spacing.xl,
        ),
        children: [
          if (familyName.isNotEmpty && careEnabled)
            FamilyCareGuideCard(family: familyName),
          if (familyName.isNotEmpty && careEnabled) spacing.vMd,
          Semantics(
            button: true,
            label: l10n.familyPlantsButton,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: familyName.isEmpty
                    ? null
                    : () {
                        showFamilyPlantsSheet(
                          context: context,
                          family: familyName,
                          plantsStream: plantsStream,
                        );
                      },
                icon: Icon(context.icons.family),
                label: Text(l10n.familyPlantsButton),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
