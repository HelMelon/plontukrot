import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/growth_event.dart';

class PlantGrowthStatsSection extends StatelessWidget {
  final List<MonthlyLeafStat> monthlyStats;

  const PlantGrowthStatsSection({
    super.key,
    required this.monthlyStats,
  });

  static String _monthLabel(DateTime monthStart, Locale locale) {
    final raw = DateFormat('LLLL', locale.toString()).format(monthStart);
    if (raw.isEmpty) return raw;
    return '${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  Widget _statRow({
    required String label,
    required String value,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
    required double gap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(label, style: labelStyle),
        ),
        SizedBox(width: gap),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: valueStyle,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final details = context.screens.plantDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.plantLeafStatsTitle,
          style: typography.sectionTitle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        spacing.vSm,
        for (var i = 0; i < monthlyStats.length; i++) ...[
          if (i > 0) spacing.vMd,
          Text(
            _monthLabel(monthlyStats[i].monthStart, locale),
            style: details.infoRowValueStyle,
          ),
          spacing.vXs,
          Divider(
            height: 1,
            thickness: 1,
            color: colors.divider,
          ),
          spacing.vXs,
          _statRow(
            label: l10n.plantLeafStatsGained,
            value: '${monthlyStats[i].newLeafCount}',
            labelStyle: details.infoRowLabelStyle,
            valueStyle: details.infoRowValueStyle,
            gap: spacing.sm,
          ),
          spacing.vXxs,
          _statRow(
            label: l10n.plantLeafStatsLost,
            value: '${monthlyStats[i].removedLeafCount}',
            labelStyle: details.infoRowLabelStyle,
            valueStyle: details.infoRowValueStyle,
            gap: spacing.sm,
          ),
        ],
      ],
    );
  }
}
