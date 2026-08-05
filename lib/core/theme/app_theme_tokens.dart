import 'package:flutter/material.dart';

import 'components/app_component_themes.dart';
import 'screens/app_screen_themes.dart';
import 'tokens/app_color_tokens.dart';
import 'tokens/app_dimension_tokens.dart';
import 'tokens/app_radii_tokens.dart';
import 'tokens/app_shadow_tokens.dart';
import 'tokens/app_spacing_tokens.dart';
import 'tokens/app_typography_tokens.dart';

/// Root theme tokens registered on [ThemeData.extensions].
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.colors,
    required this.spacing,
    required this.radii,
    required this.dimensions,
    required this.typography,
    required this.shadows,
    required this.components,
    required this.screens,
  });

  factory AppThemeTokens.standard() {
    const colors = AppColorTokens.standard;
    const spacing = AppSpacingTokens.standard;
    const radii = AppRadiiTokens.standard;
    const dimensions = AppDimensionTokens.standard;
    final typography = AppTypographyTokens.standard(colors);
    final shadows = AppShadowTokens.standard(colors);
    return AppThemeTokens(
      colors: colors,
      spacing: spacing,
      radii: radii,
      dimensions: dimensions,
      typography: typography,
      shadows: shadows,
      components: AppComponentThemes.standard(
        colors: colors,
        spacing: spacing,
        radii: radii,
        dimensions: dimensions,
        typography: typography,
      ),
      screens: AppScreenThemes.standard(
        colors: colors,
        spacing: spacing,
        radii: radii,
        typography: typography,
      ),
    );
  }

  final AppColorTokens colors;
  final AppSpacingTokens spacing;
  final AppRadiiTokens radii;
  final AppDimensionTokens dimensions;
  final AppTypographyTokens typography;
  final AppShadowTokens shadows;
  final AppComponentThemes components;
  final AppScreenThemes screens;

  @override
  AppThemeTokens copyWith({
    AppColorTokens? colors,
    AppSpacingTokens? spacing,
    AppRadiiTokens? radii,
    AppDimensionTokens? dimensions,
    AppTypographyTokens? typography,
    AppShadowTokens? shadows,
    AppComponentThemes? components,
    AppScreenThemes? screens,
  }) {
    return AppThemeTokens(
      colors: colors ?? this.colors,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      dimensions: dimensions ?? this.dimensions,
      typography: typography ?? this.typography,
      shadows: shadows ?? this.shadows,
      components: components ?? this.components,
      screens: screens ?? this.screens,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return t < 0.5 ? this : other;
  }
}
