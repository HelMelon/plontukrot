import 'package:flutter/material.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
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
    final colors = context.colors;
    final inputs = context.components.inputs;

    return DropdownButtonFormField<Variegation>(
      key: ValueKey(selected),
      initialValue: selected,
      isExpanded: true,
      dropdownColor: colors.card,
      style: inputs.textStyle.copyWith(color: colors.textPrimary),
      decoration: inputs
          .decoration(
            labelText: l10n.variegationLabel,
            prefixIcon: Icon(selected.icon, color: selected.iconColor),
          )
          .copyWith(
            labelStyle: inputs.labelStyle.copyWith(
              color: colors.textSecondary,
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
