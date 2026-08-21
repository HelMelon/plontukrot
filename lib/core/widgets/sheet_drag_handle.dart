import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Decorative bottom-sheet drag indicator (not announced to assistive tech).
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final sheets = context.components.sheets;
    return ExcludeSemantics(
      child: Center(
        child: Container(
          width: sheets.handleWidth,
          height: sheets.handleHeight,
          decoration: BoxDecoration(
            color: sheets.handleColor,
            borderRadius: BorderRadius.circular(sheets.handleRadius),
          ),
        ),
      ),
    );
  }
}
