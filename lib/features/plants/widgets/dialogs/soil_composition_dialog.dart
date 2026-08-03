import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
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

      return AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: components.isEmpty
            ? Text(l10n.noComponents)
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: components
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${c.component} — ${l10n.soilParts(formatParts(c.parts))}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
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
