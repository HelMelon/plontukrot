import 'package:flutter/material.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
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

      return AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: components.isEmpty && waterMl == null
            ? Text(l10n.noComponents)
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (waterMl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            l10n.fertilizerWaterLine(waterMl),
                            style: const TextStyle(
                              color: AppColors.heading,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (components.isEmpty)
                        Text(l10n.noComponents)
                      else
                        ...components.map(
                          (c) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              l10n.fertilizerDoseLabel(c),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
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
