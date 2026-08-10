import 'package:shared_preferences/shared_preferences.dart';

/// Device-local cache of personal-data consent.
///
/// Firestore `personalDataConsentAt` remains the account source of truth.
/// When this flag is set, login/gate hide the consent checkbox on this device;
/// clearing happens on account deletion.
class DeviceConsentStore {
  DeviceConsentStore._();

  static final DeviceConsentStore instance = DeviceConsentStore._();

  static const prefsKey = 'personal_data_consent_accepted';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> isAccepted() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(prefsKey) ?? false;
  }

  Future<void> setAccepted(bool accepted) async {
    final prefs = await _ensurePrefs();
    if (accepted) {
      await prefs.setBool(prefsKey, true);
    } else {
      await prefs.remove(prefsKey);
    }
  }

  Future<void> rememberAccepted() => setAccepted(true);

  Future<void> clear() => setAccepted(false);
}
