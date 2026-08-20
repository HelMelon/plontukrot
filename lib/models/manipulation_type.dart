enum ManipulationType {
  pinching,
  rerooting,
  stimulator;

  String get code => name;

  static ManipulationType fromCode(String? code) {
    return ManipulationType.values.firstWhere(
      (type) => type.name == code,
      orElse: () => ManipulationType.pinching,
    );
  }
}
