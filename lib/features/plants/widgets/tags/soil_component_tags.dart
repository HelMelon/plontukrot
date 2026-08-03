import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/component.dart';

String formatParts(double parts) {
  if (parts == parts.roundToDouble()) {
    return parts.toInt().toString();
  }
  if (parts == 0.5) return '½';
  return parts.toString();
}

class SoilComponentTags extends StatelessWidget {
  final List<String> availableComponents;
  final List<SoilComponent> selected;
  final ValueChanged<List<SoilComponent>> onChanged;
  final VoidCallback? onAddCustom;

  const SoilComponentTags({
    super.key,
    required this.availableComponents,
    required this.selected,
    required this.onChanged,
    this.onAddCustom,
  });

  SoilComponent? _find(String name) {
    for (final c in selected) {
      if (c.component == name) return c;
    }
    return null;
  }

  void _onTap(String name) {
    final existing = _find(name);
    final next = List<SoilComponent>.from(selected);

    if (existing == null) {
      next.add(SoilComponent(component: name, parts: 1));
    } else {
      final index = next.indexWhere((c) => c.component == name);
      next[index] = SoilComponent(
        component: name,
        parts: existing.parts + 1,
      );
    }

    onChanged(next);
  }

  void _onLongPress(String name) {
    final existing = _find(name);
    final next = List<SoilComponent>.from(selected);

    if (existing == null) {
      next.add(SoilComponent(component: name, parts: 0.5));
    } else if (existing.parts > 0.5) {
      final index = next.indexWhere((c) => c.component == name);
      next[index] = SoilComponent(component: name, parts: 0.5);
    } else {
      next.removeWhere((c) => c.component == name);
    }

    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final chipMaxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...availableComponents.map((name) {
              final selectedComponent = _find(name);
              final isSelected = selectedComponent != null;

              return GestureDetector(
                onTap: () => _onTap(name),
                onLongPress: () => _onLongPress(name),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: chipMaxWidth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.goldAccent.withValues(alpha: 0.25)
                          : AppColors.greenDeep,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.goldAccent
                            : AppColors.greenSoft,
                      ),
                    ),
                    child: Text(
                      isSelected
                          ? '$name · ${formatParts(selectedComponent.parts)}'
                          : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.goldAccent
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (onAddCustom != null)
              GestureDetector(
                onTap: onAddCustom,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sage),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16, color: AppColors.heading),
                      const SizedBox(width: 4),
                      Text(
                        l10n.commonAdd,
                        style: const TextStyle(color: AppColors.heading),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
