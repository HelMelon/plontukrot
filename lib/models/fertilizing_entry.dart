import 'fertilizer_application_method.dart';
import 'fertilizer_dose.dart';
import 'model_helpers.dart';

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
    final rawComponents = readField(data, 'components') as List<dynamic>?;

    return FertilizingEntry(
      id: id,
      fertilizerId: readString(data, 'fertilizerId'),
      fertilizerName: readString(data, 'fertilizerName') ??
          readString(data, 'name') ??
          '',
      appliedAt: readDate(data, 'appliedAt') ?? DateTime.now(),
      nextFertilizing: readDate(data, 'nextFertilizing'),
      waterMl: normalizeWaterMl(readInt(data, 'waterMl')),
      components: rawComponents != null
          ? rawComponents
              .whereType<Map>()
              .map((item) => FertilizerDose.fromMap(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      applicationMethod: FertilizerApplicationMethod.fromCode(
        readString(data, 'applicationMethod'),
      ),
    );
  }

  factory FertilizingEntry.fromFirestoreData({
    required String id,
    required Map<String, dynamic> data,
    required String fertilizerName,
  }) {
    final parsed = FertilizingEntry.fromMap(id, data);
    return FertilizingEntry(
      id: parsed.id,
      fertilizerId: parsed.fertilizerId,
      fertilizerName: fertilizerName,
      appliedAt: parsed.appliedAt,
      nextFertilizing: parsed.nextFertilizing,
      waterMl: parsed.waterMl,
      components: parsed.components,
      applicationMethod: parsed.applicationMethod,
    );
  }
}
