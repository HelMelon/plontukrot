import 'package:flutter/foundation.dart';

import '../../services/api_client.dart';
import '../../services/api_exception.dart';
import '../../services/auth_service.dart';
import '../../services/token_store.dart';

/// Server-resolved feature flags. In-memory only — never persisted on device.
enum FeatureFlag {
  friends('friends', defaultEnabled: true),
  wishList('wish_list', defaultEnabled: true),
  finances('finances', defaultEnabled: true),
  propagations('propagations', defaultEnabled: true),
  archive('archive', defaultEnabled: true),
  genusCare('genus_care', defaultEnabled: true),
  soilSensors('soil_sensors', defaultEnabled: false),
  telegramAlerts('telegram_alerts', defaultEnabled: false),
  balcony('balcony', defaultEnabled: false),
  fertilizingReminders('fertilizing_reminders', defaultEnabled: true),
  bulkActions('bulk_actions', defaultEnabled: true);

  const FeatureFlag(this.key, {required this.defaultEnabled});

  final String key;
  final bool defaultEnabled;
}

/// Fetches [GET /features] and exposes flags to the UI.
///
/// Values live only in memory. Call [refresh] after sign-in; [clear] on logout.
class FeatureFlagsController extends ChangeNotifier {
  FeatureFlagsController._();

  static final FeatureFlagsController instance = FeatureFlagsController._();

  final ApiClient _api = ApiClient.instance;
  final Map<String, bool> _flags = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  bool isEnabled(FeatureFlag flag) {
    final value = _flags[flag.key];
    if (value != null) return value;
    return flag.defaultEnabled;
  }

  void _applyMap(Map<dynamic, dynamic> raw) {
    _flags
      ..clear()
      ..addEntries(
        FeatureFlag.values.map((flag) {
          final value = raw[flag.key];
          final enabled = value is bool ? value : flag.defaultEnabled;
          return MapEntry(flag.key, enabled);
        }),
      );
    _loaded = true;
  }

  Future<void> refresh() async {
    final token = TokenStore.instance.token;
    if (token == null || token.isEmpty || AuthService().currentUser == null) {
      clear();
      return;
    }
    try {
      final raw = await _api.get('/features');
      if (raw is! Map) {
        clear();
        return;
      }
      _applyMap(raw);
      notifyListeners();
    } on ApiException {
      if (!_loaded) {
        _flags.clear();
        notifyListeners();
      }
    } catch (_) {
      if (!_loaded) {
        _flags.clear();
        notifyListeners();
      }
    }
  }

  void clear() {
    if (_flags.isEmpty && !_loaded) return;
    _flags.clear();
    _loaded = false;
    notifyListeners();
  }
}
