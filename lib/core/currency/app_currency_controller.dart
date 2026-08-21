import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/model_helpers.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import 'app_currency.dart';

/// Currency preference: SharedPreferences cache + `GET/PATCH /auth/me`.
class AppCurrencyController extends ChangeNotifier {
  AppCurrencyController._();

  static final AppCurrencyController instance = AppCurrencyController._();

  static const _prefsKey = 'app_currency_code';
  static const firestoreField = 'currencyCode';
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
    await _writeToCloud(currency.code);
    notifyListeners();
  }

  Future<void> syncWithCloud() async {
    if (AuthService().currentUser == null) return;

    try {
      final json = await UserProfileService().fetchMe();
      final remote = readString(json, 'currency_code') ??
          readString(json, firestoreField);

      if (remote != null && remote.trim().isNotEmpty) {
        final next = AppCurrency.fromCode(remote);
        if (next == _currency) return;
        _currency = next;
        await _prefs?.setString(_prefsKey, next.code);
        notifyListeners();
        return;
      }

      final hasLocal = _prefs?.containsKey(_prefsKey) ?? false;
      if (hasLocal) {
        await _writeToCloud(_currency.code);
      }
    } catch (_) {}
  }

  Future<void> _writeToCloud(String code) async {
    if (AuthService().currentUser == null) return;
    try {
      await UserProfileService().patchProfile({'currency_code': code});
    } catch (_) {}
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
