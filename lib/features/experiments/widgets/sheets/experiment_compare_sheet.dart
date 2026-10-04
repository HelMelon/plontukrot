import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';
import '../../../../models/experiment.dart';
import '../../../../models/experiment_variant.dart';

/// Side-by-side comparison of an experiment's variants using each variant's
/// most recent numeric readings. This is a convenience view, not a stat tool —
/// it shows the latest measured height / leaf count / moisture per variant.
class ExperimentCompareSheet extends StatelessWidget {
  final Experiment experiment;

  const ExperimentCompareSheet({super.key, required this.experiment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final typography = context.typography;
    final media = MediaQuery.of(context);
    final sheetHeight = (media.size.height - media.padding.top) * 0.9;

    return SizedBox(
      height: sheetHeight,
      child: Container(
        decoration: BoxDecoration(
          color: colors.modal,
          borderRadius: sheets.topBorderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const SheetDragHandle(),
            Expanded(
              child: ListView(
                padding: sheets.contentPadding,
                children: [
                  Text(
                    l10n.experimentsCompare,
                    style: typography.titleLarge.copyWith(letterSpacing: -1),
                  ),
                  spacing.vXs,
                  Text(
                    l10n.experimentsCompareHint,
                    style: typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  spacing.vLg,
                  if (experiment.comparableVariants.isEmpty)
                    _EmptyCompare(text: l10n.experimentsNoMetrics)
                  else
                    _CompareTable(
                      variants: experiment.comparableVariants,
                      l10n: l10n,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCompare extends StatelessWidget {
  final String text;

  const _EmptyCompare({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.xl),
      child: Text(
        text,
        style: context.typography.bodyLarge
            .copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  final List<ExperimentVariant> variants;
  final AppLocalizations l10n;

  const _CompareTable({required this.variants, required this.l10n});

  String _cell(double? value) {
    if (value == null) return '—';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radii = context.radii;
    final typography = context.typography;
    final cellStyle = typography.bodyMedium.copyWith(color: colors.textPrimary);
    final headStyle =
        typography.titleSmall.copyWith(color: colors.textSecondary);

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(radii.lg),
        border: Border.all(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(color: colors.divider),
        ),
        columnWidths: const {
          0: FlexColumnWidth(1.6),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1.2),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              _head(l10n.experimentsVariantsSection, headStyle),
              _head(l10n.experimentsMetricHeight, headStyle),
              _head(l10n.experimentsMetricLeaves, headStyle),
              _head(l10n.experimentsMetricMoisture, headStyle),
            ],
          ),
          for (final variant in variants)
            TableRow(
              children: [
                _cellWidget(variant.label, cellStyle, bold: true),
                _cellWidget(
                  _cell(variant.latestWithMetrics?.heightCm),
                  cellStyle,
                ),
                _cellWidget(
                  variant.latestWithMetrics?.leafCount?.toString() ?? '—',
                  cellStyle,
                ),
                _cellWidget(
                  _cell(variant.latestWithMetrics?.moisture),
                  cellStyle,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _head(String text, TextStyle style) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: style),
      );

  Widget _cellWidget(String text, TextStyle style, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: bold ? style.copyWith(fontWeight: FontWeight.bold) : style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
}
