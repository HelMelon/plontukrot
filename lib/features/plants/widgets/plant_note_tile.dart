import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/note_service.dart';
import 'update_note_sheet.dart';

class PlantNoteTile extends StatefulWidget {
  final String plantId;
  final String noteId;
  final Map<String, dynamic> data;
  final bool isOpened; // Получаем состояние сверху
  final ValueChanged<bool> onOpenChanged; // Уведомляем верхний виджет

  const PlantNoteTile({
    super.key,
    required this.plantId,
    required this.noteId,
    required this.data,
    required this.isOpened,
    required this.onOpenChanged,
  });

  @override
  State<PlantNoteTile> createState() => _PlantNoteTileState();
}

class _PlantNoteTileState extends State<PlantNoteTile> {
  bool get isDesktop => kIsWeb;

  Future<void> _deleteNote(BuildContext context) async {
    // 1. Показываем диалог подтверждения
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dark2, // Используем ваш цвет фона
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20,
            ), // Скругляем углы под стиль карточек
          ),
          title: const Text(
            'Delete note?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this note? This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            // Кнопка отмены
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // Возвращает false
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            // Кнопка подтверждения удаления
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(true), // Возвращает true
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    // 2. Если пользователь нажал "Delete" (confirmed == true), удаляем из базы
    if (confirmed == true && context.mounted) {
      await NoteService().deleteNote(
        plantId: widget.plantId,
        noteId: widget.noteId,
      );
    }
  }

  void _editNote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateNoteSheet(
        plantId: widget.plantId,
        noteId: widget.noteId,
        initialText: widget.data['text'] ?? '',
      ),
    );
  }

  String _formatDate() {
    final ts = widget.data['createdAt'];
    if (ts == null) return '';
    final date = (ts as Timestamp).toDate();
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Используем widget.isOpened вместо локальной переменной
    final bool showActions = widget.isOpened;

    final noteBody = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dark2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.data['text'] ?? '',
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: noteBody),
          const SizedBox(width: 10),
          Column(
            children: [
              IconButton(
                onPressed: () => _editNote(context),
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.goldAccent,
                ),
              ),
              IconButton(
                onPressed: () => _deleteNote(context),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Свайп влево — просим родителя открыть именно ЭТУ заметку
        if (details.primaryVelocity! < 0) {
          widget.onOpenChanged(true);
        }
        // Свайп вправо — просим закрыть
        if (details.primaryVelocity! > 0) {
          widget.onOpenChanged(false);
        }
      },
      onTap: () {
        if (showActions) {
          widget.onOpenChanged(false);
        }
      },
      child: Row(
        children: [
          Expanded(child: noteBody),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: showActions ? 120 : 0,
            child: AnimatedOpacity(
              opacity: showActions ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: showActions
                            ? () => _editNote(context)
                            : null,
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.amber.withOpacity(0.15),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: showActions
                            ? () => _deleteNote(context)
                            : null,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.15),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
