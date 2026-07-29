import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Shows a text prompt dialog without disposing the controller while the
/// TextField is still attached (which crashes on dismiss with empty focus).
Future<String?> showPromptTextDialog({
  required BuildContext context,
  required String title,
  String initial = '',
  String? hintText,
  String? labelText,
  String confirmLabel = 'Сохранить',
  String cancelLabel = 'Отмена',
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
  final String confirmLabel;
  final String cancelLabel;
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
      setState(() => _errorText = 'Поле не может быть пустым');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxContentHeight =
        (media.size.height - media.viewInsets.bottom) * 0.4;

    return AlertDialog(
      backgroundColor: AppColors.backgroundSecondary,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(
        widget.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
