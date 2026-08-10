import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';

class PlantLeafCounter extends StatelessWidget {
  final int count;
  final bool busy;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onScrollToStats;

  const PlantLeafCounter({
    super.key,
    required this.count,
    this.busy = false,
    this.onIncrement,
    this.onDecrement,
    this.onScrollToStats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final growth = context.screens.growth;
    final dimensions = context.dimensions;
    final canDecrement = !busy && count > 0 && onDecrement != null;
    final canIncrement = !busy && onIncrement != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.screen.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(growth.counterRadius),
        border: Border.all(color: colors.outline.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundControl(
                  tooltip: l10n.plantLeafRemove,
                  icon: Icons.remove,
                  onPressed: canDecrement ? onDecrement : null,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                  child: Text(
                    '$count',
                    style: typography.titleLarge.copyWith(
                      fontSize: spacing.xxxl,
                      fontWeight: FontWeight.bold,
                      color: colors.heading,
                    ),
                  ),
                ),
                _RoundControl(
                  tooltip: l10n.plantLeafAdd,
                  icon: Icons.add,
                  onPressed: canIncrement ? onIncrement : null,
                ),
              ],
            ),
            if (onScrollToStats != null) ...[
              spacing.vXs,
              Semantics(
                button: true,
                label: l10n.plantLeafStatsAnchor,
                child: InkWell(
                  onTap: onScrollToStats,
                  borderRadius: BorderRadius.circular(context.radii.sm),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: spacing.xxs,
                      horizontal: spacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.plantLeafStatsAnchor,
                            style: typography.bodyEmphasis.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                        spacing.hXxs,
                        ExcludeSemantics(
                          child: Icon(
                            Icons.arrow_downward,
                            size: dimensions.iconSm,
                            color: colors.icon,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = context.dimensions.minTapTarget + 4;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: colors.modal,
          shape: CircleBorder(
            side: BorderSide(color: colors.outline),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: ExcludeSemantics(
                child: Icon(
                  icon,
                  color: onPressed == null
                      ? colors.textSecondary.withValues(alpha: 0.4)
                      : colors.icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
