import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_currency.dart';

/// Local-only currency preference. Not synced to Firestore.
class AppCurrencyController extends ChangeNotifier {
  AppCurrencyController._();

  static final AppCurrencyController instance = AppCurrencyController._();

  static const _prefsKey = 'app_currency_code';
  static const AppCurrency defaultCurrency = AppCurrency.usd;

  SharedPreferences? _prefs;
  AppCurrency _currency = defaultCurrency;

  AppCurrency get currency => _currency;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_prefsKey);
    if (stored != null) {
      _currency = AppCurrency.fromCode(stored);
    }
  }

  Future<void> setCurrency(AppCurrency currency) async {
    _currency = currency;
    await _prefs?.setString(_prefsKey, currency.code);
    notifyListeners();
  }

  String format(num amount, {String? locale}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: _currency.symbol,
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return formatter.format(amount);
  }
}
