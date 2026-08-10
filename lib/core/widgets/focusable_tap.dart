import 'package:flutter/material.dart';

import '../keyboard/app_keyboard.dart';
import '../theme/theme_context.dart';

/// Keyboard-focusable tap target (Enter/Space activate; visible focus ring).
///
/// Prefer over bare [GestureDetector] for actionable custom UI on web/desktop.
class FocusableTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final bool enabled;

  const FocusableTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.enabled = true,
  });

  @override
  State<FocusableTap> createState() => _FocusableTapState();
}

class _FocusableTapState extends State<FocusableTap> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ringWidth = context.dimensions.focusRingWidth;
    final radius = widget.borderRadius ?? BorderRadius.zero;
    final canTap = widget.enabled && widget.onTap != null;

    return FocusableActionDetector(
      enabled: canTap || widget.onLongPress != null,
      onShowFocusHighlight: (show) {
        if (_focused == show) return;
        setState(() => _focused = show);
      },
      actions: <Type, Action<Intent>>{
        if (canTap)
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canTap ? widget.onTap : null,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: _focused && appKeyboardUxEnabled
                  ? colors.primary
                  : colors.primary.withValues(alpha: 0),
              width: ringWidth,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
