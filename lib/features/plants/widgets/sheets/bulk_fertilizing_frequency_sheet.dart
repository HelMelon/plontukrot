import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/fertilizing_frequency.dart';
import '../../../../models/plant.dart';
import '../../../../services/plant_service.dart';

/// Sets fertilizing frequency for every plant in a home multi-selection.
class BulkFertilizingFrequencySheet extends StatefulWidget {
  final List<Plant> plants;

  const BulkFertilizingFrequencySheet({
    super.key,
    required this.plants,
  });

  @override
  State<BulkFertilizingFrequencySheet> createState() =>
      _BulkFertilizingFrequencySheetState();
}

class _BulkFertilizingFrequencySheetState
    extends State<BulkFertilizingFrequencySheet> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _errorText;

  bool get _mixed {
    if (widget.plants.length < 2) return false;
    final first = normalizeFertilizingFrequencyDays(
      widget.plants.first.fertilizingFrequencyDays,
    );
    return widget.plants.any(
      (plant) =>
          normalizeFertilizingFrequencyDays(plant.fertilizingFrequencyDays) !=
          first,
    );
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.plants.isEmpty || _mixed
        ? ''
        : normalizeFertilizingFrequencyDays(
            widget.plants.first.fertilizingFrequencyDays,
          ).toString();
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parseDays() => int.tryParse(_controller.text.trim());

  bool _isValid(int? days) {
    if (days == null) return false;
    if (days == fertilizingFrequencyStop) return true;
    return days >= 1 && days <= 180;
  }

  Future<void> _apply({
    required bool isCustom,
    int? frequencyDays,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await PlantService().updatePlantsFertilizingFrequency(
        plants: widget.plants,
        isCustom: isCustom,
        frequencyDays: frequencyDays,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).commonError('$error')),
        ),
      );
    }
  }

  Future<void> _save() async {
    final days = _parseDays();
    if (!_isValid(days)) {
      setState(() {
        _errorText = AppLocalizations.of(context).plantInvalidFertilizingFrequency;
      });
      return;
    }
    await _apply(isCustom: true, frequencyDays: days);
  }

  Future<void> _resetToAuto() => _apply(isCustom: false);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final inputs = context.components.inputs;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: BoxDecoration(
          color: colors.modal,
          borderRadius: sheets.topBorderRadius,
        ),
        child: SingleChildScrollView(
          padding: sheets.contentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(child: SheetDragHandle()),
              spacing.vXxl,
              Text(
                l10n.plantFertilizingFrequency,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typography.titleLarge.copyWith(letterSpacing: -1),
              ),
              if (_mixed) ...[
                spacing.vXs,
                Text(
                  l10n.homeFertilizingFrequencyMixed,
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              spacing.vMd,
              TextField(
                controller: _controller,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                style: inputs.textStyle,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                decoration: inputs.decoration(
                  labelText: l10n.plantFertilizingFrequencyDays,
                  errorText: _errorText,
                  prefixIcon: Icon(
                    context.icons.fertilizingEco,
                    color: colors.icon,
                  ),
                ),
              ),
              spacing.vXs,
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _saving ? null : _resetToAuto,
                  child: Text(l10n.plantFertilizingResetAuto),
                ),
              ),
              spacing.vSm,
              Text(
                l10n.plantFertilizingFrequencyHint,
                style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              spacing.vLg,
              SizedBox(
                width: double.infinity,
                height: dimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? SizedBox(
                          width: dimensions.iconXl,
                          height: dimensions.iconXl,
                          child: AccessibleProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      : Text(
                          l10n.commonSave,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
              spacing.vMd,
            ],
          ),
        ),
      ),
    );
  }
}
