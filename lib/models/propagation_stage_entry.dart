import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';
import 'propagation_outcome.dart';

class PropagationStageEntry {
  final String? id;
  final int stage;
  final DateTime changedAt;
  final int? quantityAlive;
  final String? note;
  final PropagationOutcome? outcome;

  const PropagationStageEntry({
    this.id,
    required this.stage,
    required this.changedAt,
    this.quantityAlive,
    this.note,
    this.outcome,
  });

  factory PropagationStageEntry.fromMap(String? id, Map<String, dynamic> data) {
    final outcomeCode = data['outcome'] as String?;
    return PropagationStageEntry(
      id: id,
      stage: data['stage'] as int? ?? 1,
      changedAt: readTimestamp(data['changedAt']) ?? DateTime.now(),
      quantityAlive: data['quantityAlive'] as int?,
      note: data['note'] as String?,
      outcome: outcomeCode == null
          ? null
          : PropagationOutcome.fromCode(outcomeCode),
    );
  }

  factory PropagationStageEntry.fromFirestore(QueryDocumentSnapshot doc) {
    return PropagationStageEntry.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stage': stage,
      'changedAt': Timestamp.fromDate(changedAt),
      if (quantityAlive != null) 'quantityAlive': quantityAlive,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      if (outcome != null) 'outcome': outcome!.code,
    };
  }
}
