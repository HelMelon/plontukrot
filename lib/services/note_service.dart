import '../models/note.dart';
import '../models/model_helpers.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'rest_stream.dart';

enum NoteParentKind { plant, propagation }

/// Owner of a journal notes collection (plant or propagation batch).
class NoteParent {
  final NoteParentKind kind;
  final String id;

  const NoteParent.plant(this.id) : kind = NoteParentKind.plant;

  const NoteParent.propagation(this.id) : kind = NoteParentKind.propagation;
}

class NoteService {
  static const retention = Duration(days: 183);

  final ApiClient _api = ApiClient.instance;

  String _base(NoteParent parent) {
    return parent.kind == NoteParentKind.plant
        ? '/plants/${parent.id}/notes'
        : '/propagations/${parent.id}/notes';
  }

  Future<void> addNote({
    required NoteParent parent,
    required String text,
    DateTime? createdAt,
  }) async {
    final at = createdAt ?? DateTime.now();
    await _api.post(_base(parent), body: {
      'text': text,
      'expires_at': isoDate(at.add(retention)),
    });
  }

  Future<void> addNotes({
    required Iterable<NoteParent> parents,
    required String text,
    DateTime? createdAt,
  }) async {
    for (final parent in parents) {
      await addNote(parent: parent, text: text, createdAt: createdAt);
    }
  }

  Future<void> updateNote({
    required NoteParent parent,
    required String noteId,
    required String text,
    DateTime? createdAt,
  }) async {
    try {
      await _api.patch('${_base(parent)}/$noteId', body: {
        'text': text,
        if (createdAt != null) ...{
          'expires_at': isoDate(createdAt.add(retention)),
        },
      });
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> deleteNote({
    required NoteParent parent,
    required String noteId,
  }) async {
    try {
      await _api.delete('${_base(parent)}/$noteId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Stream<List<Note>> notesStream(NoteParent parent, {int limit = 20}) {
    return restPollStream(() async {
      final list = jsonMapList(await _api.get(_base(parent)));
      final notes = list
          .map((m) => Note.fromMap(readString(m, 'id') ?? '', m))
          .toList()
        ..sort((a, b) {
          final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bAt.compareTo(aAt);
        });
      if (notes.length <= limit) return notes;
      return notes.take(limit).toList();
    });
  }
}
