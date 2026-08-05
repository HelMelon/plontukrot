import 'package:flutter/material.dart';

import '../tokens/app_color_tokens.dart';
import '../tokens/app_radii_tokens.dart';
import '../tokens/app_spacing_tokens.dart';
import '../tokens/app_typography_tokens.dart';

@immutable
class SplashScreenTheme {
  const SplashScreenTheme({
    required this.background,
    required this.progressTrack,
    required this.progressIndicator,
    required this.captionStyle,
  });

  factory SplashScreenTheme.standard({
    required AppColorTokens colors,
    required AppTypographyTokens typography,
  }) {
    return SplashScreenTheme(
      background: colors.screen,
      progressTrack: colors.divider,
      progressIndicator: colors.primary,
      captionStyle: typography.bodySmall,
    );
  }

  final Color background;
  final Color progressTrack;
  final Color progressIndicator;
  final TextStyle captionStyle;
}

@immutable
class LoginScreenTheme {
  const LoginScreenTheme({
    required this.brandStyle,
    required this.subtitleStyle,
  });

  factory LoginScreenTheme.standard(AppTypographyTokens typography) {
    return LoginScreenTheme(
      brandStyle: typography.brand,
      subtitleStyle: typography.bodySmall,
    );
  }

  final TextStyle brandStyle;
  final TextStyle subtitleStyle;
}

@immutable
class HomeScreenTheme {
  const HomeScreenTheme({
    required this.brandStyle,
    required this.emptyStatePadding,
    required this.emptyStateRadius,
    required this.filterChipFontSize,
    required this.avatarSize,
  });

  factory HomeScreenTheme.standard({
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
    required AppTypographyTokens typography,
  }) {
    return HomeScreenTheme(
      brandStyle: typography.brand,
      emptyStatePadding: EdgeInsets.all(spacing.xxl + 2),
      emptyStateRadius: radii.xl,
      filterChipFontSize: typography.bodySmall.fontSize ?? 13,
      avatarSize: 40,
    );
  }

  final TextStyle brandStyle;
  final EdgeInsets emptyStatePadding;
  final double emptyStateRadius;
  final double filterChipFontSize;
  final double avatarSize;
}

@immutable
class PlantDetailsScreenTheme {
  const PlantDetailsScreenTheme({
    required this.sectionGap,
    required this.actionIconColor,
  });

  factory PlantDetailsScreenTheme.standard({
    required AppColorTokens colors,
    required AppSpacingTokens spacing,
  }) {
    return PlantDetailsScreenTheme(
      sectionGap: spacing.xl,
      actionIconColor: colors.icon,
    );
  }

  final double sectionGap;
  final Color actionIconColor;
}

@immutable
class PropagationsScreenTheme {
  const PropagationsScreenTheme({
    required this.cardRadius,
    required this.cardPadding,
  });

  factory PropagationsScreenTheme.standard({
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
  }) {
    return PropagationsScreenTheme(
      cardRadius: radii.xl,
      cardPadding: EdgeInsets.all(spacing.lg),
    );
  }

  final double cardRadius;
  final EdgeInsets cardPadding;
}

@immutable
class CareHistoryScreenTheme {
  const CareHistoryScreenTheme({
    required this.entryRadius,
    required this.entryPadding,
  });

  factory CareHistoryScreenTheme.standard({
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
  }) {
    return CareHistoryScreenTheme(
      entryRadius: radii.md,
      entryPadding: EdgeInsets.all(spacing.sm + 2),
    );
  }

  final double entryRadius;
  final EdgeInsets entryPadding;
}

@immutable
class CatalogBuilderScreenTheme {
  const CatalogBuilderScreenTheme({
    required this.tagRadius,
    required this.tagPadding,
  });

  factory CatalogBuilderScreenTheme.standard({
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
  }) {
    return CatalogBuilderScreenTheme(
      tagRadius: radii.lg,
      tagPadding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
    );
  }

  final double tagRadius;
  final EdgeInsets tagPadding;
}

@immutable
class GrowthScreenTheme {
  const GrowthScreenTheme({
    required this.leafSize,
    required this.rowHeight,
    required this.counterRadius,
  });

  factory GrowthScreenTheme.standard(AppRadiiTokens radii) {
    return GrowthScreenTheme(
      leafSize: 30,
      rowHeight: 56,
      counterRadius: radii.lg,
    );
  }

  final double leafSize;
  final double rowHeight;
  final double counterRadius;
}

@immutable
class SettingsScreenTheme {
  const SettingsScreenTheme({required this.checkIconColor});

  factory SettingsScreenTheme.standard(AppColorTokens colors) {
    return SettingsScreenTheme(checkIconColor: colors.primary);
  }

  final Color checkIconColor;
}

@immutable
class WishListScreenTheme {
  const WishListScreenTheme({
    required this.cardRadius,
    required this.cardPadding,
  });

  factory WishListScreenTheme.standard({
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
  }) {
    return WishListScreenTheme(
      cardRadius: radii.md,
      cardPadding: EdgeInsets.all(spacing.sm + 2),
    );
  }

  final double cardRadius;
  final EdgeInsets cardPadding;
}

@immutable
class FinancesScreenTheme {
  const FinancesScreenTheme({
    required this.cardRadius,
    required this.cardPadding,
    required this.analyticsRadius,
    required this.analyticsPadding,
  });

  factory FinancesScreenTheme.standard({
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
  }) {
    return FinancesScreenTheme(
      cardRadius: radii.md,
      cardPadding: EdgeInsets.all(spacing.sm + 2),
      analyticsRadius: radii.xl,
      analyticsPadding: EdgeInsets.all(spacing.lg),
    );
  }

  final double cardRadius;
  final EdgeInsets cardPadding;
  final double analyticsRadius;
  final EdgeInsets analyticsPadding;
}

@immutable
class AppScreenThemes {
  const AppScreenThemes({
    required this.splash,
    required this.login,
    required this.home,
    required this.plantDetails,
    required this.propagations,
    required this.careHistory,
    required this.catalogBuilder,
    required this.growth,
    required this.settings,
    required this.wishList,
    required this.finances,
  });

  factory AppScreenThemes.standard({
    required AppColorTokens colors,
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
    required AppTypographyTokens typography,
  }) {
    return AppScreenThemes(
      splash: SplashScreenTheme.standard(
        colors: colors,
        typography: typography,
      ),
      login: LoginScreenTheme.standard(typography),
      home: HomeScreenTheme.standard(
        spacing: spacing,
        radii: radii,
        typography: typography,
      ),
      plantDetails: PlantDetailsScreenTheme.standard(
        colors: colors,
        spacing: spacing,
      ),
      propagations: PropagationsScreenTheme.standard(
        spacing: spacing,
        radii: radii,
      ),
      careHistory: CareHistoryScreenTheme.standard(
        spacing: spacing,
        radii: radii,
      ),
      catalogBuilder: CatalogBuilderScreenTheme.standard(
        spacing: spacing,
        radii: radii,
      ),
      growth: GrowthScreenTheme.standard(radii),
      settings: SettingsScreenTheme.standard(colors),
      wishList: WishListScreenTheme.standard(
        spacing: spacing,
        radii: radii,
      ),
      finances: FinancesScreenTheme.standard(
        spacing: spacing,
        radii: radii,
      ),
    );
  }

  final SplashScreenTheme splash;
  final LoginScreenTheme login;
  final HomeScreenTheme home;
  final PlantDetailsScreenTheme plantDetails;
  final PropagationsScreenTheme propagations;
  final CareHistoryScreenTheme careHistory;
  final CatalogBuilderScreenTheme catalogBuilder;
  final GrowthScreenTheme growth;
  final SettingsScreenTheme settings;
  final WishListScreenTheme wishList;
  final FinancesScreenTheme finances;
}
