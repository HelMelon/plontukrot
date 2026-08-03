import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/note_service.dart';

class UpdateNoteSheet extends StatefulWidget {
  final String plantId;
  final String noteId;
  final String initialText;

  const UpdateNoteSheet({
    super.key,
    required this.plantId,
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
        plantId: widget.plantId,
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 8,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.notesEditLabel,
                  filled: true,
                  fillColor: AppColors.dark2,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: AppTheme.buttonHeight,
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
