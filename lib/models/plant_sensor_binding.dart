import 'model_helpers.dart';

/// A plant's binding to a soil-moisture pot (1..N), plus the latest reading.
class PlantSensorBinding {
  final String plantId;
  final int pot;
  final double? moisture;
  final int? raw;
  final DateTime? readAt;
  final DateTime? createdAt;

  const PlantSensorBinding({
    required this.plantId,
    required this.pot,
    this.moisture,
    this.raw,
    this.readAt,
    this.createdAt,
  });

  bool get hasReading => moisture != null;

  factory PlantSensorBinding.fromMap(Map<String, dynamic> data) {
    return PlantSensorBinding(
      plantId: readString(data, 'plantId') ?? '',
      pot: readInt(data, 'pot') ?? 0,
      moisture: readDouble(data, 'moisture'),
      raw: readInt(data, 'raw'),
      readAt: readDate(data, 'readAt'),
      createdAt: readDate(data, 'createdAt'),
    );
  }
}
