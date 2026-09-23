import 'package:flutter/material.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/quarantine_reason.dart';

/// Checkbox + reason chips for create/edit plant sheets.
class PlantQuarantineFields extends StatelessWidget {
  final bool enabled;
  final QuarantineReason? reason;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<QuarantineReason> onReasonChanged;

  const PlantQuarantineFields({
    super.key,
    required this.enabled,
    required this.reason,
    required this.onEnabledChanged,
    required this.onReasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: enabled,
          onChanged: (value) => onEnabledChanged(value ?? false),
          title: Text(
            l10n.plantQuarantine,
            style: typography.bodyMedium,
          ),
          subtitle: Text(
            l10n.plantQuarantineHint,
            style: typography.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        if (enabled) ...[
          spacing.vXs,
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            children: [
              FilterChip(
                label: Text(l10n.plantQuarantineReasonPurchase),
                selected: reason == QuarantineReason.purchase,
                onSelected: (_) =>
                    onReasonChanged(QuarantineReason.purchase),
              ),
              FilterChip(
                label: Text(l10n.plantQuarantineReasonRepotting),
                selected: reason == QuarantineReason.repotting,
                onSelected: (_) =>
                    onReasonChanged(QuarantineReason.repotting),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
