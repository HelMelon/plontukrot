import 'model_helpers.dart';

class Note {
  final String id;
  final String text;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? updatedAt;

  const Note({
    required this.id,
    required this.text,
    this.createdAt,
    this.expiresAt,
    this.updatedAt,
  });

  factory Note.fromMap(String id, Map<String, dynamic> data) {
    return Note(
      id: id,
      text: readString(data, 'text') ?? '',
      createdAt: readDate(data, 'createdAt'),
      expiresAt: readDate(data, 'expiresAt'),
      updatedAt: readDate(data, 'updatedAt'),
    );
  }
}
