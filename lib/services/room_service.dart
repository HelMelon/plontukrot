import '../models/model_helpers.dart';
import '../models/room.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'rest_stream.dart';

class RoomService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Room>> fetchRooms() async {
    final list = jsonMapList(await _api.get('/rooms'));
    final rooms = list
        .map((m) => Room.fromMap(readString(m, 'id') ?? '', m))
        .where((room) => room.id.isNotEmpty)
        .toList();
    rooms.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return rooms;
  }

  Future<Room?> findRoomByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    for (final room in await fetchRooms()) {
      if (room.name.trim().toLowerCase() == lower) return room;
    }
    return null;
  }

  Future<String> addRoom({required String name}) async {
    final created = jsonMap(await _api.post('/rooms', body: {
      'name': name.trim(),
    }));
    return readString(created, 'id') ?? '';
  }

  Future<void> updateRoom({
    required String roomId,
    required String name,
  }) async {
    try {
      await _api.patch('/rooms/$roomId', body: {'name': name.trim()});
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    await _api.delete('/rooms/$roomId');
  }

  Stream<List<Room>> watchRooms() => restPollStream(fetchRooms);

  /// Live Yandex properties for the device saved on [roomId].
  Future<List<RoomSensorProperty>> fetchSensorReading(String roomId) async {
    final map = jsonMap(await _api.get('/room-sensors/$roomId/reading'));
    final raw = map['properties'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => RoomSensorProperty.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.instance.isNotEmpty && item.value != null)
        .toList();
  }

  Future<List<RoomSensorBinding>> fetchSensors() async {
    final list = jsonMapList(await _api.get('/room-sensors'));
    return list
        .map(RoomSensorBinding.fromMap)
        .where((item) => item.roomId.isNotEmpty && item.deviceId.isNotEmpty)
        .toList();
  }

  Stream<List<RoomSensorBinding>> watchSensors() => restPollStream(fetchSensors);

  Future<void> setSensor({
    required String roomId,
    required String deviceId,
  }) async {
    await _api.put('/room-sensors/$roomId', body: {
      'device_id': deviceId.trim(),
    });
  }

  Future<void> clearSensor(String roomId) async {
    try {
      await _api.delete('/room-sensors/$roomId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }
}
