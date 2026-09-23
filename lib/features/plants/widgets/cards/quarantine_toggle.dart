import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/plant.dart';
import 'package:plontukrot/models/quarantine_reason.dart';
import 'package:plontukrot/services/plant_service.dart';

/// Toggle quarantine on the plant details page (separate from reanimation).
class QuarantineToggle extends StatefulWidget {
  final Plant plant;
  final String plantId;

  const QuarantineToggle({
    super.key,
    required this.plant,
    required this.plantId,
  });

  @override
  State<QuarantineToggle> createState() => _QuarantineToggleState();
}

class _QuarantineToggleState extends State<QuarantineToggle> {
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await PlantService().setQuarantine(
        plantId: widget.plantId,
        enabled: on,
        reason: on
            ? (widget.plant.quarantineReason ?? QuarantineReason.purchase)
            : null,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).commonError(''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setReason(QuarantineReason reason) async {
    if (_busy || !widget.plant.isInQuarantine()) return;
    setState(() => _busy = true);
    try {
      await PlantService().setQuarantine(
        plantId: widget.plantId,
        enabled: true,
        reason: reason,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).commonError(''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final on = widget.plant.isInQuarantine();
    final until = widget.plant.quarantineUntil;
    final reason = widget.plant.quarantineReason;
    final dateLocale = Localizations.localeOf(context).toString();
    final untilLabel = until == null
        ? null
        : l10n.quarantineUntilLabel(
            DateFormat('d.MM.yyyy', dateLocale).format(until),
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
      decoration: BoxDecoration(
        color: on ? colors.warning.withValues(alpha: 0.12) : colors.modal,
        borderRadius: BorderRadius.circular(context.radii.sm),
        border: Border.all(
          color: on ? colors.warning : colors.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                context.icons.quarantine,
                color: on ? colors.warning : colors.icon,
                size: context.dimensions.iconMd,
              ),
              spacing.hSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      on ? l10n.quarantineOn : l10n.quarantineOff,
                      style: typography.bodyEmphasis.copyWith(
                        color: on ? colors.warning : colors.textPrimary,
                      ),
                    ),
                    if (on && untilLabel != null)
                      Text(
                        untilLabel,
                        style: typography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: on,
                onChanged: _busy ? null : _toggle,
              ),
            ],
          ),
          if (on) ...[
            spacing.vXs,
            Wrap(
              spacing: spacing.xs,
              runSpacing: spacing.xs,
              children: [
                FilterChip(
                  label: Text(l10n.plantQuarantineReasonPurchase),
                  selected: reason == QuarantineReason.purchase,
                  onSelected: _busy
                      ? null
                      : (_) => _setReason(QuarantineReason.purchase),
                ),
                FilterChip(
                  label: Text(l10n.plantQuarantineReasonRepotting),
                  selected: reason == QuarantineReason.repotting,
                  onSelected: _busy
                      ? null
                      : (_) => _setReason(QuarantineReason.repotting),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
