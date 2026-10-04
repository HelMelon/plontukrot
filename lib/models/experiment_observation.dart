import 'model_helpers.dart';

/// One logged observation for a single [ExperimentSubject]: a note, an optional
/// photo, and the numeric readings the user chose to record. Any of the numeric
/// fields may be null — the user is not forced to measure everything each time.
class ExperimentObservation {
  final String id;
  final String subjectId;
  final DateTime observedAt;
  final String? note;
  final String? imageUrl;
  final double? heightCm;
  final int? leafCount;
  final double? moisture;
  final DateTime? createdAt;

  const ExperimentObservation({
    required this.id,
    required this.subjectId,
    required this.observedAt,
    this.note,
    this.imageUrl,
    this.heightCm,
    this.leafCount,
    this.moisture,
    this.createdAt,
  });

  bool get hasMetrics =>
      heightCm != null || leafCount != null || moisture != null;

  factory ExperimentObservation.fromMap(String id, Map<String, dynamic> data) {
    return ExperimentObservation(
      id: id,
      subjectId: readString(data, 'subjectId') ?? '',
      observedAt: readDate(data, 'observedAt') ?? DateTime.now(),
      note: readString(data, 'note'),
      imageUrl: readString(data, 'imageUrl'),
      heightCm: readDouble(data, 'heightCm'),
      leafCount: readInt(data, 'leafCount'),
      moisture: readDouble(data, 'moisture'),
      createdAt: readDate(data, 'createdAt'),
    );
  }

  Map<String, dynamic> toMap() => {
        'observed_at': isoOrNull(observedAt),
        if (note != null) 'note': note,
        if (imageUrl != null) 'image_url': imageUrl,
        if (heightCm != null) 'height_cm': heightCm,
        if (leafCount != null) 'leaf_count': leafCount,
        if (moisture != null) 'moisture': moisture,
      };
}
