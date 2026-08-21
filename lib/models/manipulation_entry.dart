import 'model_helpers.dart';
import 'manipulation_type.dart';
import 'reanimation_tag.dart';

class ManipulationEntry {
  final String id;
  final ManipulationType type;
  final DateTime appliedAt;
  final DateTime? endedAt;
  final List<ReanimationTag> reanimationTags;
  final bool isGreenhouse;
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
    this.endedAt,
    this.reanimationTags = const [],
    this.isGreenhouse = false,
    this.note,
    this.stageBefore,
    this.stageAfter,
    this.stimulatorId,
    this.stimulatorName,
    this.dosage,
  });

  factory ManipulationEntry.fromMap(String id, Map<String, dynamic> data) {
    final rawTags = readField(data, 'reanimationTags') ??
        readField(data, 'reanimation_tags') ??
        readField(data, 'tags');
    final tags = rawTags is List
        ? rawTags
            .map((e) => ReanimationTag.tryParse(e?.toString()))
            .whereType<ReanimationTag>()
            .toList()
        : const <ReanimationTag>[];

    final isGreenhouse = readBool(data, 'isGreenhouse', fallback: false) ||
        readBool(data, 'is_greenhouse', fallback: false) ||
        readBool(data, 'greenhouse', fallback: false);

    return ManipulationEntry(
      id: id,
      type: ManipulationType.fromCode(readField(data, 'type')),
      appliedAt: readDate(data, 'appliedAt') ??
          readDate(data, 'applied_at') ??
          DateTime.now(),
      endedAt: readDate(data, 'endedAt') ?? readDate(data, 'ended_at'),
      reanimationTags: tags,
      isGreenhouse: isGreenhouse,
      note: _nullableTrimmed(readString(data, 'note')),
      stageBefore: readInt(data, 'stageBefore') ?? readInt(data, 'stage_before'),
      stageAfter: readInt(data, 'stageAfter') ?? readInt(data, 'stage_after'),
      stimulatorId:
          readString(data, 'stimulatorId') ?? readString(data, 'stimulator_id'),
      stimulatorName: _nullableTrimmed(
        readString(data, 'stimulatorName') ??
            readString(data, 'stimulator_name'),
      ),
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
      if (endedAt != null) 'endedAt': isoOrNull(endedAt),
      if (endedAt != null) 'ended_at': isoOrNull(endedAt),
      if (reanimationTags.isNotEmpty)
        'reanimationTags': reanimationTags.map((e) => e.code).toList(),
      if (reanimationTags.isNotEmpty)
        'reanimation_tags': reanimationTags.map((e) => e.code).toList(),
      if (reanimationTags.isNotEmpty)
        'tags': reanimationTags.map((e) => e.code).toList(),
      if (isGreenhouse) 'isGreenhouse': true,
      if (isGreenhouse) 'is_greenhouse': true,
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
