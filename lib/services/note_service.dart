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
  static const retention = Duration(days: 183);

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

  Map<String, dynamic> _notePayload({
    required String text,
    required DateTime createdAt,
  }) {
    return {
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(createdAt.add(retention)),
    };
  }

  Future<void> addNote({
    required NoteParent parent,
    required String text,
    DateTime? createdAt,
  }) async {
    final at = createdAt ?? DateTime.now();
    await _notesRef(parent).add(_notePayload(text: text, createdAt: at));
  }

  /// Same journal text/date on each parent (home multi-select).
  Future<void> addNotes({
    required Iterable<NoteParent> parents,
    required String text,
    DateTime? createdAt,
  }) async {
    final at = createdAt ?? DateTime.now();
    final list = parents.toList();
    const chunkSize = 200;
    for (var i = 0; i < list.length; i += chunkSize) {
      final chunk = list.skip(i).take(chunkSize);
      final batch = _firestore.batch();
      for (final parent in chunk) {
        batch.set(
          _notesRef(parent).doc(),
          _notePayload(text: text, createdAt: at),
        );
      }
      await batch.commit();
    }
  }

  Future<void> updateNote({
    required NoteParent parent,
    required String noteId,
    required String text,
    DateTime? createdAt,
  }) async {
    final updates = <String, dynamic>{
      'text': text,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (createdAt != null) {
      updates['createdAt'] = Timestamp.fromDate(createdAt);
      updates['expiresAt'] = Timestamp.fromDate(createdAt.add(retention));
    }
    await _notesRef(parent).doc(noteId).update(updates);
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
