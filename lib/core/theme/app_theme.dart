import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
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
