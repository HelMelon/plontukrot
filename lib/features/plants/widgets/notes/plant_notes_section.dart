import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/note.dart';
import '../../../../services/note_service.dart';
import 'plant_note_tile.dart';

class PlantNotesSection extends StatefulWidget {
  final String plantId;

  const PlantNotesSection({super.key, required this.plantId});

  @override
  State<PlantNotesSection> createState() => _PlantNotesSectionState();
}

class _PlantNotesSectionState extends State<PlantNotesSection> {
  static const int _pageSize = 20;

  bool showAll = false;
  int _limit = _pageSize;
  late Stream<List<Note>> _notesStream;

  String? _openedNoteId;

  @override
  void initState() {
    super.initState();
    _notesStream = NoteService().notesStream(widget.plantId, limit: _limit);
  }

  void _handleNoteOpen(String? noteId) {
    setState(() {
      _openedNoteId = noteId;
    });
  }

  void _loadMore() {
    setState(() {
      _limit += _pageSize;
      showAll = true;
      _notesStream = NoteService().notesStream(widget.plantId, limit: _limit);
    });
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

        final visibleNotes = showAll ? notes : notes.take(3).toList();
        final canLoadMore = notes.length >= _limit;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...visibleNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PlantNoteTile(
                  plantId: widget.plantId,
                  note: note,
                  isOpened: _openedNoteId == note.id,
                  onOpenChanged: (isOpen) {
                    _handleNoteOpen(isOpen ? note.id : null);
                  },
                ),
              ),
            ),
            if (!showAll && notes.length > 3)
              TextButton(
                onPressed: () {
                  setState(() {
                    showAll = true;
                  });
                },
                child: Text(
                  l10n.commonShowMore,
                  style: const TextStyle(
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (showAll && canLoadMore)
              TextButton(
                onPressed: _loadMore,
                child: Text(
                  l10n.commonLoadMore,
                  style: const TextStyle(
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (showAll && notes.length > 3)
              TextButton(
                onPressed: () {
                  setState(() {
                    showAll = false;
                  });
                },
                child: Text(
                  l10n.commonCollapse,
                  style: const TextStyle(
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
