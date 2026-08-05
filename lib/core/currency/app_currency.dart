enum AppCurrency {
  usd,
  eur,
  rub,
  byn;

  String get code => name.toUpperCase();

  String get symbol => switch (this) {
        AppCurrency.usd => r'$',
        AppCurrency.eur => '€',
        AppCurrency.rub => '₽',
        AppCurrency.byn => 'Br',
      };

  static AppCurrency fromCode(String? code) {
    final normalized = code?.trim().toUpperCase();
    return AppCurrency.values.firstWhere(
      (currency) => currency.code == normalized,
      orElse: () => AppCurrency.usd,
    );
  }
}
