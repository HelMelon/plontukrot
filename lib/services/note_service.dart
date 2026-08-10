import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/note.dart';

enum NoteParentKind { plant, propagation }

/// Owner of a journal notes subcollection (plant or propagation batch).
class NoteParent {
  final NoteParentKind kind;
  final String id;

  const NoteParent.plant(this.id) : kind = NoteParentKind.plant;

  const NoteParent.propagation(this.id) : kind = NoteParentKind.propagation;
}

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _notesRef(NoteParent parent) {
    final root = parent.kind == NoteParentKind.plant ? 'plants' : 'propagations';
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection(root)
        .doc(parent.id)
        .collection('notes');
  }

  Future<void> addNote({
    required NoteParent parent,
    required String text,
  }) async {
    final now = DateTime.now();

    await _notesRef(parent).add({
      'text': text,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 183))),
    });
  }

  Future<void> updateNote({
    required NoteParent parent,
    required String noteId,
    required String text,
  }) async {
    await _notesRef(parent).doc(noteId).update({
      'text': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote({
    required NoteParent parent,
    required String noteId,
  }) async {
    await _notesRef(parent).doc(noteId).delete();
  }

  Stream<List<Note>> notesStream(NoteParent parent, {int limit = 20}) {
    return _notesRef(parent)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Note.fromFirestore).toList(),
        );
  }
}
