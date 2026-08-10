import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/currency/app_currency_controller.dart';
import 'package:plontukrot/core/date_time_utils.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/finance_entry.dart';
import '../../../../models/plant.dart';
import '../../../../models/plant_archive_reason.dart';
import '../../../../services/finance_service.dart';
import '../../../../services/note_service.dart';
import '../../../../services/plant_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

class ArchivePlantSheet extends StatefulWidget {
  final Plant plant;

  const ArchivePlantSheet({super.key, required this.plant});

  @override
  State<ArchivePlantSheet> createState() => _ArchivePlantSheetState();
}

class _ArchivePlantSheetState extends State<ArchivePlantSheet> {
  final _plantService = PlantService();
  final _financeService = FinanceService();
  final _noteService = NoteService();
  final _deathNoteController = TextEditingController();
  final _saleNoteController = TextEditingController();
  final _amountController = TextEditingController();

  PlantArchiveReason _reason = PlantArchiveReason.died;
  DateTime _at = DateTime.now();
  bool _saving = false;
  String? _deathNoteError;
  String? _amountError;

  @override
  void dispose() {
    _deathNoteController.dispose();
    _saleNoteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _at = dateWithCurrentTime(picked));
  }

  String _plantDisplayName(AppLocalizations l10n) {
    final nickname = widget.plant.nickname.trim();
    if (nickname.isNotEmpty) return nickname;
    final species = widget.plant.species.trim();
    if (species.isNotEmpty) return species;
    return l10n.commonUntitled;
  }

  double? _parseAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);

    if (_reason == PlantArchiveReason.died) {
      final note = _deathNoteController.text.trim();
      if (note.isEmpty) {
        setState(() => _deathNoteError = l10n.plantDisposeDeathNoteRequired);
        return;
      }
    }

    if (_reason == PlantArchiveReason.sold) {
      final amount = _parseAmount();
      if (amount == null || amount < 0) {
        setState(() => _amountError = l10n.financesAmountRequired);
        return;
      }
    }

    setState(() {
      _saving = true;
      _deathNoteError = null;
      _amountError = null;
    });

    try {
      if (_reason == PlantArchiveReason.sold) {
        final amount = _parseAmount()!;
        await _financeService.addEntry(
          title: l10n.financesPlantSaleTitle(_plantDisplayName(l10n)),
          amount: amount,
          type: FinanceEntryType.income,
          date: _at,
          source: FinanceEntrySource.plantSale,
          plantId: widget.plant.id,
          note: _saleNoteController.text.trim().isEmpty
              ? null
              : _saleNoteController.text.trim(),
        );
        await _plantService.archivePlant(
          plantId: widget.plant.id,
          reason: PlantArchiveReason.sold,
          at: _at,
          note: _saleNoteController.text.trim().isEmpty
              ? null
              : _saleNoteController.text.trim(),
        );
      } else {
        final note = _deathNoteController.text.trim();
        await _plantService.archivePlant(
          plantId: widget.plant.id,
          reason: PlantArchiveReason.died,
          at: _at,
          note: note,
        );
        await _noteService.addNote(
          parent: NoteParent.plant(widget.plant.id),
          text: note,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError(e.toString()))),
        );
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    String? errorText,
    required IconData icon,
  }) {
    final colors = context.colors;
    final inputs = context.components.inputs;
    return inputs
        .decoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: colors.icon),
        )
        .copyWith(errorText: errorText);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.92;
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final inputs = context.components.inputs;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final currency = AppCurrencyController.instance.currency;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: colors.modal,
            borderRadius: sheets.topBorderRadius,
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  spacing.vSm,
                  Center(
                    child: Container(
                      width: sheets.handleWidth,
                      height: sheets.handleHeight,
                      decoration: BoxDecoration(
                        color: sheets.handleColor,
                        borderRadius:
                            BorderRadius.circular(sheets.handleRadius),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sheets.contentPadding.left,
                      spacing.md,
                      sheets.contentPadding.right,
                      0,
                    ),
                    child: Text(
                      l10n.plantDisposeTitle,
                      style: typography.titleLarge.copyWith(
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        sheets.contentPadding.left,
                        spacing.md,
                        sheets.contentPadding.right,
                        spacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SegmentedButton<PlantArchiveReason>(
                            segments: [
                              ButtonSegment(
                                value: PlantArchiveReason.died,
                                label: Text(l10n.plantDisposeReasonDied),
                                icon: const Icon(Icons.heart_broken_outlined),
                              ),
                              ButtonSegment(
                                value: PlantArchiveReason.sold,
                                label: Text(l10n.plantDisposeReasonSold),
                                icon: const Icon(Icons.sell_outlined),
                              ),
                            ],
                            selected: {_reason},
                            onSelectionChanged: (value) {
                              setState(() {
                                _reason = value.first;
                                _deathNoteError = null;
                                _amountError = null;
                              });
                            },
                          ),
                          spacing.vMd,
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(DateFormat('d MMM y').format(_at)),
                            trailing: Icon(
                              Icons.calendar_today_outlined,
                              color: colors.icon,
                            ),
                            onTap: _pickDate,
                          ),
                          spacing.vMd,
                          if (_reason == PlantArchiveReason.died)
                            TextField(
                              controller: _deathNoteController,
                              maxLines: 4,
                              style: inputs.textStyle,
                              onChanged: (_) {
                                if (_deathNoteError != null) {
                                  setState(() => _deathNoteError = null);
                                }
                              },
                              decoration: _fieldDecoration(
                                labelText: l10n.plantDisposeDeathNote,
                                errorText: _deathNoteError,
                                icon: Icons.notes_outlined,
                              ),
                            )
                          else ...[
                            TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              style: inputs.textStyle,
                              onChanged: (_) {
                                if (_amountError != null) {
                                  setState(() => _amountError = null);
                                }
                              },
                              decoration: _fieldDecoration(
                                labelText: l10n.financesAmountLabel(
                                  currency.symbol,
                                ),
                                errorText: _amountError,
                                icon: Icons.payments_outlined,
                              ),
                            ),
                            spacing.vMd,
                            TextField(
                              controller: _saleNoteController,
                              maxLines: 3,
                              style: inputs.textStyle,
                              decoration: _fieldDecoration(
                                labelText: l10n.notesOptional,
                                icon: Icons.notes_outlined,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sheets.contentPadding.left,
                      spacing.xs,
                      sheets.contentPadding.right,
                      spacing.md,
                    ),
                    child: SizedBox(
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
                            : Text(
                                l10n.plantDisposeConfirm,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
