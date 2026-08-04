import 'propagation_outcome.dart';

enum PropagationStatus {
  active,
  sold,
  gifted,
  traded,
  lost;

  String get code => name;

  bool get isArchivedStatus =>
      this == PropagationStatus.sold ||
      this == PropagationStatus.gifted ||
      this == PropagationStatus.traded ||
      this == PropagationStatus.lost;

  static PropagationStatus fromCode(String? code) {
    return PropagationStatus.values.firstWhere(
      (status) => status.name == code,
      orElse: () => PropagationStatus.active,
    );
  }

  /// Archive label when the last unit leaves via an explicit outcome.
  static PropagationStatus archiveForOutcome(PropagationOutcome outcome) {
    return switch (outcome) {
      PropagationOutcome.sold => PropagationStatus.sold,
      PropagationOutcome.gifted => PropagationStatus.gifted,
      PropagationOutcome.traded => PropagationStatus.traded,
      PropagationOutcome.lost => PropagationStatus.lost,
    };
  }

  /// Fallback when alive hits zero via stage change (no explicit outcome).
  static PropagationStatus archiveFromCounters({
    required int soldQuantity,
    required int giftedQuantity,
    required int tradedQuantity,
    required int lostQuantity,
  }) {
    if (soldQuantity > 0) return PropagationStatus.sold;
    if (giftedQuantity > 0) return PropagationStatus.gifted;
    if (tradedQuantity > 0) return PropagationStatus.traded;
    if (lostQuantity > 0) return PropagationStatus.lost;
    return PropagationStatus.lost;
  }
}
