import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

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
      text: data['text'] as String? ?? '',
      createdAt: readTimestamp(data['createdAt']),
      expiresAt: readTimestamp(data['expiresAt']),
      updatedAt: readTimestamp(data['updatedAt']),
    );
  }

  factory Note.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Note.fromMap(doc.id, doc.data());
  }
}
