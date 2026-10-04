import 'model_helpers.dart';

/// Which kind of thing a trial participant points at. Kept as a string code
/// (not an int enum) because the backend stores `subject_type` as text.
enum ExperimentSubjectType {
  plant,
  propagation;

  String get code => name;

  static ExperimentSubjectType fromCode(dynamic code) {
    if (code is String) {
      return ExperimentSubjectType.values.firstWhere(
        (type) => type.name == code,
        orElse: () => ExperimentSubjectType.plant,
      );
    }
    return ExperimentSubjectType.plant;
  }
}

extension ExperimentSubjectTypeX on ExperimentSubjectType {
  bool get isPlant => this == ExperimentSubjectType.plant;
  bool get isPropagation => this == ExperimentSubjectType.propagation;
}

/// A participant of a variant: a real plant or a propagation batch.
class ExperimentSubject {
  final String id;
  final ExperimentSubjectType subjectType;
  final String subjectId;
  final String? subjectName;

  const ExperimentSubject({
    required this.id,
    required this.subjectType,
    required this.subjectId,
    this.subjectName,
  });

  String get displayName {
    final name = (subjectName ?? '').trim();
    return name.isEmpty ? subjectId : name;
  }

  factory ExperimentSubject.fromMap(String id, Map<String, dynamic> data) {
    return ExperimentSubject(
      id: id,
      subjectType: ExperimentSubjectType.fromCode(readField(data, 'subjectType')),
      subjectId: readString(data, 'subjectId') ?? '',
      subjectName: readString(data, 'subjectName'),
    );
  }

  Map<String, dynamic> toMap() => {
        'subject_type': subjectType.code,
        'subject_id': subjectId,
        if (subjectName != null) 'subject_name': subjectName,
      };
}
