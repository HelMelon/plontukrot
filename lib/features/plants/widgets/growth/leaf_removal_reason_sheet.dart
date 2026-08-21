import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/growth_event.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

Future<LeafRemovalReason?> showLeafRemovalReasonSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final colors = context.colors;
  final spacing = context.spacing;
  final sheets = context.components.sheets;
  final typography = context.typography;
  return showAppModalBottomSheet<LeafRemovalReason>(
    context: context,
    backgroundColor: colors.modal,
    shape: RoundedRectangleBorder(
      borderRadius: sheets.topBorderRadius,
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(spacing.lg, spacing.sm, spacing.lg, spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: const SheetDragHandle()),
              spacing.vMd,
              Text(
                l10n.plantLeafRemoveTitle,
                style: typography.titleSmall,
              ),
              spacing.vSm,
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ExcludeSemantics(
                  child: Icon(context.icons.leafCut, color: colors.icon),
                ),
                title: Text(l10n.plantLeafRemoveCut),
                onTap: () =>
                    Navigator.pop(context, LeafRemovalReason.cutForRooting),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ExcludeSemantics(
                  child: Icon(context.icons.leafEaten, color: colors.icon),
                ),
                title: Text(l10n.plantLeafRemoveEaten),
                onTap: () => Navigator.pop(context, LeafRemovalReason.eaten),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ExcludeSemantics(
                  child: Icon(context.icons.watering, color: colors.icon),
                ),
                title: Text(l10n.plantLeafRemoveDried),
                onTap: () => Navigator.pop(context, LeafRemovalReason.dried),
              ),
            ],
          ),
        ),
      );
    },
  );
}
