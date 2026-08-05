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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

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
        for (final stat in monthlyStats)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.xs),
            child: Text(
              l10n.plantLeafStatsMonthLine(
                _monthLabel(stat.monthStart, locale),
                stat.newLeafCount,
                stat.removedLeafCount,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.titleMedium.copyWith(
                fontWeight: FontWeight.normal,
                color: colors.heading,
              ),
            ),
          ),
      ],
    );
  }
}
