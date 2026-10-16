import 'model_helpers.dart';

/// A place a plant can stand. [balconyId] is the reserved balcony room id.
class Room {
  static const balconyId = 'balcony';

  final String id;
  final String name;
  final DateTime? createdAt;

  const Room({
    required this.id,
    required this.name,
    this.createdAt,
  });

  bool get isBalcony => id == balconyId;

  /// Feature-flag key for this room once a sensor device id is stored.
  static String sensorFlagKey(String roomId) => 'room_sensor_$roomId';

  factory Room.fromMap(String id, Map<String, dynamic> data) {
    return Room(
      id: id,
      name: readString(data, 'name') ?? '',
      createdAt: readDate(data, 'createdAt') ?? readDate(data, 'created_at'),
    );
  }
}

/// Yandex device bound to a room.
class RoomSensorBinding {
  final String roomId;
  final String deviceId;

  const RoomSensorBinding({required this.roomId, required this.deviceId});

  factory RoomSensorBinding.fromMap(Map<String, dynamic> data) {
    return RoomSensorBinding(
      roomId: readString(data, 'roomId') ?? readString(data, 'room_id') ?? '',
      deviceId:
          readString(data, 'deviceId') ?? readString(data, 'device_id') ?? '',
    );
  }
}

/// One live property reported by a room's Yandex device.
class RoomSensorProperty {
  final String instance;
  final Object? value;
  final String? unit;

  const RoomSensorProperty({
    required this.instance,
    required this.value,
    this.unit,
  });

  factory RoomSensorProperty.fromMap(Map<String, dynamic> data) {
    return RoomSensorProperty(
      instance: readString(data, 'instance') ?? '',
      value: data['value'],
      unit: readString(data, 'unit'),
    );
  }
}
