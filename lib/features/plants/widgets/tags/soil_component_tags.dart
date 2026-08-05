import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
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
    } else {
      final nextParts = existing.parts - 1;
      if (nextParts < 0.5) {
        next.removeWhere((c) => c.component == name);
      } else {
        final index = next.indexWhere((c) => c.component == name);
        next[index] = SoilComponent(component: name, parts: nextParts);
      }
    }

    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final catalog = context.screens.catalogBuilder;
    final dimensions = context.dimensions;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chipMaxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return Wrap(
          spacing: spacing.xs,
          runSpacing: spacing.xs,
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
                    padding: catalog.tagPadding,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.25)
                          : colors.outline,
                      borderRadius: BorderRadius.circular(catalog.tagRadius),
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.divider,
                      ),
                    ),
                    child: Text(
                      isSelected
                          ? '$name · ${formatParts(selectedComponent.parts)}'
                          : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.label.copyWith(
                        color: isSelected ? colors.primary : colors.textPrimary,
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
                  padding: catalog.tagPadding,
                  decoration: BoxDecoration(
                    color: colors.modal,
                    borderRadius: BorderRadius.circular(catalog.tagRadius),
                    border: Border.all(color: colors.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: dimensions.iconSm,
                        color: colors.icon,
                      ),
                      spacing.hXxs,
                      Text(
                        l10n.commonAdd,
                        style: typography.label.copyWith(color: colors.heading),
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
