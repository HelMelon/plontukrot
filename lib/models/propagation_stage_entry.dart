import 'model_helpers.dart';
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
    final outcomeCode = readString(data, 'outcome');
    return PropagationStageEntry(
      id: id,
      stage: readInt(data, 'stage') ?? 1,
      changedAt: readDate(data, 'changedAt') ?? DateTime.now(),
      quantityAlive: readInt(data, 'quantityAlive'),
      note: readString(data, 'note'),
      outcome: outcomeCode == null
          ? null
          : PropagationOutcome.fromCode(outcomeCode),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stage': stage,
      'changedAt': isoOrNull(changedAt),
      'changed_at': isoOrNull(changedAt),
      if (quantityAlive != null) 'quantityAlive': quantityAlive,
      if (quantityAlive != null) 'quantity_alive': quantityAlive,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      if (outcome != null) 'outcome': outcome!.code,
    };
  }
}
