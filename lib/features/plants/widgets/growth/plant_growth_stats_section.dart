import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.plantLeafStatsTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 12),
        for (final stat in monthlyStats)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.plantLeafStatsMonthLine(
                _monthLabel(stat.monthStart, locale),
                stat.newLeafCount,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                color: AppColors.heading,
              ),
            ),
          ),
      ],
    );
  }
}
