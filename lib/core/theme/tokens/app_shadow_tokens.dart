import 'package:flutter/material.dart';

import 'app_color_tokens.dart';

@immutable
class AppShadowTokens {
  const AppShadowTokens({required this.card});

  factory AppShadowTokens.standard(AppColorTokens colors) {
    return AppShadowTokens(
      card: [
        BoxShadow(
          color: colors.screen.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  final List<BoxShadow> card;

  AppShadowTokens lerp(AppShadowTokens? other, double t) {
    if (other is! AppShadowTokens) return this;
    return t < 0.5 ? this : other;
  }
}
