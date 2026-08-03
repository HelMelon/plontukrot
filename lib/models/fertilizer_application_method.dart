enum FertilizerApplicationMethod {
  root,
  foliar;

  String get code => name;

  static FertilizerApplicationMethod fromCode(String? code) {
    return FertilizerApplicationMethod.values.firstWhere(
      (method) => method.name == code,
      orElse: () => FertilizerApplicationMethod.root,
    );
  }
}
