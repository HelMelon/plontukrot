import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../theme/theme_context.dart';

/// Circular progress with a screen-reader label (live region).
class AccessibleProgressIndicator extends StatelessWidget {
  final Color? color;
  final double? strokeWidth;
  final String? label;
  final double? size;

  const AccessibleProgressIndicator({
    super.key,
    this.color,
    this.strokeWidth,
    this.label,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resolvedColor = color ?? context.colors.primary;
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: resolvedColor,
        strokeWidth: strokeWidth ?? 2,
      ),
    );

    return Semantics(
      label: label ?? l10n.loading,
      liveRegion: true,
      child: ExcludeSemantics(child: indicator),
    );
  }
}
