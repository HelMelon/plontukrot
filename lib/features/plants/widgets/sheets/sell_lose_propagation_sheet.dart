import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/currency/app_currency_controller.dart';
import '../../../../core/date_time_utils.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../models/finance_entry.dart';
import '../../../../models/propagation.dart';
import '../../../../models/propagation_outcome.dart';
import '../../../../services/finance_service.dart';
import '../../../../services/propagation_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

/// Result of marking a propagation outcome.
/// [linkWishList] is true only for trades where the user wants a wish-list plant.
class MarkPropagationOutcomeResult {
  final bool success;
  final bool linkWishList;

  const MarkPropagationOutcomeResult({
    required this.success,
    this.linkWishList = false,
  });
}

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
  final _financeService = FinanceService();
  final _noteController = TextEditingController();
  late final TextEditingController _quantityController;
  final _amountController = TextEditingController();

  DateTime _at = DateTime.now();
  bool _saving = false;
  bool _linkWishList = false;
  String? _amountError;

  bool get _isSold => widget.outcome == PropagationOutcome.sold;
  bool get _isTraded => widget.outcome == PropagationOutcome.traded;

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
    _amountController.dispose();
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

  double? _parseAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw);
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

    double? saleAmount;
    if (_isSold) {
      saleAmount = _parseAmount();
      if (saleAmount == null || saleAmount < 0) {
        setState(() => _amountError = l10n.financesAmountRequired);
        return;
      }
    }

    setState(() {
      _saving = true;
      _amountError = null;
    });
    try {
      await _service.markOutcome(
        propagationId: widget.propagation.id,
        outcome: widget.outcome,
        quantity: quantity,
        at: _at,
        note: _noteController.text.trim(),
      );

      if (_isSold && saleAmount != null) {
        final plantName = widget.propagation.parentPlantName;
        await _financeService.addEntry(
          title: l10n.financesPropagationSaleTitle(plantName, quantity),
          amount: saleAmount,
          type: FinanceEntryType.income,
          date: _at,
          source: FinanceEntrySource.propagationSale,
          propagationId: widget.propagation.id,
          quantity: quantity,
          note: _noteController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        MarkPropagationOutcomeResult(
          success: true,
          linkWishList: _isTraded && _linkWishList,
        ),
      );
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
                  Center(child: const SheetDragHandle()),
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
                  if (_isSold) ...[
                    spacing.vMd,
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: inputs.textStyle,
                      decoration: inputs
                          .decoration(
                            labelText: l10n.financesAmountLabel(
                              AppCurrencyController.instance.currency.symbol,
                            ),
                          )
                          .copyWith(errorText: _amountError),
                    ),
                  ],
                  if (_isTraded) ...[
                    spacing.vMd,
                    FilterChip(
                      label: Text(l10n.propagationTradeForWishList),
                      selected: _linkWishList,
                      onSelected: (selected) {
                        setState(() => _linkWishList = selected);
                      },
                    ),
                  ],
                  spacing.vMd,
                  Semantics(
                    button: true,
                    label: l10n.a11ySelectDate(
                      DateFormat('d MMM y').format(_at),
                    ),
                    child: InkWell(
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
                            ExcludeSemantics(
                              child: Icon(
                                Icons.calendar_today_outlined,
                                color: colors.icon,
                                size: dimensions.iconLg,
                              ),
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
                              child: AccessibleProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
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
