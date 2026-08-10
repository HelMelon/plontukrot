import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Red helper under a required control (consent, custom fields, etc.).
///
/// Prefer [InputDecoration.errorText] for [TextFormField]; use this for
/// non-input requirements that block a primary action.
class FieldErrorText extends StatelessWidget {
  final String message;

  const FieldErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Text(
      message,
      style: typography.bodySmall.copyWith(color: colors.error),
    );
  }
}
