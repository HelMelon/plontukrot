import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/component.dart';
import '../tags/soil_component_tags.dart';

Future<void> showSoilCompositionDialog({
  required BuildContext context,
  required String title,
  required List<SoilComponent> components,
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
        content: components.isEmpty
            ? Text(l10n.noComponents, style: dialogs.bodyStyle)
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: components
                        .map(
                          (c) => Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: spacing.xxs,
                            ),
                            child: Text(
                              '${c.component} — ${l10n.soilParts(formatParts(c.parts))}',
                              style: dialogs.bodyStyle.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
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
