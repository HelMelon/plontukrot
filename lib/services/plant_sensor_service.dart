import '../models/model_helpers.dart';
import '../models/plant_sensor_binding.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'rest_stream.dart';

/// Bind a plant to a soil-moisture pot and read its latest moisture.
class PlantSensorService {
  final ApiClient _api = ApiClient.instance;

  /// Bind [pot] to [plantId]. Returns the binding with the latest reading.
  Future<PlantSensorBinding> bind({
    required String plantId,
    required int pot,
  }) async {
    final res = jsonMap(
      await _api.post('/plants/$plantId/sensor-binding', body: {'pot': pot}),
    );
    return PlantSensorBinding.fromMap(res);
  }

  /// The plant's current binding + latest moisture, or null if unbound.
  Future<PlantSensorBinding?> getBinding(String plantId) async {
    try {
      final res = await _api.get('/plants/$plantId/sensor-binding');
      if (res is! Map) return null;
      return PlantSensorBinding.fromMap(jsonMap(res));
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// Remove the plant's pot binding.
  Future<void> unbind(String plantId) async {
    try {
      await _api.delete('/plants/$plantId/sensor-binding');
    } on ApiException catch (e) {
      if (!e.isNotFound) rethrow;
    }
  }

  /// Live stream of the plant's binding (re-polls every 30s).
  Stream<PlantSensorBinding?> watchBinding(String plantId) {
    return restPollStream(() => getBinding(plantId));
  }

  /// All of the user's bindings with latest moisture, keyed by plant id.
  Future<Map<String, PlantSensorBinding>> getAllBindings() async {
    final list = jsonMapList(await _api.get('/plants/sensor-bindings'));
    return {
      for (final m in list)
        if (readString(m, 'plantId') != null)
          readString(m, 'plantId')!: PlantSensorBinding.fromMap(m),
    };
  }

  /// Live stream of all bindings (re-polls every 30s).
  Stream<Map<String, PlantSensorBinding>> watchAllBindings() {
    return restPollStream(getAllBindings);
  }
}
