import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/plant_sensor_binding.dart';
import 'package:plontukrot/services/plant_sensor_service.dart';

/// Lets the user bind a soil-moisture pot (1..N) to this plant and shows the
/// latest moisture reading. Mirrors the BalconyToggle card style.
class SensorBindingToggle extends StatefulWidget {
  final String plantId;

  const SensorBindingToggle({super.key, required this.plantId});

  @override
  State<SensorBindingToggle> createState() => _SensorBindingToggleState();
}

class _SensorBindingToggleState extends State<SensorBindingToggle> {
  final PlantSensorService _service = PlantSensorService();
  late final Stream<PlantSensorBinding?> _bindingStream;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _bindingStream = _service.watchBinding(widget.plantId);
  }

  @override
  void didUpdateWidget(SensorBindingToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plantId != widget.plantId) {
      _bindingStream = _service.watchBinding(widget.plantId);
    }
  }

  Future<void> _bind(int pot) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.bind(plantId: widget.plantId, pot: pot);
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

  Future<void> _unbind() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.unbind(widget.plantId);
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

    return StreamBuilder<PlantSensorBinding?>(
      stream: _bindingStream,
      builder: (context, snapshot) {
        final binding = snapshot.data;
        final bound = binding != null && binding.pot > 0;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: spacing.sm, vertical: spacing.xs),
          decoration: BoxDecoration(
            color:
                bound ? colors.primary.withValues(alpha: 0.12) : colors.modal,
            borderRadius: BorderRadius.circular(context.radii.sm),
            border: Border.all(
              color: bound
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: context.icons.humidity,
                    size: context.dimensions.iconMd,
                  ),
                  spacing.hSm,
                  Expanded(
                    child: Text(
                      l10n.sensorBindingTitle,
                      style: typography.bodyEmphasis.copyWith(
                        color: bound ? colors.primary : colors.textPrimary,
                      ),
                    ),
                  ),
                  if (bound)
                    IconButton(
                      tooltip: l10n.sensorBindingUnbind,
                      onPressed: _busy ? null : _unbind,
                      icon: Icon(context.icons.remove,
                          size: context.dimensions.iconSm),
                    ),
                ],
              ),
              if (bound) ...[
                spacing.vXs,
                Text(
                  l10n.sensorBindingBound(binding.pot),
                  style:
                      typography.caption.copyWith(color: colors.textSecondary),
                ),
                if (binding.hasReading) ...[
                  spacing.vXxs,
                  Text(
                    l10n.sensorBindingMoisture(
                        binding.moisture!.roundToDouble()),
                    style: typography.bodyMedium.copyWith(
                      color: binding.moisture! < 20
                          ? colors.error
                          : colors.textPrimary,
                    ),
                  ),
                ] else ...[
                  spacing.vXxs,
                  Text(
                    l10n.sensorBindingNoReading,
                    style: typography.caption
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
              ] else ...[
                spacing.vXs,
                Wrap(
                  spacing: spacing.xs,
                  runSpacing: spacing.xs,
                  children: [
                    for (var pot = 1; pot <= 3; pot++)
                      ActionChip(
                        label: Text(l10n.sensorBindingPot(pot)),
                        onPressed: _busy ? null : () => _bind(pot),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
