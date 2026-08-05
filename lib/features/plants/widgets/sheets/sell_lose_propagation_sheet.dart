import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/date_time_utils.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../models/propagation.dart';
import '../../../../models/propagation_outcome.dart';
import '../../../../services/propagation_service.dart';

class MarkPropagationOutcomeSheet extends StatefulWidget {
  final Propagation propagation;
  final PropagationOutcome outcome;

  const MarkPropagationOutcomeSheet({
    super.key,
    required this.propagation,
    required this.outcome,
  });

  @override
  State<MarkPropagationOutcomeSheet> createState() =>
      _MarkPropagationOutcomeSheetState();
}

class _MarkPropagationOutcomeSheetState
    extends State<MarkPropagationOutcomeSheet> {
  final _service = PropagationService();
  final _noteController = TextEditingController();
  late final TextEditingController _quantityController;

  DateTime _at = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: '${widget.propagation.quantityAlive}',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: widget.propagation.startedAt,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _at = dateWithCurrentTime(picked));
  }

  String _quantityRequiredMessage(AppLocalizations l10n) {
    return switch (widget.outcome) {
      PropagationOutcome.sold => l10n.propagationSellQuantityRequired,
      PropagationOutcome.gifted => l10n.propagationGiftQuantityRequired,
      PropagationOutcome.traded => l10n.propagationTradeQuantityRequired,
      PropagationOutcome.lost => l10n.propagationLoseQuantityRequired,
    };
  }

  String _quantityLabel(AppLocalizations l10n) {
    return switch (widget.outcome) {
      PropagationOutcome.sold => l10n.propagationSellQuantity,
      PropagationOutcome.gifted => l10n.propagationGiftQuantity,
      PropagationOutcome.traded => l10n.propagationTradeQuantity,
      PropagationOutcome.lost => l10n.propagationLoseQuantity,
    };
  }

  String _buttonLabel(AppLocalizations l10n) {
    return switch (widget.outcome) {
      PropagationOutcome.sold => l10n.propagationSell,
      PropagationOutcome.gifted => l10n.propagationConfirmGift,
      PropagationOutcome.traded => l10n.propagationConfirmTrade,
      PropagationOutcome.lost => l10n.propagationWriteOff,
    };
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_quantityRequiredMessage(l10n))),
      );
      return;
    }
    if (quantity > widget.propagation.quantityAlive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.propagationQuantityExceedsAlive(
              widget.propagation.quantityAlive,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.markOutcome(
        propagationId: widget.propagation.id,
        outcome: widget.outcome,
        quantity: quantity,
        at: _at,
        note: _noteController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final maxHeight =
        (media.size.height - keyboard - 72).clamp(160.0, media.size.height);
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final sheets = context.components.sheets;
    final inputs = context.components.inputs;
    final typography = context.typography;
    final dimensions = context.dimensions;

    return Container(
      decoration: BoxDecoration(
        color: colors.modal,
        borderRadius: sheets.topBorderRadius,
      ),
      child: SafeArea(
        child: Padding(
          padding: sheets.contentPadding.copyWith(
            bottom: spacing.xl + keyboard,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: sheets.handleWidth,
                      height: sheets.handleHeight,
                      decoration: BoxDecoration(
                        color: sheets.handleColor,
                        borderRadius: BorderRadius.circular(sheets.handleRadius),
                      ),
                    ),
                  ),
                  spacing.vXxl,
                  Text(
                    l10n.propagationOutcomeLabel(widget.outcome),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleLarge.copyWith(
                      letterSpacing: -1,
                    ),
                  ),
                  spacing.vXs,
                  Text(
                    l10n.propagationAliveWithPlant(
                      widget.propagation.quantityAlive,
                      widget.propagation.parentPlantName,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodyLarge.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  spacing.vXl,
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: inputs.textStyle,
                    decoration: inputs.decoration(
                      labelText: _quantityLabel(l10n),
                    ),
                  ),
                  spacing.vMd,
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(radii.lg),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.md,
                        vertical: spacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(radii.lg),
                        border: Border.all(color: colors.outline),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: colors.icon,
                            size: dimensions.iconLg,
                          ),
                          spacing.hSm,
                          Expanded(
                            child: Text(
                              l10n.propagationDate(
                                DateFormat('d MMM y').format(_at),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: typography.bodyLarge.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  spacing.vMd,
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    style: inputs.textStyle,
                    decoration: inputs.decoration(
                      labelText: l10n.notesOptional,
                    ),
                  ),
                  spacing.vXxxl,
                  SizedBox(
                    width: double.infinity,
                    height: dimensions.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? SizedBox(
                              width: dimensions.iconXl,
                              height: dimensions.iconXl,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Text(_buttonLabel(l10n)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Backwards-compatible aliases used by existing call sites.
class SellPropagationSheet extends MarkPropagationOutcomeSheet {
  const SellPropagationSheet({super.key, required super.propagation})
      : super(outcome: PropagationOutcome.sold);
}

class LosePropagationSheet extends MarkPropagationOutcomeSheet {
  const LosePropagationSheet({super.key, required super.propagation})
      : super(outcome: PropagationOutcome.lost);
}
