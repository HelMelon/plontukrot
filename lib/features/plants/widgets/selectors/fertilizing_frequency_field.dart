import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/season/fertilizing_season_controller.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../models/fertilizing_frequency.dart';

/// Fertilizing frequency editor: days (0 = no fertilizing, 1–180 active).
class FertilizingFrequencyField extends StatefulWidget {
  final int stage;
  final int? frequencyDays;
  final bool isCustom;
  final ValueChanged<int?> onFrequencyChanged;
  final ValueChanged<bool> onCustomChanged;

  const FertilizingFrequencyField({
    super.key,
    required this.stage,
    required this.frequencyDays,
    required this.isCustom,
    required this.onFrequencyChanged,
    required this.onCustomChanged,
  });

  @override
  State<FertilizingFrequencyField> createState() =>
      _FertilizingFrequencyFieldState();
}

class _FertilizingFrequencyFieldState extends State<FertilizingFrequencyField> {
  late final TextEditingController _controller;

  static String _textForFrequency(int? days) {
    final normalized = normalizeFertilizingFrequencyDays(days);
    return normalized.toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _textForFrequency(widget.frequencyDays),
    );
  }

  @override
  void didUpdateWidget(covariant FertilizingFrequencyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage && !widget.isCustom) {
      _controller.text = _textForFrequency(widget.frequencyDays);
    } else if (oldWidget.frequencyDays != widget.frequencyDays &&
        widget.frequencyDays !=
            int.tryParse(_controller.text.trim())) {
      _controller.text = _textForFrequency(widget.frequencyDays);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyAutoFrequency() {
    final auto = resolveFertilizingFrequencyDays(
      stage: widget.stage,
      seasonSettings: FertilizingSeasonController.instance.settings,
      isCustom: false,
      currentFrequencyDays: null,
    );
    setState(() {
      _controller.text = _textForFrequency(auto);
    });
    widget.onFrequencyChanged(auto);
  }

  void _onDaysChanged(String raw) {
    widget.onCustomChanged(true);
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      widget.onFrequencyChanged(null);
      return;
    }
    widget.onFrequencyChanged(int.tryParse(trimmed));
  }

  void _resetToAuto() {
    widget.onCustomChanged(false);
    _applyAutoFrequency();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;
    final inputs = context.components.inputs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          style: inputs.textStyle,
          decoration: inputs.decoration(
            labelText: l10n.plantFertilizingFrequency,
            prefixIcon: Icon(Icons.eco_outlined, color: colors.icon),
          ),
          onChanged: _onDaysChanged,
        ),
        if (widget.isCustom) ...[
          spacing.vXs,
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _resetToAuto,
              child: Text(l10n.plantFertilizingResetAuto),
            ),
          ),
        ],
        spacing.vSm,
        SelectableText(
          l10n.plantFertilizingFrequencyHint,
          style: typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
