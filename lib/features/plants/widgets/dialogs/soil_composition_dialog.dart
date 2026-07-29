import 'package:flutter/material.dart';

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
            ? const Text('Нет компонентов')
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
                              '${c.component} — ${formatParts(c.parts)} части',
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
            child: const Text('Закрыть'),
          ),
        ],
      );
    },
  );
}
