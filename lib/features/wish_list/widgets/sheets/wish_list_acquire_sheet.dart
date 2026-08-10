import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/currency/app_currency_controller.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../models/finance_entry.dart';
import '../../../../models/wish_list_item.dart';
import '../../../../services/finance_service.dart';
import '../../../plants/widgets/sheets/add_plant_sheet.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

enum WishListAcquireMode { bought, exchanged }

/// Result of the acquire dialog before opening AddPlantSheet.
class WishListAcquireResult {
  final WishListAcquireMode mode;
  final double? amount;

  const WishListAcquireResult({
    required this.mode,
    this.amount,
  });
}

class WishListAcquireSheet extends StatefulWidget {
  final WishListItem item;

  const WishListAcquireSheet({super.key, required this.item});

  @override
  State<WishListAcquireSheet> createState() => _WishListAcquireSheetState();
}

class _WishListAcquireSheetState extends State<WishListAcquireSheet> {
  final _amountController = TextEditingController();
  WishListAcquireMode _mode = WishListAcquireMode.bought;
  bool _saving = false;
  String? _amountError;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? _parseAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw);
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);

    if (_mode == WishListAcquireMode.bought) {
      final amount = _parseAmount();
      if (amount == null || amount < 0) {
        setState(() => _amountError = l10n.financesAmountRequired);
        return;
      }

      setState(() {
        _saving = true;
        _amountError = null;
      });

      try {
        await FinanceService().addEntry(
          title: widget.item.nameAlt,
          amount: amount,
          type: FinanceEntryType.expense,
          date: DateTime.now(),
          source: FinanceEntrySource.wishListPurchase,
          wishListItemId: widget.item.id,
        );
      } catch (e) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.commonError('$e'))),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    Navigator.pop(
      context,
      WishListAcquireResult(
        mode: _mode,
        amount: _mode == WishListAcquireMode.bought ? _parseAmount() : null,
      ),
    );
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
    final sheets = context.components.sheets;
    final inputs = context.components.inputs;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final currency = AppCurrencyController.instance.currency;

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
                    l10n.wishListAcquireTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleLarge.copyWith(letterSpacing: -1),
                  ),
                  spacing.vXs,
                  Text(
                    widget.item.nameAlt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodyLarge.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  spacing.vXl,
                  SegmentedButton<WishListAcquireMode>(
                    segments: [
                      ButtonSegment(
                        value: WishListAcquireMode.bought,
                        label: Text(l10n.wishListBought),
                      ),
                      ButtonSegment(
                        value: WishListAcquireMode.exchanged,
                        label: Text(l10n.wishListExchanged),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (value) {
                      setState(() {
                        _mode = value.first;
                        _amountError = null;
                      });
                    },
                  ),
                  if (_mode == WishListAcquireMode.bought) ...[
                    spacing.vXl,
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
                            labelText:
                                l10n.financesAmountLabel(currency.symbol),
                          )
                          .copyWith(errorText: _amountError),
                    ),
                  ] else ...[
                    spacing.vXl,
                    Text(
                      l10n.wishListExchangeNoFinanceHint,
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  spacing.vXxxl,
                  SizedBox(
                    width: double.infinity,
                    height: dimensions.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _confirm,
                      child: _saving
                          ? SizedBox(
                              width: dimensions.iconXl,
                              height: dimensions.iconXl,
                              child: AccessibleProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                            )
                          : Text(l10n.commonContinue),
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

/// Opens acquire sheet, then AddPlantSheet on success.
Future<void> openWishListAcquireFlow(
  BuildContext context,
  WishListItem item,
) async {
  final result = await showModalBottomSheet<WishListAcquireResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    builder: (_) => WishListAcquireSheet(item: item),
  );

  if (result == null || !context.mounted) return;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    builder: (_) => AddPlantSheet(
      initialTradingName: item.nameAlt,
      wishListItemId: item.id,
    ),
  );
}
