import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/quarantine.dart';
import 'package:plontukrot/models/quarantine_reason.dart';

/// Checkbox, reason chips, and start-date picker for create/edit plant sheets.
class PlantQuarantineFields extends StatelessWidget {
  final bool enabled;
  final QuarantineReason? reason;
  final DateTime startedAt;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<QuarantineReason> onReasonChanged;
  final ValueChanged<DateTime> onStartedAtChanged;

  const PlantQuarantineFields({
    super.key,
    required this.enabled,
    required this.reason,
    required this.startedAt,
    required this.onEnabledChanged,
    required this.onReasonChanged,
    required this.onStartedAtChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final typography = context.typography;
    final dateLocale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat('d.MM.yyyy', dateLocale).format(startedAt);
    final untilLabel = l10n.quarantineUntilLabel(
      DateFormat(
        'd.MM.yyyy',
        dateLocale,
      ).format(quarantineEndDate(startedAt)),
    );

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
                onSelected: (_) => onReasonChanged(QuarantineReason.purchase),
              ),
              FilterChip(
                label: Text(l10n.plantQuarantineReasonRepotting),
                selected: reason == QuarantineReason.repotting,
                onSelected: (_) => onReasonChanged(QuarantineReason.repotting),
              ),
            ],
          ),
          Semantics(
            button: true,
            label: l10n.a11ySelectDate('$dateLabel, $untilLabel'),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ExcludeSemantics(
                child: Icon(context.icons.calendar),
              ),
              title: Text(
                l10n.plantQuarantineStartDate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$dateLabel · $untilLabel',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () async {
                final picked = await showQuarantineStartDatePicker(
                  context,
                  initialDate: startedAt,
                );
                if (picked != null) onStartedAtChanged(picked);
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Picks a quarantine start inside the still-open 14-day window.
Future<DateTime?> showQuarantineStartDatePicker(
  BuildContext context, {
  required DateTime initialDate,
}) {
  final now = DateTime.now();
  final firstDate = earliestActiveQuarantineStart(now);
  final lastDate = latestQuarantineStart(now);
  var initial = quarantineCalendarDay(initialDate);
  if (initial.isBefore(firstDate)) initial = firstDate;
  if (initial.isAfter(lastDate)) initial = lastDate;
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}
