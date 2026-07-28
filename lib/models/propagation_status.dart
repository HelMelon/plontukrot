enum PropagationStatus {
  active('Активно'),
  sold('Продано'),
  lost('Погибло');

  const PropagationStatus(this.label);

  final String label;

  String get code => name;

  static PropagationStatus fromCode(String? code) {
    return PropagationStatus.values.firstWhere(
      (status) => status.name == code,
      orElse: () => PropagationStatus.active,
    );
  }
}
