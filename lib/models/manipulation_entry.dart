import 'model_helpers.dart';
import 'manipulation_type.dart';

class ManipulationEntry {
  final String id;
  final ManipulationType type;
  final DateTime appliedAt;
  final String? note;
  final int? stageBefore;
  final int? stageAfter;
  final String? stimulatorId;
  final String? stimulatorName;
  final String? dosage;

  const ManipulationEntry({
    required this.id,
    required this.type,
    required this.appliedAt,
    this.note,
    this.stageBefore,
    this.stageAfter,
    this.stimulatorId,
    this.stimulatorName,
    this.dosage,
  });

  factory ManipulationEntry.fromMap(String id, Map<String, dynamic> data) {
    return ManipulationEntry(
      id: id,
      type: ManipulationType.fromCode(readField(data, 'type')),
      appliedAt: readDate(data, 'appliedAt') ?? DateTime.now(),
      note: _nullableTrimmed(readString(data, 'note')),
      stageBefore: readInt(data, 'stageBefore'),
      stageAfter: readInt(data, 'stageAfter'),
      stimulatorId: readString(data, 'stimulatorId'),
      stimulatorName: _nullableTrimmed(readString(data, 'stimulatorName')),
      dosage: _nullableTrimmed(readString(data, 'dosage')),
    );
  }

  static String? _nullableTrimmed(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'appliedAt': isoOrNull(appliedAt),
      'applied_at': isoOrNull(appliedAt),
      if (note != null) 'note': note,
      if (stageBefore != null) 'stageBefore': stageBefore,
      if (stageBefore != null) 'stage_before': stageBefore,
      if (stageAfter != null) 'stageAfter': stageAfter,
      if (stageAfter != null) 'stage_after': stageAfter,
      if (stimulatorId != null) 'stimulatorId': stimulatorId,
      if (stimulatorId != null) 'stimulator_id': stimulatorId,
      if (stimulatorName != null) 'stimulatorName': stimulatorName,
      if (stimulatorName != null) 'stimulator_name': stimulatorName,
      if (dosage != null) 'dosage': dosage,
    };
  }
}
