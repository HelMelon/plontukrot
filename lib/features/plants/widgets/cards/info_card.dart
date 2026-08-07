import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

class InfoCard extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radii = context.radii;
    final spacing = context.spacing;
    final typography = context.typography;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radii.md),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(radii.md),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              icon!,
              SizedBox(width: spacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: typography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.heading,
                    ),
                  ),
                  spacing.vXxs,
                  Text(
                    value,
                    style: typography.captionSmall,
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
