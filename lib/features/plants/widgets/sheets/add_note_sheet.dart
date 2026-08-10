import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../services/note_service.dart';

class AddNoteSheet extends StatefulWidget {
  final NoteParent parent;

  const AddNoteSheet({super.key, required this.parent});

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final noteController = TextEditingController();

  bool isLoading = false;

  Future<void> saveNote() async {
    final l10n = AppLocalizations.of(context);
    final text = noteController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notesCannotBeEmpty)),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await NoteService().addNote(parent: widget.parent, text: text);

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
    // Tall sheet so the top edge sits high on the screen (above keyboard).
    final sheetHeight = availableHeight * 0.92;

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
                  l10n.notesAdd,
                  style: typography.titleLarge.copyWith(
                    letterSpacing: -1,
                  ),
                ),
                spacing.vXs,
                Text(
                  l10n.notesAddHint,
                  style: typography.bodyLarge.copyWith(
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                spacing.vXxl,
                Expanded(
                  child: TextField(
                    controller: noteController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    autofocus: true,
                    style: inputs.textStyle,
                    decoration: inputs.decoration(
                      labelText: l10n.notesLabel,
                    ).copyWith(alignLabelWithHint: true),
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
    );
  }
}
