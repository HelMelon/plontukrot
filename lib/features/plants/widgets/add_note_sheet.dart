import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/note_service.dart';

class AddNoteSheet extends StatefulWidget {
  final String plantId;

  const AddNoteSheet({super.key, required this.plantId});

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final noteController = TextEditingController();

  bool isLoading = false;

  Future<void> saveNote() async {
    final text = noteController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    await NoteService().addNote(plantId: widget.plantId, text: text);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Add Note',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: AppColors.heading,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Add a new journal entry for this plant.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: noteController,
                maxLines: 8,
                autofocus: true,

                style: const TextStyle(color: AppColors.textPrimary),

                decoration: InputDecoration(
                  labelText: 'Journal entry',
                  alignLabelWithHint: true,

                  labelStyle: const TextStyle(color: AppColors.textSecondary),

                  filled: true,
                  fillColor: AppColors.dark2,

                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 120),
                    child: Icon(
                      Icons.notes_rounded,
                      color: AppColors.accentLight,
                    ),
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.greenDeep),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: AppColors.goldAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(
                  onPressed: isLoading ? null : saveNote,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: AppColors.dark1,
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.dark1,
                          ),
                        )
                      : const Text(
                          'Save Note',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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
