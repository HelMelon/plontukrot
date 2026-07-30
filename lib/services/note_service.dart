import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/note.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _notesRef(String plantId) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('plants')
        .doc(plantId)
        .collection('notes');
  }

  Future<void> addNote({required String plantId, required String text}) async {
    final now = DateTime.now();

    await _notesRef(plantId).add({
      'text': text,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 183))),
    });
  }

  Future<void> updateNote({
    required String plantId,
    required String noteId,
    required String text,
  }) async {
    await _notesRef(plantId).doc(noteId).update({
      'text': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote({
    required String plantId,
    required String noteId,
  }) async {
    await _notesRef(plantId).doc(noteId).delete();
  }

  Stream<List<Note>> notesStream(String plantId, {int limit = 20}) {
    return _notesRef(plantId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Note.fromFirestore).toList(),
        );
  }
}
