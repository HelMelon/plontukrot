import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Whether keyboard-oriented focus UX is a primary target for this build.
bool get appKeyboardUxEnabled {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// Wraps the app so modal focus and Tab traversal behave consistently.
class AppKeyboardScope extends StatelessWidget {
  final Widget child;

  const AppKeyboardScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // FocusTraversalGroup at root keeps reading-order Tab on hubs.
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: child,
    );
  }
}

/// Traps Tab inside a modal and focuses the first descendant on open.
class ModalFocusTrap extends StatelessWidget {
  final Widget child;

  const ModalFocusTrap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: true,
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: child,
      ),
    );
  }
}
