import 'package:flutter/material.dart';

import '../tokens/app_color_tokens.dart';
import '../tokens/app_dimension_tokens.dart';
import '../tokens/app_radii_tokens.dart';
import '../tokens/app_spacing_tokens.dart';
import '../tokens/app_typography_tokens.dart';

@immutable
class AppButtonComponentTheme {
  const AppButtonComponentTheme({
    required this.primaryBackground,
    required this.primaryForeground,
    required this.primaryHover,
    required this.secondaryBackground,
    required this.secondaryForeground,
    required this.secondaryOutline,
    required this.destructiveBackground,
    required this.destructiveForeground,
    required this.height,
    required this.radius,
    required this.horizontalPadding,
    required this.labelStyle,
  });

  factory AppButtonComponentTheme.standard({
    required AppColorTokens colors,
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
    required AppDimensionTokens dimensions,
    required AppTypographyTokens typography,
  }) {
    return AppButtonComponentTheme(
      primaryBackground: colors.primary,
      primaryForeground: colors.onPrimary,
      primaryHover: colors.primaryHover,
      secondaryBackground: colors.secondaryButton,
      secondaryForeground: colors.textPrimary,
      secondaryOutline: colors.outline,
      destructiveBackground: colors.error,
      destructiveForeground: colors.onPrimary,
      height: dimensions.buttonHeight,
      radius: radii.lg,
      horizontalPadding: spacing.md,
      labelStyle: typography.button,
    );
  }

  final Color primaryBackground;
  final Color primaryForeground;
  final Color primaryHover;
  final Color secondaryBackground;
  final Color secondaryForeground;
  final Color secondaryOutline;
  final Color destructiveBackground;
  final Color destructiveForeground;
  final double height;
  final double radius;
  final double horizontalPadding;
  final TextStyle labelStyle;
}

@immutable
class AppSheetComponentTheme {
  const AppSheetComponentTheme({
    required this.background,
    required this.topRadius,
    required this.contentPadding,
    required this.handleColor,
    required this.handleWidth,
    required this.handleHeight,
    required this.handleRadius,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  factory AppSheetComponentTheme.standard({
    required AppColorTokens colors,
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
    required AppDimensionTokens dimensions,
    required AppTypographyTokens typography,
  }) {
    return AppSheetComponentTheme(
      background: colors.modal,
      topRadius: radii.sheet,
      contentPadding: EdgeInsets.fromLTRB(
        spacing.xl - 2,
        spacing.xl - 2,
        spacing.xl - 2,
        spacing.xl,
      ),
      handleColor: colors.divider,
      handleWidth: dimensions.dragHandleWidth,
      handleHeight: dimensions.dragHandleHeight,
      handleRadius: radii.pill,
      titleStyle: typography.titleMedium,
      subtitleStyle: typography.bodySmall,
    );
  }

  final Color background;
  final double topRadius;
  final EdgeInsets contentPadding;
  final Color handleColor;
  final double handleWidth;
  final double handleHeight;
  final double handleRadius;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  BorderRadius get topBorderRadius =>
      BorderRadius.vertical(top: Radius.circular(topRadius));
}

@immutable
class AppInputComponentTheme {
  const AppInputComponentTheme({
    required this.fill,
    required this.border,
    required this.focusedBorder,
    required this.radius,
    required this.textStyle,
    required this.labelStyle,
    required this.hintStyle,
    required this.contentPadding,
  });

  factory AppInputComponentTheme.standard({
    required AppColorTokens colors,
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
    required AppTypographyTokens typography,
  }) {
    return AppInputComponentTheme(
      fill: colors.card,
      border: colors.outline,
      focusedBorder: colors.primary,
      radius: radii.lg,
      textStyle: typography.bodyLarge,
      labelStyle: typography.bodySmall,
      hintStyle: typography.bodySmall,
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),
    );
  }

  final Color fill;
  final Color border;
  final Color focusedBorder;
  final double radius;
  final TextStyle textStyle;
  final TextStyle labelStyle;
  final TextStyle hintStyle;
  final EdgeInsets contentPadding;

  InputDecoration decoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final borderSide = BorderSide(color: border);
    final focusedSide = BorderSide(color: focusedBorder);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: labelStyle,
      hintStyle: hintStyle,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fill,
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: focusedSide,
      ),
    );
  }
}

@immutable
class AppCardComponentTheme {
  const AppCardComponentTheme({
    required this.background,
    required this.border,
    required this.radius,
    required this.padding,
  });

  factory AppCardComponentTheme.standard({
    required AppColorTokens colors,
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
  }) {
    return AppCardComponentTheme(
      background: colors.card,
      border: colors.outline,
      radius: radii.xl,
      padding: EdgeInsets.all(spacing.xl),
    );
  }

  final Color background;
  final Color border;
  final double radius;
  final EdgeInsets padding;

  BoxDecoration get decoration => BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      );
}

@immutable
class AppChipComponentTheme {
  const AppChipComponentTheme({
    required this.selectedBackground,
    required this.unselectedBackground,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.selectedBorder,
    required this.unselectedBorder,
    required this.checkmark,
    required this.labelStyle,
    required this.radius,
  });

  factory AppChipComponentTheme.standard({
    required AppColorTokens colors,
    required AppRadiiTokens radii,
    required AppTypographyTokens typography,
  }) {
    return AppChipComponentTheme(
      selectedBackground: colors.primary,
      unselectedBackground: colors.modal,
      selectedForeground: colors.onPrimary,
      unselectedForeground: colors.textPrimary,
      selectedBorder: colors.primary,
      unselectedBorder: colors.outline,
      checkmark: colors.onPrimary,
      labelStyle: typography.bodySmall,
      radius: radii.lg,
    );
  }

  final Color selectedBackground;
  final Color unselectedBackground;
  final Color selectedForeground;
  final Color unselectedForeground;
  final Color selectedBorder;
  final Color unselectedBorder;
  final Color checkmark;
  final TextStyle labelStyle;
  final double radius;
}

@immutable
class AppDialogComponentTheme {
  const AppDialogComponentTheme({
    required this.background,
    required this.titleStyle,
    required this.bodyStyle,
    required this.radius,
  });

  factory AppDialogComponentTheme.standard({
    required AppColorTokens colors,
    required AppRadiiTokens radii,
    required AppTypographyTokens typography,
  }) {
    return AppDialogComponentTheme(
      background: colors.modal,
      titleStyle: typography.titleSmall,
      bodyStyle: typography.bodyLarge,
      radius: radii.lg,
    );
  }

  final Color background;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final double radius;
}

@immutable
class AppComponentThemes {
  const AppComponentThemes({
    required this.buttons,
    required this.sheets,
    required this.inputs,
    required this.cards,
    required this.chips,
    required this.dialogs,
  });

  factory AppComponentThemes.standard({
    required AppColorTokens colors,
    required AppSpacingTokens spacing,
    required AppRadiiTokens radii,
    required AppDimensionTokens dimensions,
    required AppTypographyTokens typography,
  }) {
    return AppComponentThemes(
      buttons: AppButtonComponentTheme.standard(
        colors: colors,
        spacing: spacing,
        radii: radii,
        dimensions: dimensions,
        typography: typography,
      ),
      sheets: AppSheetComponentTheme.standard(
        colors: colors,
        spacing: spacing,
        radii: radii,
        dimensions: dimensions,
        typography: typography,
      ),
      inputs: AppInputComponentTheme.standard(
        colors: colors,
        spacing: spacing,
        radii: radii,
        typography: typography,
      ),
      cards: AppCardComponentTheme.standard(
        colors: colors,
        spacing: spacing,
        radii: radii,
      ),
      chips: AppChipComponentTheme.standard(
        colors: colors,
        radii: radii,
        typography: typography,
      ),
      dialogs: AppDialogComponentTheme.standard(
        colors: colors,
        radii: radii,
        typography: typography,
      ),
    );
  }

  final AppButtonComponentTheme buttons;
  final AppSheetComponentTheme sheets;
  final AppInputComponentTheme inputs;
  final AppCardComponentTheme cards;
  final AppChipComponentTheme chips;
  final AppDialogComponentTheme dialogs;
}
