import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/note_service.dart';
import 'plant_note_tile.dart';

class PlantNotesSection extends StatefulWidget {
  final String plantId;

  const PlantNotesSection({super.key, required this.plantId});

  @override
  State<PlantNotesSection> createState() => _PlantNotesSectionState();
}

class _PlantNotesSectionState extends State<PlantNotesSection> {
  bool showAll = false;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _notesStream;

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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notesStream,

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
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

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dark2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'No notes yet',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final visibleNotes = showAll ? docs : docs.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...visibleNotes.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PlantNoteTile(
                  plantId: widget.plantId,
                  noteId: doc.id,
                  data: doc.data(),

                  isOpened: _openedNoteId == doc.id,

                  onOpenChanged: (isOpen) {
                    _handleNoteOpen(isOpen ? doc.id : null);
                  },
                ),
              ),
            ),

            if (docs.length > 3)
              TextButton(
                onPressed: () {
                  setState(() {
                    showAll = !showAll;
                  });
                },
                child: Text(
                  showAll ? 'Show less' : 'Show more',
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
