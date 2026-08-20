enum ManipulationType {
  pinching,
  rerooting,
  stimulator;

  String get code => name;

  static ManipulationType fromCode(dynamic code) {
    if (code is int && code >= 0 && code < ManipulationType.values.length) {
      return ManipulationType.values[code];
    }
    if (code is String) {
      return ManipulationType.values.firstWhere(
        (type) => type.name == code,
        orElse: () => ManipulationType.pinching,
      );
    }
    return ManipulationType.pinching;
  }
}
