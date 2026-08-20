import '../models/model_helpers.dart';
import '../models/stimulator.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'rest_stream.dart';

class StimulatorService {
  final ApiClient _api = ApiClient.instance;

  String get uid => '';

  Future<List<Stimulator>> _fetchAll() async {
    final list = jsonMapList(await _api.get('/stimulators'));
    return list
        .map((m) => Stimulator.fromMap(readString(m, 'id') ?? '', m))
        .toList()
      ..sort((a, b) {
        final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
  }

  Future<Stimulator?> findStimulatorByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    for (final item in await _fetchAll()) {
      if (item.name.trim().toLowerCase() == lower) return item;
    }
    return null;
  }

  Future<String> addStimulator({
    required String name,
    String? defaultDosage,
  }) async {
    final created = jsonMap(await _api.post('/stimulators', body: {
      'name': name.trim(),
      'default_dosage': (defaultDosage != null && defaultDosage.trim().isNotEmpty)
          ? defaultDosage.trim()
          : null,
    }));
    return readString(created, 'id') ?? '';
  }

  Future<void> updateStimulator({
    required String stimulatorId,
    required String name,
    String? defaultDosage,
  }) async {
    final dosage = defaultDosage?.trim();
    try {
      await _api.patch('/stimulators/$stimulatorId', body: {
        'name': name.trim(),
        'default_dosage': (dosage != null && dosage.isNotEmpty) ? dosage : null,
      });
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> deleteStimulator(String stimulatorId) async {
    await _api.delete('/stimulators/$stimulatorId');
  }

  Stream<List<Stimulator>> watchStimulators() => restPollStream(_fetchAll);

  Future<Stimulator?> getStimulator(String stimulatorId) async {
    for (final item in await _fetchAll()) {
      if (item.id == stimulatorId) return item;
    }
    return null;
  }
}
