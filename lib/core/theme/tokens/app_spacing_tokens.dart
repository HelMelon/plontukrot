import 'package:flutter/material.dart';

/// Shared spacing scale. Prefer named roles in component/screen themes
/// when a value is not on this scale.
@immutable
class AppSpacingTokens {
  const AppSpacingTokens({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
  });

  static const standard = AppSpacingTokens(
    xxs: 4,
    xs: 8,
    sm: 12,
    md: 16,
    lg: 20,
    xl: 24,
    xxl: 28,
    xxxl: 32,
  );

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  EdgeInsets get allXxs => EdgeInsets.all(xxs);
  EdgeInsets get allXs => EdgeInsets.all(xs);
  EdgeInsets get allSm => EdgeInsets.all(sm);
  EdgeInsets get allMd => EdgeInsets.all(md);
  EdgeInsets get allLg => EdgeInsets.all(lg);
  EdgeInsets get allXl => EdgeInsets.all(xl);

  EdgeInsets symmetric({double? horizontal, double? vertical}) =>
      EdgeInsets.symmetric(
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );

  SizedBox get gapXxs => SizedBox(height: xxs, width: xxs);
  SizedBox get gapXs => SizedBox(height: xs, width: xs);
  SizedBox get gapSm => SizedBox(height: sm, width: sm);
  SizedBox get gapMd => SizedBox(height: md, width: md);
  SizedBox get gapLg => SizedBox(height: lg, width: lg);
  SizedBox get gapXl => SizedBox(height: xl, width: xl);

  SizedBox get vXxs => SizedBox(height: xxs);
  SizedBox get vXs => SizedBox(height: xs);
  SizedBox get vSm => SizedBox(height: sm);
  SizedBox get vMd => SizedBox(height: md);
  SizedBox get vLg => SizedBox(height: lg);
  SizedBox get vXl => SizedBox(height: xl);
  SizedBox get vXxl => SizedBox(height: xxl);
  SizedBox get vXxxl => SizedBox(height: xxxl);

  SizedBox get hXxs => SizedBox(width: xxs);
  SizedBox get hXs => SizedBox(width: xs);
  SizedBox get hSm => SizedBox(width: sm);
  SizedBox get hMd => SizedBox(width: md);
  SizedBox get hLg => SizedBox(width: lg);

  AppSpacingTokens lerp(AppSpacingTokens? other, double t) {
    if (other is! AppSpacingTokens) return this;
    double l(double a, double b) => a + (b - a) * t;
    return AppSpacingTokens(
      xxs: l(xxs, other.xxs),
      xs: l(xs, other.xs),
      sm: l(sm, other.sm),
      md: l(md, other.md),
      lg: l(lg, other.lg),
      xl: l(xl, other.xl),
      xxl: l(xxl, other.xxl),
      xxxl: l(xxxl, other.xxxl),
    );
  }
}
