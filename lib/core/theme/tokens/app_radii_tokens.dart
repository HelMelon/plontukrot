import 'package:flutter/material.dart';

@immutable
class AppRadiiTokens {
  const AppRadiiTokens({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.sheet,
    required this.pill,
  });

  static const standard = AppRadiiTokens(
    sm: 8,
    md: 16,
    lg: 20,
    xl: 28,
    sheet: 32,
    pill: 99,
  );

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double sheet;
  final double pill;

  BorderRadius get smAll => BorderRadius.circular(sm);
  BorderRadius get mdAll => BorderRadius.circular(md);
  BorderRadius get lgAll => BorderRadius.circular(lg);
  BorderRadius get xlAll => BorderRadius.circular(xl);
  BorderRadius get pillAll => BorderRadius.circular(pill);

  BorderRadius get sheetTop =>
      BorderRadius.vertical(top: Radius.circular(sheet));

  AppRadiiTokens lerp(AppRadiiTokens? other, double t) {
    if (other is! AppRadiiTokens) return this;
    double l(double a, double b) => a + (b - a) * t;
    return AppRadiiTokens(
      sm: l(sm, other.sm),
      md: l(md, other.md),
      lg: l(lg, other.lg),
      xl: l(xl, other.xl),
      sheet: l(sheet, other.sheet),
      pill: l(pill, other.pill),
    );
  }
}
