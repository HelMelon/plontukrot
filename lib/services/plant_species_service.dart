import '../models/plant_species.dart';
import '../models/model_helpers.dart';
import 'api_client.dart';
import 'rest_stream.dart';

class PlantSpeciesService {
  final ApiClient _api = ApiClient.instance;

  Future<void> ensureSpecies({
    required String species,
    required String genus,
    String? plantFamily,
  }) async {
    final trimmedSpecies = species.trim();
    if (trimmedSpecies.isEmpty) return;
    final trimmedFamily = plantFamily?.trim();
    await _api.post('/species', body: {
      'species': trimmedSpecies,
      'genus': genus.trim(),
      'plant_family':
          (trimmedFamily == null || trimmedFamily.isEmpty) ? null : trimmedFamily,
    });
  }

  Stream<PlantSpecies?> watchSpecies(String species) {
    final trimmed = species.trim();
    if (trimmed.isEmpty) {
      return Stream.value(null);
    }
    final id = PlantSpecies.docIdFor(trimmed);
    return restPollStream(() async {
      final list = jsonMapList(await _api.get('/species'));
      for (final map in list) {
        final item = PlantSpecies.fromMap(readString(map, 'id') ?? '', map);
        if (item.id == id || item.species.toLowerCase() == trimmed.toLowerCase()) {
          return item;
        }
      }
      return null;
    });
  }
}
