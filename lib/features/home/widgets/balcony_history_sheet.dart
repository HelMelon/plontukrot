import 'package:flutter/material.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/balcony_day_temp.dart';
import 'package:plontukrot/services/balcony_service.dart';

/// Bottom sheet showing the last 3 days of balcony temperature.
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
    final sheets = context.components.sheets;
    final typography = context.typography;
    final details = context.screens.plantDetails;

    return Material(
      color: colors.modal,
      borderRadius: sheets.topBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: spacing.allMd,
          child: StreamBuilder<List<BalconyDayTemp>>(
            stream: _historyStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: SheetDragHandle()),
                    spacing.vMd,
                    Text(
                      l10n.balconyHistoryTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleMedium,
                    ),
                    spacing.vSm,
                    Padding(
                      padding: spacing.allMd,
                      child: Text(
                        l10n.commonError('${snapshot.error}'),
                        style: details.infoRowValueStyle.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (!snapshot.hasData) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: SheetDragHandle()),
                    spacing.vMd,
                    Text(
                      l10n.balconyHistoryTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleMedium,
                    ),
                    spacing.vSm,
                    Semantics(
                      label: l10n.loading,
                      liveRegion: true,
                      child: const _BalconyHistorySkeleton(blockCount: 3),
                    ),
                  ],
                );
              }

              final days = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: SheetDragHandle()),
                  spacing.vMd,
                  Text(
                    l10n.balconyHistoryTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleMedium,
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
      ),
    );
  }
}

/// Pulsing placeholder that mirrors the day / night stat layout.
class _BalconyHistorySkeleton extends StatefulWidget {
  final int blockCount;

  const _BalconyHistorySkeleton({required this.blockCount});

  @override
  State<_BalconyHistorySkeleton> createState() => _BalconyHistorySkeletonState();
}

class _BalconyHistorySkeletonState extends State<_BalconyHistorySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.28, end: 0.52).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bone({
    double? width,
    required double height,
    required Color color,
    required BorderRadius radius,
  }) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: _pulse.value),
            borderRadius: radius,
          ),
        );
      },
    );
  }

  Widget _statRowSkeleton({
    required Color color,
    required BorderRadius radius,
    required double gap,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _bone(
            height: 14,
            color: color,
            radius: radius,
          ),
        ),
        SizedBox(width: gap),
        _bone(width: 56, height: 24, color: color, radius: radius),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final boneColor = colors.outline;

    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widget.blockCount; i++) ...[
            if (i > 0) spacing.vMd,
            _bone(width: 96, height: 16, color: boneColor, radius: BorderRadius.circular(radii.sm)),
            spacing.vXs,
            Divider(height: 1, thickness: 1, color: colors.divider),
            spacing.vXs,
            _statRowSkeleton(color: boneColor, radius: BorderRadius.circular(radii.sm), gap: spacing.sm),
            spacing.vXxs,
            _statRowSkeleton(color: boneColor, radius: BorderRadius.circular(radii.sm), gap: spacing.sm),
          ],
        ],
      ),
    );
  }
}
