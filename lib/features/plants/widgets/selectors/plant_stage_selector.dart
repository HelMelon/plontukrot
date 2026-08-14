import 'package:flutter/material.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/stage_info.dart';

class PlantStageSelector extends StatelessWidget {
  final int selectedStage;
  final ValueChanged<int> onChanged;

  const PlantStageSelector({
    super.key,
    required this.selectedStage,
    required this.onChanged,
  });

  bool _hasStageDescription(int stage) => stage >= 1 && stage <= 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final stage = stageInfos.firstWhere(
      (e) => e.value == selectedStage,
      orElse: () => stageInfos.first,
    );
    final showDescription = _hasStageDescription(selectedStage);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 700 ||
            MediaQuery.of(context).orientation == Orientation.landscape;

        if (horizontal) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: showDescription ? 2 : 1,
                child: _buildSelector(l10n),
              ),
              if (showDescription) ...[
                SizedBox(width: spacing.xl),
                Expanded(
                  flex: 3,
                  child: _buildDescription(stage, context, l10n),
                ),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelector(l10n),
            if (showDescription) ...[
              spacing.vMd,
              _buildDescription(stage, context, l10n),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSelector(AppLocalizations l10n) {
    return RadioGroup<int>(
      groupValue: selectedStage,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      child: Column(
        children: stageInfos.map((item) {
          return RadioListTile<int>(
            value: item.value,
            title: Text(l10n.stageInfoTitle(item)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDescription(
    StageInfo stage,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final spacing = context.spacing;
    final typography = context.typography;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.only(bottom: spacing.xs),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        l10n.stageDescriptionTitle,
        style: typography.label.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...l10n.stageChecklist(stage.value).map(
                    (text) => Padding(
                      padding: EdgeInsets.only(bottom: spacing.xxs + 1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: typography.bodyLarge),
                          Expanded(
                            child: Text(text, style: typography.bodyLarge),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
