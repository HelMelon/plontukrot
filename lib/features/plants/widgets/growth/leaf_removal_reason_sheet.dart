import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/growth_event.dart';

Future<LeafRemovalReason?> showLeafRemovalReasonSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final colors = context.colors;
  final spacing = context.spacing;
  final sheets = context.components.sheets;
  final typography = context.typography;
  return showModalBottomSheet<LeafRemovalReason>(
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
              Center(
                child: Container(
                  width: sheets.handleWidth,
                  height: sheets.handleHeight,
                  decoration: BoxDecoration(
                    color: sheets.handleColor,
                    borderRadius: BorderRadius.circular(sheets.handleRadius),
                  ),
                ),
              ),
              spacing.vMd,
              Text(
                l10n.plantLeafRemoveTitle,
                style: typography.titleSmall,
              ),
              spacing.vSm,
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.content_cut, color: colors.icon),
                title: Text(l10n.plantLeafRemoveCut),
                onTap: () =>
                    Navigator.pop(context, LeafRemovalReason.cutForRooting),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.restaurant, color: colors.icon),
                title: Text(l10n.plantLeafRemoveEaten),
                onTap: () => Navigator.pop(context, LeafRemovalReason.eaten),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.water_drop_outlined, color: colors.icon),
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
