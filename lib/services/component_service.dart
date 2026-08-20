import '../models/catalog_component.dart';
import '../models/model_helpers.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'rest_stream.dart';

const List<String> kDefaultSoilComponentNames = [
  'Perlite',
  'Coco coir',
  'Bark',
  'Peat',
  'Sand',
  'Charcoal',
  'Zeolite',
  'Pumice',
  'Worm castings',
  'Vermiculite',
];

class ComponentService {
  final ApiClient _api = ApiClient.instance;

  Future<List<CatalogComponent>> _fetchAll() async {
    final list = jsonMapList(await _api.get('/components'));
    return list
        .map((m) => CatalogComponent.fromMap(readString(m, 'id') ?? '', m))
        .toList();
  }

  Future<CatalogComponent?> findComponentByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    for (final item in await _fetchAll()) {
      if (item.name.trim().toLowerCase() == lower) return item;
    }
    return null;
  }

  Future<String> ensureComponent({required String name}) async {
    final existing = await findComponentByName(name);
    if (existing != null) return existing.id;
    return addComponent(name: name);
  }

  Future<String> addComponent({required String name}) async {
    final created = jsonMap(await _api.post('/components', body: {
      'name': name.trim(),
    }));
    return readString(created, 'id') ?? '';
  }

  Future<void> updateComponent({
    required String componentId,
    required String name,
  }) async {
    try {
      await _api.patch('/components/$componentId', body: {'name': name.trim()});
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> deleteComponent(String componentId) async {
    await _api.delete('/components/$componentId');
  }

  Stream<List<CatalogComponent>> getComponents() {
    return restPollStream(() async {
      final items = await _fetchAll();
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    });
  }

  Future<void> ensureDefaultComponents() async {
    final existing = await _fetchAll();
    if (existing.isNotEmpty) return;
    for (final name in kDefaultSoilComponentNames) {
      await addComponent(name: name);
    }
  }
}
