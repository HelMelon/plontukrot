import 'package:flutter/material.dart';

/// Semantic color palette for SKÖRD.
///
/// Single source of truth — used by [ThemeExtension] and static [AppTheme]
/// aliases for painters without [BuildContext].
@immutable
class AppColorTokens {
  const AppColorTokens({
    required this.screen,
    required this.modal,
    required this.card,
    required this.divider,
    required this.primary,
    required this.primaryHover,
    required this.onPrimary,
    required this.secondaryButton,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.heading,
    required this.icon,
    required this.success,
    required this.warning,
    required this.error,
  });

  /// Default (and currently only) app palette.
  static const standard = AppColorTokens(
    screen: Color(0xFF171A1A),
    modal: Color(0xFF202425),
    card: Color(0xFF1B2020),
    divider: Color(0xFF293331),
    primary: Color(0xFF4A6B5D),
    primaryHover: Color(0xFF5A7E6E),
    onPrimary: Color(0xFFF4F6F5),
    secondaryButton: Color(0xFF2A3230),
    outline: Color(0xFF3E4C48),
    textPrimary: Color(0xFFEDF2F0),
    textSecondary: Color(0xFFB5C0BC),
    heading: Color(0xFFF5FAF8),
    icon: Color(0xFFBCC4C0),
    success: Color(0xFF72A88E),
    warning: Color(0xFFC6B080),
    error: Color(0xFFB16C65),
  );

  /// Фон экрана
  final Color screen;

  /// Фон модальных окон / bottom sheets
  final Color modal;

  /// Фон карточек
  final Color card;

  /// Разделители
  final Color divider;

  /// Главные кнопки
  final Color primary;

  /// Наведение главных кнопок
  final Color primaryHover;

  /// Текст на главных кнопках
  final Color onPrimary;

  /// Фон второстепенных кнопок
  final Color secondaryButton;

  /// Обводка
  final Color outline;

  /// Основной текст
  final Color textPrimary;

  /// Второстепенный текст
  final Color textSecondary;

  /// Заголовки
  final Color heading;

  /// Иконки
  final Color icon;

  /// Успех
  final Color success;

  /// Предупреждение
  final Color warning;

  /// Ошибка
  final Color error;

  AppColorTokens copyWith({
    Color? screen,
    Color? modal,
    Color? card,
    Color? divider,
    Color? primary,
    Color? primaryHover,
    Color? onPrimary,
    Color? secondaryButton,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? heading,
    Color? icon,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppColorTokens(
      screen: screen ?? this.screen,
      modal: modal ?? this.modal,
      card: card ?? this.card,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      onPrimary: onPrimary ?? this.onPrimary,
      secondaryButton: secondaryButton ?? this.secondaryButton,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      heading: heading ?? this.heading,
      icon: icon ?? this.icon,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  AppColorTokens lerp(AppColorTokens? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      screen: Color.lerp(screen, other.screen, t)!,
      modal: Color.lerp(modal, other.modal, t)!,
      card: Color.lerp(card, other.card, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondaryButton:
          Color.lerp(secondaryButton, other.secondaryButton, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      heading: Color.lerp(heading, other.heading, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
