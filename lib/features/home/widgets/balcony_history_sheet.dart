import 'package:flutter/material.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/balcony_day_temp.dart';
import 'package:plontukrot/services/balcony_service.dart';

/// Bottom sheet showing the last 3 days of balcony temperature
/// (day/night averages), styled like the leaf-stats section.
class BalconyHistorySheet extends StatefulWidget {
  const BalconyHistorySheet({super.key});

  @override
  State<BalconyHistorySheet> createState() => _BalconyHistorySheetState();
}

class _BalconyHistorySheetState extends State<BalconyHistorySheet> {
  final BalconyService _service = BalconyService();
  late final Stream<List<BalconyDayTemp>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _service.watchHistory();
  }

  String _dayLabel(AppLocalizations l10n, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    return switch (diff) {
      0 => l10n.balconyHistoryToday,
      1 => l10n.balconyHistoryYesterday,
      _ => l10n.balconyHistoryDayBefore,
    };
  }

  String _temp(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(1)}°C';
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: Text(label, style: labelStyle)),
        SizedBox(width: gap),
        // Dark pill behind the temperature value.
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.sm,
            vertical: context.spacing.xxs,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(context.radii.sm),
          ),
          child: Text(value, textAlign: TextAlign.end, style: valueStyle),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final details = context.screens.plantDetails;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, spacing.xl),
        child: StreamBuilder<List<BalconyDayTemp>>(
          stream: _historyStream,
          builder: (context, snapshot) {
            final days = snapshot.data ?? const <BalconyDayTemp>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.balconyHistoryTitle,
                  style: typography.sectionTitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                spacing.vSm,
                if (days.isEmpty)
                  Padding(
                    padding: spacing.allMd,
                    child: Text(
                      l10n.balconyHistoryNoData,
                      style: details.infoRowValueStyle,
                    ),
                  )
                else
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) spacing.vMd,
                    Text(
                      _dayLabel(l10n, days[i].day),
                      style: details.infoRowValueStyle,
                    ),
                    spacing.vXs,
                    Divider(height: 1, thickness: 1, color: colors.divider),
                    spacing.vXs,
                    _statRow(
                      label: l10n.balconyHistoryDay,
                      value: _temp(days[i].dayAvg),
                      labelStyle: details.infoRowLabelStyle,
                      valueStyle: details.infoRowValueStyle,
                      gap: spacing.sm,
                    ),
                    spacing.vXxs,
                    _statRow(
                      label: l10n.balconyHistoryNight,
                      value: _temp(days[i].nightAvg),
                      labelStyle: details.infoRowLabelStyle,
                      valueStyle: details.infoRowValueStyle,
                      gap: spacing.sm,
                    ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}
