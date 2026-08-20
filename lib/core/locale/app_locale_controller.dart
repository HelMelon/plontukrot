import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/model_helpers.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';

/// Locale preference: SharedPreferences cache + `GET/PATCH /auth/me`.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  static const _prefsKey = 'app_locale_code';
  static const firestoreField = 'localeCode';
  static const systemCode = 'system';

  static const supportedLanguageCodes = ['en', 'ru', 'de', 'fr'];

  SharedPreferences? _prefs;
  String _preference = systemCode;

  Locale? get localeOverride {
    if (_preference == systemCode) return null;
    return Locale(_preference);
  }

  String get preferenceCode => _preference;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_prefsKey);
    if (stored != null && _isValidCode(stored)) {
      _preference = stored;
    }
  }

  Future<void> setPreference(String code) async {
    if (!_isValidCode(code)) return;

    _preference = code;
    await _prefs?.setString(_prefsKey, code);
    await _writeToCloud(code);
    _applyIntlLocale();
    notifyListeners();
  }

  Future<void> syncWithCloud() async {
    if (AuthService().currentUser == null) return;

    try {
      final json = await UserProfileService().fetchMe();
      final remote = readString(json, firestoreField);

      if (remote != null && _isValidCode(remote)) {
        if (remote == _preference) return;
        _preference = remote;
        await _prefs?.setString(_prefsKey, remote);
        _applyIntlLocale();
        notifyListeners();
        return;
      }

      final hasLocal = _prefs?.containsKey(_prefsKey) ?? false;
      if (hasLocal) {
        await _writeToCloud(_preference);
      }
    } catch (_) {}
  }

  Future<void> _writeToCloud(String code) async {
    if (AuthService().currentUser == null) return;
    try {
      await UserProfileService().patchProfile({'locale_code': code});
    } catch (_) {}
  }

  void _applyIntlLocale() {
    final resolved = localeOverride ??
        WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = supportedLanguageCodes.contains(resolved.languageCode)
        ? resolved.languageCode
        : 'en';
    Intl.defaultLocale = languageCode;
  }

  bool _isValidCode(String code) {
    return code == systemCode || supportedLanguageCodes.contains(code);
  }

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
