import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../services/note_service.dart';

class UpdateNoteSheet extends StatefulWidget {
  final NoteParent parent;
  final String noteId;
  final String initialText;

  const UpdateNoteSheet({
    super.key,
    required this.parent,
    required this.noteId,
    required this.initialText,
  });

  @override
  State<UpdateNoteSheet> createState() => _UpdateNoteSheetState();
}

class _UpdateNoteSheetState extends State<UpdateNoteSheet> {
  late final TextEditingController controller;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
  }

  Future<void> save() async {
    final l10n = AppLocalizations.of(context);
    final text = controller.text.trim();

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
      await NoteService().updateNote(
        parent: widget.parent,
        noteId: widget.noteId,
        text: text,
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
    final dimensions = context.dimensions;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height -
        media.viewInsets.bottom -
        media.padding.top -
        media.padding.bottom;

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
            children: [
              TextField(
                controller: controller,
                maxLines: 4,
                style: inputs.textStyle,
                decoration: inputs.decoration(
                  labelText: l10n.notesEditLabel,
                ),
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
