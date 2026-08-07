import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme_tokens.dart';
import 'tokens/app_color_tokens.dart';
import 'tokens/app_dimension_tokens.dart';
import 'tokens/app_radii_tokens.dart';
import 'tokens/app_shadow_tokens.dart';
import 'tokens/app_spacing_tokens.dart';
import 'tokens/app_typography_tokens.dart';

/// Application visual system.
///
/// UI widgets must read tokens via [BuildContext] (`context.colors`, …).
/// Painters / non-widget code may use the static aliases below — same values,
/// no duplication.
class AppTheme {
  AppTheme._();

  static final AppThemeTokens tokens = AppThemeTokens.standard();

  /// Static aliases for painters and code without [BuildContext].
  static AppColorTokens get colors => tokens.colors;
  static AppSpacingTokens get spacing => tokens.spacing;
  static AppRadiiTokens get radii => tokens.radii;
  static AppDimensionTokens get dimensions => tokens.dimensions;
  static AppTypographyTokens get typography => tokens.typography;
  static AppShadowTokens get shadows => tokens.shadows;

  /// Fixed height for primary actions (also in [dimensions.buttonHeight]).
  static double get buttonHeight => dimensions.buttonHeight;

  /// Single app [ThemeData] (no light/dark switch yet).
  static ThemeData get theme {
    final c = colors;
    final d = dimensions;
    final t = typography;
    final r = radii;

    ButtonStyle primaryButtonStyle({FontWeight weight = FontWeight.w700}) {
      return ElevatedButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        minimumSize: d.buttonMinSize,
        maximumSize: d.buttonMaxSize,
        padding: EdgeInsets.symmetric(horizontal: spacing.md),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.lg),
        ),
        textStyle: t.button.copyWith(fontWeight: weight),
      );
    }

    final secondaryOutlined = OutlinedButton.styleFrom(
      backgroundColor: c.secondaryButton,
      foregroundColor: c.textPrimary,
      minimumSize: d.buttonMinSize,
      maximumSize: d.buttonMaxSize,
      padding: EdgeInsets.symmetric(horizontal: spacing.md),
      elevation: 0,
      side: BorderSide(color: c.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.lg),
      ),
      textStyle: t.button.copyWith(color: c.textPrimary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: c.screen,
      colorScheme: ColorScheme.dark(
        primary: c.primary,
        onPrimary: c.onPrimary,
        secondary: c.primaryHover,
        onSecondary: c.onPrimary,
        surface: c.card,
        onSurface: c.textPrimary,
        error: c.error,
        onError: c.onPrimary,
        outline: c.outline,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: primaryButtonStyle(weight: FontWeight.w600),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: secondaryOutlined,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: t.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: c.primary,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.screen,
        elevation: 0,
        foregroundColor: c.heading,
        iconTheme: IconThemeData(color: c.icon),
        titleTextStyle: t.titleMedium.copyWith(fontSize: 28),
      ),
      textTheme: GoogleFonts.amaticScTextTheme(
        TextTheme(
          bodyLarge: t.bodyLarge,
          bodyMedium: t.bodyMedium,
          bodySmall: t.bodySmall,
          titleLarge: t.titleLarge,
          titleMedium: t.titleMedium,
          titleSmall: t.titleSmall,
          labelLarge: t.label,
          headlineMedium: t.titleMedium,
        ),
      ),
      cardColor: c.card,
      dividerColor: c.divider,
      iconTheme: IconThemeData(color: c.icon),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        circularTrackColor: c.divider,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.modal,
        contentTextStyle: t.bodyMedium,
        actionTextColor: c.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.modal,
        titleTextStyle: t.titleSmall,
        contentTextStyle: t.bodyLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.lg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.modal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(r.sheet)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        labelStyle: t.bodySmall,
        hintStyle: t.bodySmall,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.lg),
          borderSide: BorderSide(color: c.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.lg),
          borderSide: BorderSide(color: c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.lg),
          borderSide: BorderSide(color: c.primary),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.modal,
        selectedColor: c.primary,
        disabledColor: c.divider,
        labelStyle: t.bodySmall,
        secondaryLabelStyle: t.bodySmall.copyWith(color: c.onPrimary),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.lg),
          side: BorderSide(color: c.outline),
        ),
        side: BorderSide(color: c.outline),
        checkmarkColor: c.onPrimary,
      ),
    );
  }
}
