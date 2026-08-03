enum PropagationStatus {
  active,
  sold,
  lost;

  String get code => name;

  static PropagationStatus fromCode(String? code) {
    return PropagationStatus.values.firstWhere(
      (status) => status.name == code,
      orElse: () => PropagationStatus.active,
    );
  }
}
