import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/currency/app_currency_controller.dart';
import '../../../../core/date_time_utils.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../models/finance_entry.dart';
import '../../../../models/fertilizer.dart';
import '../../../../services/component_service.dart';
import '../../../../services/fertilize_service.dart';
import '../../../../services/finance_service.dart';
import '../../../../services/soil_service.dart';

enum _CatalogLink {
  none,
  soilComponent,
  fertilizerIngredient,
  purchasedFertilizer,
  readyMadeSoil,
}

class AddFinanceEntrySheet extends StatefulWidget {
  final FinanceEntry? entry;
  final FinanceEntryType initialType;

  const AddFinanceEntrySheet({
    super.key,
    this.initialType = FinanceEntryType.expense,
  }) : entry = null;

  const AddFinanceEntrySheet.edit({
    super.key,
    required FinanceEntry this.entry,
  }) : initialType = FinanceEntryType.expense;

  @override
  State<AddFinanceEntrySheet> createState() => _AddFinanceEntrySheetState();
}

class _AddFinanceEntrySheetState extends State<AddFinanceEntrySheet> {
  final _service = FinanceService();
  final _componentService = ComponentService();
  final _fertilizeService = FertilizeService();
  final _soilService = SoilService();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late FinanceEntryType _type;
  late DateTime _date;
  _CatalogLink _catalogLink = _CatalogLink.none;
  bool _saving = false;
  String? _titleError;
  String? _amountError;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _amountController = TextEditingController(
      text: entry == null
          ? ''
          : (entry.amount % 1 == 0
              ? entry.amount.toInt().toString()
              : entry.amount.toString()),
    );
    _type = entry?.type ?? widget.initialType;
    _date = entry?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = dateWithCurrentTime(picked));
    }
  }

  double? _parseAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final amount = _parseAmount();

    String? titleError;
    String? amountError;
    if (title.isEmpty) titleError = l10n.financesTitleRequired;
    if (amount == null || amount < 0) {
      amountError = l10n.financesAmountRequired;
    }

    if (titleError != null || amountError != null) {
      setState(() {
        _titleError = titleError;
        _amountError = amountError;
      });
      return;
    }

    setState(() {
      _saving = true;
      _titleError = null;
      _amountError = null;
    });

    try {
      if (_isEditing) {
        await _service.updateEntry(
          id: widget.entry!.id,
          title: title,
          amount: amount!,
          type: _type,
          date: _date,
        );
      } else {
        var source = FinanceEntrySource.manual;
        if (_type == FinanceEntryType.expense) {
          switch (_catalogLink) {
            case _CatalogLink.soilComponent:
              source = FinanceEntrySource.soilComponent;
              await _componentService.addComponent(name: title);
            case _CatalogLink.fertilizerIngredient:
              source = FinanceEntrySource.fertilizer;
              await _fertilizeService.addIngredient(name: title);
            case _CatalogLink.purchasedFertilizer:
              source = FinanceEntrySource.purchasedFertilizer;
              await _fertilizeService.addFertilizer(
                name: title,
                kind: FertilizerKind.purchased,
              );
            case _CatalogLink.readyMadeSoil:
              source = FinanceEntrySource.soilMix;
              await _soilService.addSoil(name: title, components: const []);
            case _CatalogLink.none:
              break;
          }
        }

        await _service.addEntry(
          title: title,
          amount: amount!,
          type: _type,
          date: _date,
          source: source,
        );
      }

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
                    _isEditing ? l10n.financesEdit : l10n.financesAdd,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleLarge.copyWith(letterSpacing: -1),
                  ),
                  spacing.vXl,
                  SegmentedButton<FinanceEntryType>(
                    segments: [
                      ButtonSegment(
                        value: FinanceEntryType.expense,
                        label: Text(l10n.financesExpense),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment(
                        value: FinanceEntryType.income,
                        label: Text(l10n.financesIncome),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (value) {
                      setState(() {
                        _type = value.first;
                        if (_type != FinanceEntryType.expense) {
                          _catalogLink = _CatalogLink.none;
                        }
                      });
                    },
                  ),
                  spacing.vXl,
                  TextField(
                    controller: _titleController,
                    style: inputs.textStyle,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: inputs
                        .decoration(labelText: l10n.financesTitleLabel)
                        .copyWith(errorText: _titleError),
                  ),
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
                          labelText: l10n.financesAmountLabel(currency.symbol),
                        )
                        .copyWith(errorText: _amountError),
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
                              DateFormat('d MMM y').format(_date),
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
                  if (!_isEditing && _type == FinanceEntryType.expense) ...[
                    spacing.vXl,
                    Text(
                      l10n.financesAlsoAddToCatalog,
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    spacing.vSm,
                    Wrap(
                      spacing: spacing.sm,
                      runSpacing: spacing.sm,
                      children: [
                        FilterChip(
                          label: Text(l10n.financesAsSoilComponent),
                          selected: _catalogLink == _CatalogLink.soilComponent,
                          onSelected: (selected) {
                            setState(() {
                              _catalogLink = selected
                                  ? _CatalogLink.soilComponent
                                  : _CatalogLink.none;
                            });
                          },
                        ),
                        FilterChip(
                          label: Text(l10n.financesAsFertilizer),
                          selected:
                              _catalogLink == _CatalogLink.fertilizerIngredient,
                          onSelected: (selected) {
                            setState(() {
                              _catalogLink = selected
                                  ? _CatalogLink.fertilizerIngredient
                                  : _CatalogLink.none;
                            });
                          },
                        ),
                        FilterChip(
                          label: Text(l10n.financesAsPurchasedFertilizer),
                          selected: _catalogLink ==
                              _CatalogLink.purchasedFertilizer,
                          onSelected: (selected) {
                            setState(() {
                              _catalogLink = selected
                                  ? _CatalogLink.purchasedFertilizer
                                  : _CatalogLink.none;
                            });
                          },
                        ),
                        FilterChip(
                          label: Text(l10n.financesAsReadyMadeSoil),
                          selected: _catalogLink == _CatalogLink.readyMadeSoil,
                          onSelected: (selected) {
                            setState(() {
                              _catalogLink = selected
                                  ? _CatalogLink.readyMadeSoil
                                  : _CatalogLink.none;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
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
                          : Text(l10n.commonSave),
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
