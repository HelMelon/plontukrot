enum PropagationMethod {
  leaf,
  leafFragment,
  rhizome,
  tuber,
  division,
  offset,
  cutting,
  microcloning;

  String get code => name;

  static PropagationMethod fromCode(String? code) {
    return PropagationMethod.values.firstWhere(
      (method) => method.name == code,
      orElse: () => PropagationMethod.leaf,
    );
  }
}
