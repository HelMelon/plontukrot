enum FertilizerApplicationMethod {
  root,
  foliar;

  String get code => name;

  String get label => switch (this) {
        FertilizerApplicationMethod.root => 'Корневое',
        FertilizerApplicationMethod.foliar => 'Внекорневое',
      };

  static FertilizerApplicationMethod fromCode(String? code) {
    return FertilizerApplicationMethod.values.firstWhere(
      (method) => method.name == code,
      orElse: () => FertilizerApplicationMethod.root,
    );
  }
}
