import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    TextStyle amatic({
      double? fontSize,
      FontWeight fontWeight = FontWeight.bold,
      Color? color,
      double? height,
    }) {
      return GoogleFonts.amaticSc(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }

    return AppTypographyTokens(
      // Brand wordmark stays NordicStyle (SKÖRD) — not Amatic SC.
      brand: TextStyle(
        fontFamily: 'NordicStyle',
        fontSize: 36,
        color: colors.heading,
      ),
      titlePage: amatic(
        fontSize: 28,
        color: colors.textPrimary,
      ),
      titleLarge: amatic(
        fontSize: 30,
        color: colors.heading,
      ),
      titleMedium: amatic(
        fontSize: 24,
        color: colors.heading,
      ),
      titleSmall: amatic(
        fontSize: 22,
        color: colors.heading,
      ),
      bodyLarge: amatic(
        fontSize: 20,
        color: colors.textPrimary,
      ),
      bodyEmphasis: amatic(
        fontSize: 19,
        color: colors.textPrimary,
      ),
      bodyMedium: amatic(
        fontSize: 18,
        color: colors.textPrimary,
      ),
      bodySmall: amatic(
        fontSize: 17,
        color: colors.textSecondary,
      ),
      label: amatic(
        fontSize: 17,
        color: colors.textPrimary,
      ),
      caption: amatic(
        fontSize: 16,
        color: colors.textSecondary,
      ),
      captionSmall: amatic(
        fontSize: 15,
        color: colors.textSecondary,
        height: 1.25,
      ),
      button: amatic(
        fontSize: 18,
        color: colors.onPrimary,
      ),
      link: amatic(
        fontSize: 18,
        color: colors.primary,
      ),
      sectionTitle: amatic(
        fontSize: 20,
        color: colors.heading,
      ),
      error: amatic(
        fontSize: 18,
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

  /// Bumps every style's [fontSize] by [delta] (e.g. +2 on large screens).
  AppTypographyTokens withSizeDelta(double delta) {
    if (delta == 0) return this;
    TextStyle bump(TextStyle style) {
      final size = style.fontSize;
      if (size == null) return style;
      return style.copyWith(fontSize: size + delta);
    }

    return AppTypographyTokens(
      brand: bump(brand),
      titlePage: bump(titlePage),
      titleLarge: bump(titleLarge),
      titleMedium: bump(titleMedium),
      titleSmall: bump(titleSmall),
      bodyLarge: bump(bodyLarge),
      bodyEmphasis: bump(bodyEmphasis),
      bodyMedium: bump(bodyMedium),
      bodySmall: bump(bodySmall),
      label: bump(label),
      caption: bump(caption),
      captionSmall: bump(captionSmall),
      button: bump(button),
      link: bump(link),
      sectionTitle: bump(sectionTitle),
      error: bump(error),
    );
  }

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
