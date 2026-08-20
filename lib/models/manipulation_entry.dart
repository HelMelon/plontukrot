import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';
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
      type: ManipulationType.fromCode(data['type'] as String?),
      appliedAt: readTimestamp(data['appliedAt']) ?? DateTime.now(),
      note: _nullableTrimmed(data['note'] as String?),
      stageBefore: data['stageBefore'] as int?,
      stageAfter: data['stageAfter'] as int?,
      stimulatorId: data['stimulatorId'] as String?,
      stimulatorName: _nullableTrimmed(data['stimulatorName'] as String?),
      dosage: _nullableTrimmed(data['dosage'] as String?),
    );
  }

  factory ManipulationEntry.fromFirestore(QueryDocumentSnapshot doc) {
    return ManipulationEntry.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>,
    );
  }

  static String? _nullableTrimmed(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.code,
      'appliedAt': Timestamp.fromDate(appliedAt),
      if (note != null) 'note': note,
      if (stageBefore != null) 'stageBefore': stageBefore,
      if (stageAfter != null) 'stageAfter': stageAfter,
      if (stimulatorId != null) 'stimulatorId': stimulatorId,
      if (stimulatorName != null) 'stimulatorName': stimulatorName,
      if (dosage != null) 'dosage': dosage,
    };
  }
}
