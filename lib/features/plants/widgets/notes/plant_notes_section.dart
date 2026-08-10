import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/note.dart';
import '../../../../services/note_service.dart';
import '../common/expandable_side_scroll_list.dart';
import 'plant_note_tile.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

class PlantNotesSection extends StatefulWidget {
  final NoteParent parent;

  const PlantNotesSection({super.key, required this.parent});

  @override
  State<PlantNotesSection> createState() => _PlantNotesSectionState();
}

class _PlantNotesSectionState extends State<PlantNotesSection> {
  static const int _streamLimit = 50;

  late Stream<List<Note>> _notesStream;

  @override
  void initState() {
    super.initState();
    _notesStream =
        NoteService().notesStream(widget.parent, limit: _streamLimit);
  }

  @override
  void didUpdateWidget(covariant PlantNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parent.kind != widget.parent.kind ||
        oldWidget.parent.id != widget.parent.id) {
      _notesStream =
          NoteService().notesStream(widget.parent, limit: _streamLimit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;

    return StreamBuilder<List<Note>>(
      stream: _notesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              l10n.commonError(snapshot.error.toString()),
              style: typography.error,
            ),
          );
        }

        if (!snapshot.hasData) {
          return SizedBox(
            height: 100,
            child: Center(
              child: AccessibleProgressIndicator(color: colors.primary),
            ),
          );
        }

        final notes = snapshot.data!;

        if (notes.isEmpty) {
          return Container(
            width: double.infinity,
            padding: context.spacing.allLg,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(context.radii.lg),
            ),
            child: Text(
              l10n.notesEmpty,
              style: typography.bodySmall,
            ),
          );
        }

        return ExpandableSideScrollList(
          itemCount: notes.length,
          collapsedVisible: 3,
          expandedViewport: 5,
          itemExtent: 120,
          itemBuilder: (context, index) {
            return PlantNoteTile(
              parent: widget.parent,
              note: notes[index],
            );
          },
        );
      },
    );
  }
}
