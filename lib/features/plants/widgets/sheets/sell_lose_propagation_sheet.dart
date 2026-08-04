import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/date_time_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 22, 22, 24 + keyboard),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.propagationOutcomeLabel(widget.outcome),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.propagationAliveWithPlant(
                      widget.propagation.quantityAlive,
                      widget.propagation.parentPlantName,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: _quantityLabel(l10n),
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.dark2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: AppColors.greenDeep),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AppColors.goldAccent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dark2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.greenDeep),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.accentLight,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.propagationDate(
                                DateFormat('d MMM y').format(_at),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.notesOptional,
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.dark2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: AppColors.greenDeep),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AppColors.goldAccent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: AppTheme.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldAccent,
                        foregroundColor: AppColors.dark1,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.dark1,
                              ),
                            )
                          : Text(
                              _buttonLabel(l10n),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
