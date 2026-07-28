import 'fertilizer_application_method.dart';
import 'fertilizer_dose.dart';
import 'firestore_helpers.dart';

class FertilizingEntry {
  final String id;
  final String? fertilizerId;
  final String fertilizerName;
  final DateTime appliedAt;
  final DateTime? nextFertilizing;
  final int waterMl;
  final List<FertilizerDose> components;
  final FertilizerApplicationMethod applicationMethod;

  const FertilizingEntry({
    required this.id,
    this.fertilizerId,
    required this.fertilizerName,
    required this.appliedAt,
    this.nextFertilizing,
    this.waterMl = 250,
    this.components = const [],
    this.applicationMethod = FertilizerApplicationMethod.root,
  });

  factory FertilizingEntry.fromMap(String id, Map<String, dynamic> data) {
    final rawComponents = data['components'] as List<dynamic>?;

    return FertilizingEntry(
      id: id,
      fertilizerId: data['fertilizerId'] as String?,
      fertilizerName: data['fertilizerName'] as String? ??
          data['name'] as String? ??
          'Неизвестно',
      appliedAt: readTimestamp(data['appliedAt']) ?? DateTime.now(),
      nextFertilizing: readTimestamp(data['nextFertilizing']),
      waterMl: normalizeWaterMl((data['waterMl'] as num?)?.toInt()),
      components: rawComponents != null
          ? rawComponents
              .map((item) => FertilizerDose.fromMap(item as Map<String, dynamic>))
              .toList()
          : const [],
      applicationMethod: FertilizerApplicationMethod.fromCode(
        data['applicationMethod'] as String?,
      ),
    );
  }

  factory FertilizingEntry.fromFirestoreData({
    required String id,
    required Map<String, dynamic> data,
    required String fertilizerName,
  }) {
    final rawComponents = data['components'] as List<dynamic>?;

    return FertilizingEntry(
      id: id,
      fertilizerId: data['fertilizerId'] as String?,
      fertilizerName: fertilizerName,
      appliedAt: readTimestamp(data['appliedAt']) ?? DateTime.now(),
      nextFertilizing: readTimestamp(data['nextFertilizing']),
      waterMl: normalizeWaterMl((data['waterMl'] as num?)?.toInt()),
      components: rawComponents != null
          ? rawComponents
              .map((item) => FertilizerDose.fromMap(item as Map<String, dynamic>))
              .toList()
          : const [],
      applicationMethod: FertilizerApplicationMethod.fromCode(
        data['applicationMethod'] as String?,
      ),
    );
  }
}
