import 'package:shared_preferences/shared_preferences.dart';

/// Device-local cache of personal-data consent (login checkbox).
///
/// Firestore `personalDataConsentAt` remains the account source of truth;
/// this only skips re-ticking the login checkbox on the same browser/device.
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
