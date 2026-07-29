import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  /// Fixed height for primary actions on pages and bottom sheets.
  static const double buttonHeight = 52;

  static ThemeData darkTheme = ThemeData(
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, buttonHeight),
        maximumSize: const Size(double.infinity, buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, buttonHeight),
        maximumSize: const Size(double.infinity, buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, buttonHeight),
        maximumSize: const Size(double.infinity, buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    ),

    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentGreen,
      secondary: AppColors.goldAccent,
      surface: AppColors.backgroundSecondary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.heading,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      headlineMedium: TextStyle(
        color: AppColors.heading,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardColor: AppColors.backgroundSecondary,
    iconTheme: const IconThemeData(color: AppColors.accentLight),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.goldAccent,
      foregroundColor: AppColors.dark1,
    ),
  );
}
