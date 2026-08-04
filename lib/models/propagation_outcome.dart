/// Final disposition of units within a propagation batch.
///
/// Distinct from [stage]: stage history is preserved; outcome only reduces
/// alive quantity. "Alive" is represented by the absence of an outcome
/// (remaining [quantityAlive]), not a separate enum value.
enum PropagationOutcome {
  sold,
  gifted,
  traded,
  lost;

  String get code => name;

  static PropagationOutcome fromCode(String? code) {
    return PropagationOutcome.values.firstWhere(
      (outcome) => outcome.name == code,
      orElse: () => PropagationOutcome.lost,
    );
  }
}
