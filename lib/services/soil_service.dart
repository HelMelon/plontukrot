import '../models/component.dart';
import '../models/model_helpers.dart';
import '../models/soil.dart';
import 'api_client.dart';
import 'rest_stream.dart';

class SoilService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Soil>> _fetchAll() async {
    final list = jsonMapList(await _api.get('/soils'));
    return list
        .map((m) => Soil.fromMap(readString(m, 'id') ?? '', m))
        .toList()
      ..sort((a, b) {
        final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
  }

  Future<Soil?> findSoilByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    for (final item in await _fetchAll()) {
      if (item.name.trim().toLowerCase() == lower) return item;
    }
    return null;
  }

  Future<String> ensureSoil({
    required String name,
    required List<SoilComponent> components,
  }) async {
    final existing = await findSoilByName(name);
    if (existing != null) return existing.id;
    return addSoil(name: name, components: components);
  }

  Future<String> addSoil({
    required String name,
    required List<SoilComponent> components,
  }) async {
    final created = jsonMap(await _api.post('/soils', body: {
      'name': name,
      'components': components.map((e) => e.toMap()).toList(),
    }));
    return readString(created, 'id') ?? '';
  }

  Stream<List<Soil>> getSoils() => restPollStream(_fetchAll);

  Future<Soil?> getSoil(String soilId) async {
    for (final item in await _fetchAll()) {
      if (item.id == soilId) return item;
    }
    return null;
  }
}
