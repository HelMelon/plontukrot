import 'package:flutter/material.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/fertilizer_dose.dart';

Future<void> showFertilizerCompositionDialog({
  required BuildContext context,
  required String title,
  required List<FertilizerDose> components,
  int? waterMl,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final media = MediaQuery.of(context);
      final maxHeight = (media.size.height - media.viewInsets.bottom) * 0.5;
      final dialogs = context.components.dialogs;
      final spacing = context.spacing;
      final colors = context.colors;

      return AlertDialog(
        backgroundColor: dialogs.background,
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: dialogs.titleStyle,
        ),
        content: components.isEmpty && waterMl == null
            ? Text(l10n.noComponents, style: dialogs.bodyStyle)
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (waterMl != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: spacing.xs),
                          child: Text(
                            l10n.fertilizerWaterLine(waterMl),
                            style: dialogs.bodyStyle.copyWith(
                              color: colors.heading,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (components.isEmpty)
                        Text(l10n.noComponents, style: dialogs.bodyStyle)
                      else
                        ...components.map(
                          (c) => Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: spacing.xxs,
                            ),
                            child: Text(
                              l10n.fertilizerDoseLabel(c),
                              style: dialogs.bodyStyle.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
        ],
      );
    },
  );
}
