import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_currency.dart';

/// Currency preference: SharedPreferences cache + Firestore `users/{uid}.currencyCode`.
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

  /// After sign-in: prefer Firestore value when present; otherwise push local
  /// only if the user has an explicit local preference.
  Future<void> syncWithCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final remote = doc.data()?[firestoreField] as String?;

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
    } catch (_) {
      // Keep local preference if cloud sync fails.
    }
  }

  Future<void> _writeToCloud(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {firestoreField: code},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Local preference is already saved.
    }
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
