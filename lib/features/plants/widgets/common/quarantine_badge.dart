import 'package:flutter/material.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

/// Compact quarantine pill for plant cards and gallery overlays.
///
/// [iconOnly] is the home-grid variant: yellow clock, no visible word.
/// Other screens keep the labeled badge.
class QuarantineBadge extends StatelessWidget {
  const QuarantineBadge({super.key, this.iconOnly = false});

  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final radii = context.radii;
    final label = l10n.a11yPlantQuarantine;

    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(radii.sm),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.xs,
          vertical: spacing.xxs,
        ),
        child: iconOnly
            ? Icon(
                context.icons.clock,
                size: context.dimensions.iconSm,
                color: colors.onPrimary,
              )
            : Row(
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
    );

    return Semantics(
      label: label,
      child: iconOnly
          ? Tooltip(
              message: label,
              excludeFromSemantics: true,
              child: badge,
            )
          : badge,
    );
  }
}
