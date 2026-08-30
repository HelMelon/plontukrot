import 'package:flutter/material.dart';
import 'package:plontukrot/core/app_footer_controller.dart';
import 'package:plontukrot/core/widgets/app_footer.dart';

/// Wraps routed content with a pinned bottom [AppFooter] on every page.
class AppPageShell extends StatelessWidget {
  const AppPageShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppFooterController.instance,
      builder: (context, _) {
        if (!AppFooterController.instance.visible) {
          return child;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: child),
            const AppFooter(),
          ],
        );
      },
    );
  }
}
