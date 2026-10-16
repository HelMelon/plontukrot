import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/widgets/app_modal.dart';
import '../../../../core/theme/theme_context.dart';

Future<String?> showBotanicalPrefillDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showAppDialog<String>(
    context: context,
    builder: (context) => _BotanicalPrefillDialog(
      title: l10n.botanicalPrefillTitle,
      labelText: l10n.botanicalPrefillLabel,
      hintText: l10n.botanicalPrefillHint,
      confirmLabel: l10n.botanicalPrefillButton,
      cancelLabel: l10n.commonCancel,
    ),
  );
}

class _BotanicalPrefillDialog extends StatefulWidget {
  final String title;
  final String? labelText;
  final String? hintText;
  final String? confirmLabel;
  final String? cancelLabel;

  const _BotanicalPrefillDialog({
    required this.title,
    required this.labelText,
    required this.hintText,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  State<_BotanicalPrefillDialog> createState() =>
      _BotanicalPrefillDialogState();
}

class _BotanicalPrefillDialogState extends State<_BotanicalPrefillDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(
        () => _errorText = AppLocalizations.of(context).promptEmptyNotAllowed,
      );
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final dialogs = context.components.dialogs;
    final spacing = context.spacing;
    final keyboardOpen = media.viewInsets.bottom > 0;
    final labelTopGap = widget.labelText == null ? 0.0 : spacing.sm;

    return AlertDialog(
      backgroundColor: dialogs.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogs.radius),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: spacing.xl,
        vertical: keyboardOpen ? spacing.sm : spacing.xl,
      ),
      scrollable: true,
      title: Text(
        widget.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: dialogs.titleStyle,
      ),
      content: Padding(
        padding: EdgeInsets.only(top: labelTopGap),
        child: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_errorText != null) setState(() => _errorText = null);
          },
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: widget.hintText,
            labelText: widget.labelText,
            errorText: _errorText,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: spacing.xs,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel ?? l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel ?? l10n.commonSave),
        ),
      ],
    );
  }
}
