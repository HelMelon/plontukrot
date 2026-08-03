import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/propagation.dart';
import '../../../../models/stage_info.dart';
import '../../../../services/propagation_service.dart';

class ChangePropagationStageSheet extends StatefulWidget {
  final Propagation propagation;

  const ChangePropagationStageSheet({
    super.key,
    required this.propagation,
  });

  @override
  State<ChangePropagationStageSheet> createState() =>
      _ChangePropagationStageSheetState();
}

class _ChangePropagationStageSheetState
    extends State<ChangePropagationStageSheet> {
  final _service = PropagationService();
  final _noteController = TextEditingController();
  late final TextEditingController _quantityController;

  late int _stage;
  DateTime _changedAt = DateTime.now();
  bool _saving = false;

  static final _stages = stageInfos.where((stage) => stage.value >= 1).toList();

  @override
  void initState() {
    super.initState();
    _stage = widget.propagation.stage.clamp(1, 4);
    _quantityController = TextEditingController(
      text: '${widget.propagation.quantityAlive}',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _changedAt,
      firstDate: widget.propagation.startedAt,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _changedAt = picked);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final quantityAlive = int.tryParse(_quantityController.text.trim());
    if (quantityAlive == null || quantityAlive < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.propagationAliveRequired)),
      );
      return;
    }
    if (quantityAlive > widget.propagation.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.propagationQuantityExceedsOriginal(
              widget.propagation.quantity,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.changeStage(
        propagationId: widget.propagation.id,
        stage: _stage,
        changedAt: _changedAt,
        quantityAlive: quantityAlive,
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
                    l10n.propagationChangeStage,
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
                    '${l10n.propagationAliveWithMethod(widget.propagation.quantityAlive, l10n.propagationMethodPlural(widget.propagation.method))} · ${widget.propagation.parentPlantName}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._stages.map((stage) {
                    final selected = _stage == stage.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        l10n.stageInfoTitle(stage),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onTap: () => setState(() => _stage = stage.value),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.propagationAliveNow,
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
                                DateFormat('d MMM y').format(_changedAt),
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
                              l10n.commonSave,
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
