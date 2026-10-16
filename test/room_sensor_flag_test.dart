import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/room.dart';

void main() {
  test('room sensor flag key is the room id with a stable prefix', () {
    expect(Room.sensorFlagKey(Room.balconyId), 'room_sensor_balcony');
    expect(
      Room.sensorFlagKey('abc123'),
      'room_sensor_abc123',
    );
  });
}
