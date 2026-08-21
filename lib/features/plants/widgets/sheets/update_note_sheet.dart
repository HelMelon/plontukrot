import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';
import '../../../../services/note_service.dart';

class UpdateNoteSheet extends StatefulWidget {
  final NoteParent parent;
  final String noteId;
  final String initialText;
  final DateTime? initialCreatedAt;

  const UpdateNoteSheet({
    super.key,
    required this.parent,
    required this.noteId,
    required this.initialText,
    this.initialCreatedAt,
  });

  @override
  State<UpdateNoteSheet> createState() => _UpdateNoteSheetState();
}

class _UpdateNoteSheetState extends State<UpdateNoteSheet> {
  late final TextEditingController controller;
  late DateTime _selectedDate;

  bool isLoading = false;
  String? _textError;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
    _selectedDate = widget.initialCreatedAt ?? DateTime.now();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial =
        _selectedDate.isAfter(now) ? now : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> save() async {
    final l10n = AppLocalizations.of(context);
    final text = controller.text.trim();

    if (text.isEmpty) {
      setState(() => _textError = l10n.notesCannotBeEmpty);
      return;
    }

    setState(() {
      isLoading = true;
      _textError = null;
    });

    try {
      await NoteService().updateNote(
        parent: widget.parent,
        noteId: widget.noteId,
        text: text,
        createdAt: _selectedDate,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError(e.toString()))),
        );
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final inputs = context.components.inputs;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height -
        media.viewInsets.bottom -
        media.padding.top -
        media.padding.bottom;
    final dateLabel = DateFormat('d MMM y').format(_selectedDate);

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: colors.modal,
        borderRadius: sheets.topBorderRadius,
      ),
      child: Padding(
        padding: sheets.contentPadding.copyWith(
          bottom: media.viewInsets.bottom + sheets.contentPadding.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SheetDragHandle()),
              spacing.vLg,
              Text(
                l10n.notesEdit,
                style: typography.titleLarge.copyWith(letterSpacing: -1),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              spacing.vLg,
              Semantics(
                button: true,
                label: l10n.a11ySelectDate(dateLabel),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ExcludeSemantics(
                    child: Icon(context.icons.calendar),
                  ),
                  title: Text(dateLabel),
                  onTap: _pickDate,
                ),
              ),
              spacing.vMd,
              TextField(
                controller: controller,
                maxLines: 4,
                style: inputs.textStyle,
                onChanged: (_) {
                  if (_textError != null) {
                    setState(() => _textError = null);
                  }
                },
                decoration: inputs.decoration(
                  labelText: l10n.notesEditLabel,
                ).copyWith(errorText: _textError),
              ),
              spacing.vLg,
              SizedBox(
                width: double.infinity,
                height: dimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: isLoading ? null : save,
                  child: Text(
                    l10n.plantSaveChanges,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
