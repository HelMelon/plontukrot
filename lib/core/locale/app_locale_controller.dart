import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale preference: SharedPreferences cache + Firestore `users/{uid}.localeCode`.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  static const _prefsKey = 'app_locale_code';
  static const firestoreField = 'localeCode';
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
