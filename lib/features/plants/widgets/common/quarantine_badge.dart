import 'package:flutter/material.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

/// Compact «Карантин» pill for plant cards and gallery overlays.
class QuarantineBadge extends StatelessWidget {
  const QuarantineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final radii = context.radii;

    return Semantics(
      label: l10n.a11yPlantQuarantine,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(radii.sm),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.xs,
            vertical: spacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                context.icons.quarantine,
                size: context.dimensions.iconSm,
                color: colors.onPrimary,
              ),
              SizedBox(width: spacing.xxs),
              Text(
                l10n.plantQuarantineBadge,
                style: typography.caption.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
