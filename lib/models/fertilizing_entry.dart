import 'firestore_helpers.dart';

class FertilizingEntry {
  final String id;
  final String fertilizerId;
  final String fertilizerName;
  final DateTime appliedAt;
  final DateTime? nextFertilizing;

  const FertilizingEntry({
    required this.id,
    required this.fertilizerId,
    required this.fertilizerName,
    required this.appliedAt,
    this.nextFertilizing,
  });

  factory FertilizingEntry.fromMap(String id, Map<String, dynamic> data) {
    return FertilizingEntry(
      id: id,
      fertilizerId: data['fertilizerId'] as String? ?? '',
      fertilizerName: data['fertilizerName'] as String? ?? 'Unknown',
      appliedAt: readTimestamp(data['appliedAt']) ?? DateTime.now(),
      nextFertilizing: readTimestamp(data['nextFertilizing']),
    );
  }

  factory FertilizingEntry.fromFirestoreData({
    required String id,
    required Map<String, dynamic> data,
    required String fertilizerName,
  }) {
    return FertilizingEntry(
      id: id,
      fertilizerId: data['fertilizerId'] as String? ?? '',
      fertilizerName: fertilizerName,
      appliedAt: readTimestamp(data['appliedAt']) ?? DateTime.now(),
      nextFertilizing: readTimestamp(data['nextFertilizing']),
    );
  }
}
