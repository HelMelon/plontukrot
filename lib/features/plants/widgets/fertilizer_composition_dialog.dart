import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/fertilizer_dose.dart';

Future<void> showFertilizerCompositionDialog({
  required BuildContext context,
  required String title,
  required List<FertilizerDose> components,
  int? waterMl,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(title),
        content: components.isEmpty && waterMl == null
            ? const Text('No components')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (waterMl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Water: ${waterMl}ml',
                        style: const TextStyle(
                          color: AppColors.heading,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (components.isEmpty)
                    const Text('No components')
                  else
                    ...components.map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          c.label,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
