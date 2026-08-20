import 'model_helpers.dart';

class WateringEntry {
  final String? id;
  final DateTime wateredAt;
  final DateTime? nextWatering;

  const WateringEntry({
    this.id,
    required this.wateredAt,
    this.nextWatering,
  });

  factory WateringEntry.fromMap(String? id, Map<String, dynamic> data) {
    return WateringEntry(
      id: id,
      wateredAt: readDate(data, 'wateredAt') ?? DateTime.now(),
      nextWatering: readDate(data, 'nextWatering'),
    );
  }
}
