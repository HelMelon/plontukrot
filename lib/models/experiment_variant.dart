import 'experiment_observation.dart';
import 'experiment_subject.dart';
import 'model_helpers.dart';

/// One arm of an experiment. Variants are what the user compares; their
/// difference is described in the user's own words ([description]) because the
/// variable of a trial can be a substrate, a place, a care regime, or anything
/// else the user invents.
class ExperimentVariant {
  final String id;
  final String label;
  final String? description;
  final String? imageUrl;
  final int position;
  final List<ExperimentSubject> subjects;
  final List<ExperimentObservation> observations;
  final int observationCount;
  final DateTime? latestObservedAt;

  const ExperimentVariant({
    required this.id,
    required this.label,
    this.description,
    this.imageUrl,
    required this.position,
    this.subjects = const [],
    this.observations = const [],
    this.observationCount = 0,
    this.latestObservedAt,
  });

  bool get hasSubjects => subjects.isNotEmpty;

  /// Latest observation that carries any numeric reading — the row the compare
  /// screen shows for this variant.
  ExperimentObservation? get latestWithMetrics {
    for (final observation in observations.reversed) {
      if (observation.hasMetrics) return observation;
    }
    return null;
  }

  factory ExperimentVariant.fromMap(String id, Map<String, dynamic> data) {
    final rawSubjects = readField(data, 'subjects');
    final rawObservations = readField(data, 'observations');
    return ExperimentVariant(
      id: id,
      label: readString(data, 'label') ?? '',
      description: readString(data, 'description'),
      imageUrl: readString(data, 'imageUrl'),
      position: readInt(data, 'position') ?? 0,
      subjects: rawSubjects is List
          ? rawSubjects
              .whereType<Map>()
              .map((e) => ExperimentSubject.fromMap(
                    readString(Map<String, dynamic>.from(e), 'id') ?? '',
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      observations: rawObservations is List
          ? rawObservations
              .whereType<Map>()
              .map((e) => ExperimentObservation.fromMap(
                    readString(Map<String, dynamic>.from(e), 'id') ?? '',
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      observationCount: readInt(data, 'observationCount') ?? 0,
      latestObservedAt: readDate(data, 'latestObservedAt'),
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        'position': position,
      };
}
