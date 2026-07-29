import 'package:flutter/material.dart';

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
  bool showAll = false;

  late final Stream<List<Note>> _notesStream;

  String? _openedNoteId;

  @override
  void initState() {
    super.initState();
    _notesStream = NoteService().notesStream(widget.plantId);
  }

  void _handleNoteOpen(String? noteId) {
    setState(() {
      _openedNoteId = noteId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: _notesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Ошибка: ${snapshot.error}',
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
            child: const Text(
              'Заметок пока нет',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final visibleNotes = showAll ? notes : notes.take(3).toList();

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
            if (notes.length > 3)
              TextButton(
                onPressed: () {
                  setState(() {
                    showAll = !showAll;
                  });
                },
                child: Text(
                  showAll ? 'Свернуть' : 'Показать ещё',
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
