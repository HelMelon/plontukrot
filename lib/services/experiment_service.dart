import 'dart:async';

import '../models/experiment.dart';
import '../models/experiment_subject.dart';
import '../models/model_helpers.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'rest_stream.dart';

/// REST access to the experiments feature: trials, variants, subjects and the
/// per-subject observation log. The backend owns the nested tree, so every
/// write returns fresh state and reads are full-tree polls via [restPollStream].
class ExperimentService {
  final ApiClient _api = ApiClient.instance;

  List<Experiment> _parseList(dynamic json) {
    return jsonMapList(json)
        .map((m) => Experiment.fromMap(readString(m, 'id') ?? '', m))
        .toList();
  }

  Future<List<Experiment>> _fetchAll() async {
    return _parseList(await _api.get('/experiments'));
  }

  Future<Experiment?> fetch(String experimentId) async {
    for (final experiment in await _fetchAll()) {
      if (experiment.id == experimentId) return experiment;
    }
    return null;
  }

  Stream<List<Experiment>> watchExperiments() {
    return restPollStream(() async {
      final items = await _fetchAll();
      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  Stream<Experiment?> watchExperiment(String experimentId) {
    return restPollStream(() async {
      for (final experiment in await _fetchAll()) {
        if (experiment.id == experimentId) return experiment;
      }
      return null;
    });
  }

  Future<String> createExperiment({
    required String title,
    String? hypothesis,
    String? note,
    DateTime? startedAt,
    List<Map<String, dynamic>> variants = const [],
  }) async {
    final created = jsonMap(await _api.post('/experiments', body: {
      'title': title,
      if (hypothesis != null) 'hypothesis': hypothesis,
      if (note != null) 'note': note,
      if (startedAt != null) 'started_at': isoDate(startedAt),
      'variants': variants,
    }));
    return readString(created, 'id') ?? '';
  }

  Future<void> updateExperiment({
    required String experimentId,
    String? title,
    String? hypothesis,
    String? note,
    DateTime? startedAt,
    String? conclusion,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) async {
    await _api.patch('/experiments/$experimentId', body: {
      if (title != null) 'title': title,
      if (hypothesis != null) 'hypothesis': hypothesis,
      if (note != null) 'note': note,
      if (startedAt != null) 'started_at': isoDate(startedAt),
      if (conclusion != null) 'conclusion': conclusion,
      if (clearCompletedAt) 'completed_at': null,
      if (completedAt != null) 'completed_at': isoDate(completedAt),
    });
  }

  Future<void> deleteExperiment(String experimentId) async {
    try {
      await _api.delete('/experiments/$experimentId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<String> addVariant({
    required String experimentId,
    required String label,
    String? description,
  }) async {
    final created = jsonMap(await _api.post(
      '/experiments/$experimentId/variants',
      body: {
        'label': label,
        if (description != null) 'description': description,
      },
    ));
    return readString(created, 'id') ?? '';
  }

  Future<void> updateVariant({
    required String variantId,
    String? label,
    String? description,
    int? position,
  }) async {
    await _api.patch('/variants/$variantId', body: {
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (position != null) 'position': position,
    });
  }

  Future<void> deleteVariant(String variantId) async {
    try {
      await _api.delete('/variants/$variantId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> addSubject({
    required String variantId,
    required ExperimentSubjectType subjectType,
    required String subjectId,
    String? subjectName,
  }) async {
    await _api.post('/variants/$variantId/subjects', body: {
      'subject_type': subjectType.code,
      'subject_id': subjectId,
      if (subjectName != null) 'subject_name': subjectName,
    });
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await _api.delete('/subjects/$subjectId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> addObservation({
    required String subjectId,
    required DateTime observedAt,
    String? note,
    String? imageUrl,
    double? heightCm,
    int? leafCount,
    double? moisture,
  }) async {
    await _api.post('/subjects/$subjectId/observations', body: {
      'observed_at': isoDate(observedAt),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (imageUrl != null && imageUrl.trim().isNotEmpty)
        'image_url': imageUrl.trim(),
      if (heightCm != null) 'height_cm': heightCm,
      if (leafCount != null) 'leaf_count': leafCount,
      if (moisture != null) 'moisture': moisture,
    });
  }

  Future<void> deleteObservation(String observationId) async {
    try {
      await _api.delete('/observations/$observationId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  /// Upload an observation photo and return its public URL. Only the file is
  /// stored here; the caller then logs the observation with this URL.
  Future<String> uploadObservationPhoto({
    required String subjectId,
    required List<int> imageBytes,
    String filename = 'observation.jpg',
  }) async {
    final response = await _api.postMultipart(
      '/subjects/$subjectId/observations/upload',
      fileField: 'file',
      filename: filename,
      fileBytes: imageBytes,
    );
    final json = jsonMap(response);
    final url = readString(json, 'imageUrl')?.trim() ??
        readString(json, 'image_url')?.trim() ??
        '';
    if (url.isEmpty) {
      throw StateError('Upload succeeded but no image URL returned');
    }
    return url;
  }
}
