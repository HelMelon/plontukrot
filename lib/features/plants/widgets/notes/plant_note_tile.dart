import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/note.dart';
import '../../../../services/note_service.dart';
import '../sheets/update_note_sheet.dart';

class PlantNoteTile extends StatelessWidget {
  final String plantId;
  final Note note;

  const PlantNoteTile({
    super.key,
    required this.plantId,
    required this.note,
  });

  Future<void> _deleteNote(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dark2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.notesDeleteTitle,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            l10n.notesDeleteConfirm,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.commonCancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l10n.commonDelete,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await NoteService().deleteNote(
        plantId: plantId,
        noteId: note.id,
      );
    }
  }

  void _editNote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateNoteSheet(
        plantId: plantId,
        noteId: note.id,
        initialText: note.text,
      ),
    );
  }

  String _formatDate() {
    final date = note.createdAt;
    if (date == null) return '';
    return DateFormat.yMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = _formatDate();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.dark2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  date.isEmpty ? '—' : date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                height: 20,
                width: 28,
                child: IconButton(
                  tooltip: l10n.commonEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editNote(context),
                ),
              ),
              SizedBox(
                height: 20,
                width: 28,
                child: IconButton(
                  tooltip: l10n.commonDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteNote(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
