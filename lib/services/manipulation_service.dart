import '../models/model_helpers.dart';
import '../models/manipulation_entry.dart';
import '../models/manipulation_type.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'plant_service.dart';
import 'rest_stream.dart';

class ManipulationService {
  final ApiClient _api = ApiClient.instance;

  String get uid => '';

  static String? _trimOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static void _validateStimulatorName(String? name) {
    if (_trimOrNull(name) == null) {
      throw ArgumentError('stimulatorName is required for stimulator type');
    }
  }

  Future<List<ManipulationEntry>> _fetchHistory(String plantId) async {
    final list = jsonMapList(await _api.get('/plants/$plantId/manipulations'));
    return list
        .map((m) => ManipulationEntry.fromMap(readString(m, 'id') ?? '', m))
        .toList()
      ..sort((a, b) {
        final aDate = a.endedAt ?? a.appliedAt;
        final bDate = b.endedAt ?? b.appliedAt;
        return bDate.compareTo(aDate);
      });
  }

  Future<void> addManipulation({
    required String plantId,
    required ManipulationType type,
    required DateTime appliedAt,
    DateTime? endedAt,
    String? note,
    int? stageAfter,
    String? stimulatorId,
    String? stimulatorName,
    String? dosage,
  }) async {
    if (type == ManipulationType.stimulator) {
      _validateStimulatorName(stimulatorName);
    }

    int? stageBefore;
    if (type == ManipulationType.rerooting) {
      final plant = await PlantService().getPlant(plantId);
      stageBefore = plant?.stage ?? 0;
    }

    await _api.post('/plants/$plantId/manipulations', body: {
      'type': type.index,
      'applied_at': isoDate(appliedAt),
      if (endedAt != null) 'ended_at': isoDate(endedAt),
      'note': _trimOrNull(note),
      'stage_before': stageBefore,
      'stage_after': stageAfter,
      if (stimulatorId != null) 'stimulator_id': stimulatorId,
      'stimulator_name': _trimOrNull(stimulatorName),
      'dosage': _trimOrNull(dosage),
    });

    if (type == ManipulationType.rerooting && stageAfter != null) {
      try {
        await _api.patch('/plants/$plantId', body: {'stage': stageAfter});
      } on ApiException catch (error) {
        if (!error.isNotFound) rethrow;
      }
    }
  }

  Future<void> addManipulations({
    required Iterable<String> plantIds,
    required ManipulationType type,
    required DateTime appliedAt,
    DateTime? endedAt,
    String? note,
    int? stageAfter,
    String? stimulatorId,
    String? stimulatorName,
    String? dosage,
  }) async {
    for (final plantId in plantIds) {
      await addManipulation(
        plantId: plantId,
        type: type,
        appliedAt: appliedAt,
        endedAt: endedAt,
        note: note,
        stageAfter: stageAfter,
        stimulatorId: stimulatorId,
        stimulatorName: stimulatorName,
        dosage: dosage,
      );
    }
  }

  Future<void> updateManipulation({
    required String plantId,
    required String manipulationId,
    required ManipulationType type,
    required DateTime appliedAt,
    DateTime? endedAt,
    String? note,
    int? stageBefore,
    int? stageAfter,
    String? stimulatorId,
    String? stimulatorName,
    String? dosage,
  }) async {
    if (type == ManipulationType.stimulator) {
      _validateStimulatorName(stimulatorName);
    }
    try {
      await _api.patch('/plants/$plantId/manipulations/$manipulationId', body: {
        'type': type.index,
        'applied_at': isoDate(appliedAt),
        'ended_at': isoOrNull(endedAt),
        'note': _trimOrNull(note),
        'stage_before': stageBefore,
        'stage_after': stageAfter,
        'stimulator_id': stimulatorId,
        'stimulator_name': _trimOrNull(stimulatorName),
        'dosage': _trimOrNull(dosage),
      });
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
    if (type == ManipulationType.rerooting && stageAfter != null) {
      try {
        await _api.patch('/plants/$plantId', body: {'stage': stageAfter});
      } on ApiException catch (error) {
        if (!error.isNotFound) rethrow;
      }
    }
  }

  Future<void> deleteManipulation({
    required String plantId,
    required String manipulationId,
  }) async {
    try {
      await _api.delete('/plants/$plantId/manipulations/$manipulationId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Stream<List<ManipulationEntry>> getManipulationHistory(
    String plantId, {
    int limit = 40,
  }) {
    return restPollStream(() async {
      final entries = await _fetchHistory(plantId);
      if (entries.length <= limit) return entries;
      return entries.take(limit).toList();
    });
  }

  Stream<ManipulationEntry?> watchLastManipulation(String plantId) {
    return restPollStream(() async {
      final entries = await _fetchHistory(plantId);
      if (entries.isEmpty) return null;
      return entries.first;
    });
  }
}
