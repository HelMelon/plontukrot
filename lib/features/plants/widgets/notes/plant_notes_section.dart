import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/note.dart';
import '../../../../services/note_service.dart';
import '../common/expandable_side_scroll_list.dart';
import 'plant_note_tile.dart';

class PlantNotesSection extends StatefulWidget {
  final String plantId;

  const PlantNotesSection({super.key, required this.plantId});

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
        NoteService().notesStream(widget.plantId, limit: _streamLimit);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<List<Note>>(
      stream: _notesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              l10n.commonError(snapshot.error.toString()),
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            ),
          );
        }

        final notes = snapshot.data!;

        if (notes.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dark2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.notesEmpty,
              style: const TextStyle(color: AppColors.textSecondary),
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
              plantId: widget.plantId,
              note: notes[index],
            );
          },
        );
      },
    );
  }
}
