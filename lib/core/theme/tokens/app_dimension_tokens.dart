import 'package:flutter/material.dart';

@immutable
class AppDimensionTokens {
  const AppDimensionTokens({
    required this.buttonHeight,
    required this.iconSm,
    required this.iconMd,
    required this.iconLg,
    required this.iconXl,
    required this.avatar,
    required this.photoPlaceholder,
    required this.dragHandleWidth,
    required this.dragHandleHeight,
    required this.minTapTarget,
  });

  static const standard = AppDimensionTokens(
    buttonHeight: 52,
    iconSm: 16,
    iconMd: 18,
    iconLg: 20,
    iconXl: 22,
    avatar: 40,
    photoPlaceholder: 40,
    dragHandleWidth: 40,
    dragHandleHeight: 4,
    minTapTarget: 40,
  );

  final double buttonHeight;
  final double iconSm;
  final double iconMd;
  final double iconLg;
  final double iconXl;
  final double avatar;
  final double photoPlaceholder;
  final double dragHandleWidth;
  final double dragHandleHeight;
  final double minTapTarget;

  Size get buttonMinSize => Size(64, buttonHeight);
  Size get buttonMaxSize => Size(double.infinity, buttonHeight);

  AppDimensionTokens lerp(AppDimensionTokens? other, double t) {
    if (other is! AppDimensionTokens) return this;
    double l(double a, double b) => a + (b - a) * t;
    return AppDimensionTokens(
      buttonHeight: l(buttonHeight, other.buttonHeight),
      iconSm: l(iconSm, other.iconSm),
      iconMd: l(iconMd, other.iconMd),
      iconLg: l(iconLg, other.iconLg),
      iconXl: l(iconXl, other.iconXl),
      avatar: l(avatar, other.avatar),
      photoPlaceholder: l(photoPlaceholder, other.photoPlaceholder),
      dragHandleWidth: l(dragHandleWidth, other.dragHandleWidth),
      dragHandleHeight: l(dragHandleHeight, other.dragHandleHeight),
      minTapTarget: l(minTapTarget, other.minTapTarget),
    );
  }
}
