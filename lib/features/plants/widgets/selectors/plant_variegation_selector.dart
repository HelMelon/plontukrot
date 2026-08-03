import 'package:flutter/material.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);

    return DropdownButtonFormField<Variegation>(
      key: ValueKey(selected),
      initialValue: selected,
      isExpanded: true,
      dropdownColor: AppColors.dark2,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: l10n.variegationLabel,
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
                l10n.variegationLabelOf(item),
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
