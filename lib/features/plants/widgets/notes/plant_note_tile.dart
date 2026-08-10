import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/note.dart';
import '../../../../services/note_service.dart';
import '../sheets/update_note_sheet.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

class PlantNoteTile extends StatelessWidget {
  final NoteParent parent;
  final Note note;

  const PlantNoteTile({
    super.key,
    required this.parent,
    required this.note,
  });

  Future<void> _deleteNote(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final dialogs = context.components.dialogs;
    final colors = context.colors;
    final typography = context.typography;
    final bool? confirmed = await showAppDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogs.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dialogs.radius),
          ),
          title: Text(
            l10n.notesDeleteTitle,
            style: dialogs.titleStyle.copyWith(color: colors.textPrimary),
          ),
          content: Text(
            l10n.notesDeleteConfirm,
            style: dialogs.bodyStyle.copyWith(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.commonCancel,
                style: typography.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l10n.commonDelete,
                style: typography.error,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await NoteService().deleteNote(
        parent: parent,
        noteId: note.id,
      );
    }
  }

  void _editNote(BuildContext context) {
    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateNoteSheet(
        parent: parent,
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
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final date = _formatDate();

    return Container(
      width: double.infinity,
      padding: spacing.allMd,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.radii.md),
        color: colors.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  date.isEmpty ? '—' : date,
                  style: typography.caption.copyWith(
                    height: 1.2,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                height: spacing.lg,
                width: spacing.xxl,
                child: IconButton(
                  tooltip: l10n.commonEdit,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: spacing.xxl,
                    height: spacing.lg,
                  ),
                  visualDensity: VisualDensity.compact,
                  iconSize: dimensions.iconSm,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editNote(context),
                ),
              ),
              SizedBox(
                height: spacing.lg,
                width: spacing.xxl,
                child: IconButton(
                  tooltip: l10n.commonDelete,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: spacing.xxl,
                    height: spacing.lg,
                  ),
                  visualDensity: VisualDensity.compact,
                  iconSize: dimensions.iconSm,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteNote(context),
                ),
              ),
            ],
          ),
          spacing.vXs,
          Text(
            note.text,
            style: typography.bodyEmphasis.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
