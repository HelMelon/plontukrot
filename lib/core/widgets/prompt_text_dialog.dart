import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../theme/theme_context.dart';

/// Shows a text prompt dialog without disposing the controller while the
/// TextField is still attached (which crashes on dismiss with empty focus).
Future<String?> showPromptTextDialog({
  required BuildContext context,
  required String title,
  String initial = '',
  String? hintText,
  String? labelText,
  String? confirmLabel,
  String? cancelLabel,
  bool allowEmpty = false,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  TextCapitalization textCapitalization = TextCapitalization.sentences,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PromptTextDialog(
      title: title,
      initial: initial,
      hintText: hintText,
      labelText: labelText,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      allowEmpty: allowEmpty,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
    ),
  );
}

class _PromptTextDialog extends StatefulWidget {
  final String title;
  final String initial;
  final String? hintText;
  final String? labelText;
  final String? confirmLabel;
  final String? cancelLabel;
  final bool allowEmpty;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const _PromptTextDialog({
    required this.title,
    required this.initial,
    required this.hintText,
    required this.labelText,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.allowEmpty,
    required this.keyboardType,
    required this.inputFormatters,
    required this.textCapitalization,
  });

  @override
  State<_PromptTextDialog> createState() => _PromptTextDialogState();
}

class _PromptTextDialogState extends State<_PromptTextDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (!widget.allowEmpty && value.isEmpty) {
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
    final maxContentHeight =
        (media.size.height - media.viewInsets.bottom) * 0.4;
    final dialogs = context.components.dialogs;
    final spacing = context.spacing;

    return AlertDialog(
      backgroundColor: dialogs.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogs.radius),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: spacing.xl,
        vertical: spacing.xl,
      ),
      title: Text(
        widget.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: dialogs.titleStyle,
      ),
      content: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: maxContentHeight.clamp(120.0, 320.0)),
        child: SingleChildScrollView(
          child: TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: widget.hintText,
              labelText: widget.labelText,
              errorText: _errorText,
            ),
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
