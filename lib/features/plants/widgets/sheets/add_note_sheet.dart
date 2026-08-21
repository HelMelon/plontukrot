import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/accessible_progress_indicator.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';
import '../../../../services/note_service.dart';

class AddNoteSheet extends StatefulWidget {
  final List<NoteParent> parents;
  final String? title;

  const AddNoteSheet({
    super.key,
    required this.parents,
    this.title,
  });

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final noteController = TextEditingController();

  bool isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String? _textError;

  bool get _isBulk => widget.parents.length > 1;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
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

  Future<void> saveNote() async {
    final l10n = AppLocalizations.of(context);
    final text = noteController.text.trim();

    if (text.isEmpty) {
      setState(() => _textError = l10n.notesCannotBeEmpty);
      return;
    }

    setState(() {
      isLoading = true;
      _textError = null;
    });

    try {
      final service = NoteService();
      if (_isBulk) {
        await service.addNotes(
          parents: widget.parents,
          text: text,
          createdAt: _selectedDate,
        );
      } else {
        await service.addNote(
          parent: widget.parents.first,
          text: text,
          createdAt: _selectedDate,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
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
    noteController.dispose();
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
    final keyboard = media.viewInsets.bottom;
    final availableHeight =
        media.size.height - media.padding.top - keyboard;
    final sheetHeight = availableHeight * 0.92;
    final dateLabel = DateFormat('d MMM y').format(_selectedDate);
    final title = widget.title ?? l10n.notesAdd;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: sheetHeight,
        child: Container(
          decoration: BoxDecoration(
            color: colors.modal,
            borderRadius: sheets.topBorderRadius,
          ),
          child: Padding(
            padding: sheets.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: SheetDragHandle()),
                spacing.vXxl,
                Text(
                  title,
                  style: typography.titleLarge.copyWith(
                    letterSpacing: -1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                spacing.vXs,
                Text(
                  _isBulk ? l10n.notesAddHintBulk : l10n.notesAddHint,
                  style: typography.bodyLarge.copyWith(
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
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
                Expanded(
                  child: TextField(
                    controller: noteController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    autofocus: true,
                    style: inputs.textStyle,
                    onChanged: (_) {
                      if (_textError != null) {
                        setState(() => _textError = null);
                      }
                    },
                    decoration: inputs
                        .decoration(
                          labelText: l10n.notesLabel,
                        )
                        .copyWith(
                          alignLabelWithHint: true,
                          errorText: _textError,
                        ),
                  ),
                ),
                spacing.vXl,
                SizedBox(
                  width: double.infinity,
                  height: dimensions.buttonHeight,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : saveNote,
                    child: isLoading
                        ? SizedBox(
                            width: dimensions.iconXl,
                            height: dimensions.iconXl,
                            child: AccessibleProgressIndicator(
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
    );
  }
}
