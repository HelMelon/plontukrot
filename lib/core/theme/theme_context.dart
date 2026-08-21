import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';
import 'components/app_component_themes.dart';
import 'screens/app_screen_themes.dart';
import 'tokens/app_color_tokens.dart';
import 'tokens/app_dimension_tokens.dart';
import 'tokens/app_icon_tokens.dart';
import 'tokens/app_radii_tokens.dart';
import 'tokens/app_shadow_tokens.dart';
import 'tokens/app_spacing_tokens.dart';
import 'tokens/app_typography_tokens.dart';

export 'tokens/app_color_tokens.dart';
export 'tokens/app_dimension_tokens.dart';
export 'tokens/app_icon_tokens.dart';
export 'tokens/app_radii_tokens.dart';
export 'tokens/app_shadow_tokens.dart';
export 'tokens/app_spacing_tokens.dart';
export 'tokens/app_typography_tokens.dart';

/// BuildContext accessors for [AppThemeTokens].
extension AppThemeContext on BuildContext {
  AppThemeTokens get appTheme {
    final tokens = Theme.of(this).extension<AppThemeTokens>();
    assert(
      tokens != null,
      'AppThemeTokens missing from ThemeData.extensions',
    );
    return tokens!;
  }

  AppColorTokens get colors => appTheme.colors;
  AppSpacingTokens get spacing => appTheme.spacing;
  AppRadiiTokens get radii => appTheme.radii;
  AppDimensionTokens get dimensions => appTheme.dimensions;
  AppTypographyTokens get typography => appTheme.typography;
  AppShadowTokens get shadows => appTheme.shadows;
  AppIconTokens get icons => appTheme.icons;
  AppComponentThemes get components => appTheme.components;
  AppScreenThemes get screens => appTheme.screens;
}
