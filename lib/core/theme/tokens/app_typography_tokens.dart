import 'package:flutter/material.dart';

import 'app_color_tokens.dart';

@immutable
class AppTypographyTokens {
  const AppTypographyTokens({
    required this.brand,
    required this.titlePage,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyEmphasis,
    required this.bodyMedium,
    required this.bodySmall,
    required this.label,
    required this.caption,
    required this.captionSmall,
    required this.button,
    required this.link,
    required this.sectionTitle,
    required this.error,
  });

  factory AppTypographyTokens.standard(AppColorTokens colors) {
    return AppTypographyTokens(
      brand: TextStyle(
        fontFamily: 'NordicStyle',
        fontSize: 36,
        color: colors.heading,
      ),
      titlePage: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: colors.heading,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: colors.heading,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.heading,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: colors.textPrimary,
      ),
      bodyEmphasis: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: colors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        color: colors.textSecondary,
      ),
      label: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
      ),
      caption: TextStyle(
        fontSize: 12,
        color: colors.textSecondary,
      ),
      captionSmall: TextStyle(
        fontSize: 11,
        color: colors.textSecondary,
        height: 1.25,
      ),
      button: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: colors.onPrimary,
      ),
      link: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.primary,
      ),
      sectionTitle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.heading,
      ),
      error: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: colors.error,
      ),
    );
  }

  final TextStyle brand;
  final TextStyle titlePage;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyEmphasis;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle captionSmall;
  final TextStyle button;
  final TextStyle link;
  final TextStyle sectionTitle;
  final TextStyle error;

  AppTypographyTokens lerp(AppTypographyTokens? other, double t) {
    if (other is! AppTypographyTokens) return this;
    return AppTypographyTokens(
      brand: TextStyle.lerp(brand, other.brand, t)!,
      titlePage: TextStyle.lerp(titlePage, other.titlePage, t)!,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t)!,
      titleMedium: TextStyle.lerp(titleMedium, other.titleMedium, t)!,
      titleSmall: TextStyle.lerp(titleSmall, other.titleSmall, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyEmphasis: TextStyle.lerp(bodyEmphasis, other.bodyEmphasis, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      captionSmall: TextStyle.lerp(captionSmall, other.captionSmall, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      link: TextStyle.lerp(link, other.link, t)!,
      sectionTitle: TextStyle.lerp(sectionTitle, other.sectionTitle, t)!,
      error: TextStyle.lerp(error, other.error, t)!,
    );
  }
}
