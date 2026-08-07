import 'package:flutter/material.dart';

import '../tokens/app_color_tokens.dart';
import '../tokens/app_dimension_tokens.dart';
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
    required this.galleryDateScrim,
    required this.galleryDateText,
    required this.galleryDotActive,
    required this.galleryDotInactive,
    required this.galleryActionBackground,
    required this.galleryDotSize,
    required this.galleryDotGap,
    required this.nicknameStyle,
    required this.infoRowLabelStyle,
    required this.infoRowValueStyle,
  });

  factory PlantDetailsScreenTheme.standard({
    required AppColorTokens colors,
    required AppSpacingTokens spacing,
    required AppTypographyTokens typography,
  }) {
    return PlantDetailsScreenTheme(
      sectionGap: spacing.xl,
      actionIconColor: colors.icon,
      galleryDateScrim: colors.screen.withValues(alpha: 0.55),
      galleryDateText: colors.onPrimary,
      galleryDotActive: colors.primaryHover,
      galleryDotInactive: colors.onPrimary.withValues(alpha: 0.35),
      galleryActionBackground: colors.screen.withValues(alpha: 0.45),
      galleryDotSize: spacing.sm,
      galleryDotGap: spacing.xs,
      nicknameStyle: typography.titleSmall.copyWith(
        fontSize: (typography.titleSmall.fontSize ?? 18) + 1,
        fontWeight: FontWeight.w600,
        color: colors.heading,
      ),
      infoRowLabelStyle: typography.bodySmall.copyWith(
        fontSize: (typography.bodySmall.fontSize ?? 13) + 1,
        color: colors.textSecondary,
      ),
      infoRowValueStyle: typography.bodySmall.copyWith(
        fontSize: (typography.bodySmall.fontSize ?? 13) + 1,
        color: colors.heading,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  final double sectionGap;
  final Color actionIconColor;
  final Color galleryDateScrim;
  final Color galleryDateText;
  final Color galleryDotActive;
  final Color galleryDotInactive;
  final Color galleryActionBackground;
  final double galleryDotSize;
  final double galleryDotGap;
  final TextStyle nicknameStyle;
  final TextStyle infoRowLabelStyle;
  final TextStyle infoRowValueStyle;
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
class ProfileScreenTheme {
  const ProfileScreenTheme({
    required this.privacyLinkColor,
    required this.statCardColor,
    required this.avatarSize,
    required this.dangerButtonBackground,
    required this.dangerButtonForeground,
    required this.dropdownTextStyle,
    required this.statLabelStyle,
    required this.statValueStyle,
  });

  factory ProfileScreenTheme.standard({
    required AppColorTokens colors,
    required AppDimensionTokens dimensions,
    required AppTypographyTokens typography,
  }) {
    return ProfileScreenTheme(
      privacyLinkColor: colors.primary,
      statCardColor: colors.heading.withValues(alpha: 0.04),
      avatarSize: dimensions.avatar * 2,
      dangerButtonBackground: colors.error,
      dangerButtonForeground: colors.onPrimary,
      dropdownTextStyle: typography.bodySmall.copyWith(
        color: colors.heading,
      ),
      statLabelStyle: typography.bodyMedium.copyWith(
        color: colors.textSecondary,
      ),
      statValueStyle: typography.bodyMedium.copyWith(
        color: colors.heading,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  final Color privacyLinkColor;
  final Color statCardColor;
  final double avatarSize;
  final Color dangerButtonBackground;
  final Color dangerButtonForeground;
  final TextStyle dropdownTextStyle;
  final TextStyle statLabelStyle;
  final TextStyle statValueStyle;
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
    required this.profile,
    required this.wishList,
    required this.finances,
  });

  factory AppScreenThemes.standard({
    required AppColorTokens colors,
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
    required AppTypographyTokens typography,
    required AppDimensionTokens dimensions,
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
        typography: typography,
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
      profile: ProfileScreenTheme.standard(
        colors: colors,
        dimensions: dimensions,
        typography: typography,
      ),
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
  final ProfileScreenTheme profile;
  final WishListScreenTheme wishList;
  final FinancesScreenTheme finances;
}
