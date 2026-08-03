import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only locale preference. Not synced to Firestore.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  static const _prefsKey = 'app_locale_code';
  static const systemCode = 'system';

  static const supportedLanguageCodes = ['en', 'ru', 'de', 'fr'];

  SharedPreferences? _prefs;
  String _preference = systemCode;

  /// `null` means follow device locale (with English fallback).
  Locale? get localeOverride {
    if (_preference == systemCode) return null;
    return Locale(_preference);
  }

  String get preferenceCode => _preference;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_prefsKey);
    if (stored != null &&
        (stored == systemCode || supportedLanguageCodes.contains(stored))) {
      _preference = stored;
    }
  }

  Future<void> setPreference(String code) async {
    if (code != systemCode && !supportedLanguageCodes.contains(code)) {
      return;
    }
    _preference = code;
    await _prefs?.setString(_prefsKey, code);

    final resolved = localeOverride ??
        WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = supportedLanguageCodes.contains(resolved.languageCode)
        ? resolved.languageCode
        : 'en';
    Intl.defaultLocale = languageCode;

    notifyListeners();
  }

  /// Resolve MaterialApp locale from device locale.
  static Locale? resolveLocale(
    Locale? deviceLocale,
    Iterable<Locale> supportedLocales,
  ) {
    if (deviceLocale == null) return const Locale('en');
    for (final supported in supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) {
        return supported;
      }
    }
    return const Locale('en');
  }
}
