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

  static PropagationMethod fromCode(dynamic code) {
    if (code is int && code >= 0 && code < PropagationMethod.values.length) {
      return PropagationMethod.values[code];
    }
    if (code is String) {
      return PropagationMethod.values.firstWhere(
        (method) => method.name == code,
        orElse: () => PropagationMethod.leaf,
      );
    }
    return PropagationMethod.leaf;
  }
}
