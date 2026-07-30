import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/variegation.dart';

class PlantVariegationSelector extends StatelessWidget {
  final Variegation selected;
  final ValueChanged<Variegation> onChanged;

  const PlantVariegationSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Variegation>(
      key: ValueKey(selected),
      initialValue: selected,
      isExpanded: true,
      dropdownColor: AppColors.dark2,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Вариегатность',
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.dark2,
        prefixIcon: Icon(selected.icon, color: selected.iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.greenDeep),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: AppColors.goldAccent,
            width: 1.5,
          ),
        ),
      ),
      items: Variegation.values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
