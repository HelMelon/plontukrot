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

/// Snapshot of another user's flags + ban/delete state (admin API).
class AdminUserFeatures {
  final String userId;
  final Map<String, bool> flags;
  final bool banned;
  final String? banReason;
  final bool deleted;
  final String? deleteReason;
  final DateTime? deletedAt;

  const AdminUserFeatures({
    required this.userId,
    required this.flags,
    required this.banned,
    this.banReason,
    this.deleted = false,
    this.deleteReason,
    this.deletedAt,
  });

  bool isEnabled(FeatureFlag flag) {
    final value = flags[flag.key];
    if (value != null) return value;
    return flag.defaultEnabled;
  }

  AdminUserFeatures copyWith({
    Map<String, bool>? flags,
    bool? banned,
    String? banReason,
    bool clearBanReason = false,
    bool? deleted,
    String? deleteReason,
    DateTime? deletedAt,
    bool clearDelete = false,
  }) {
    return AdminUserFeatures(
      userId: userId,
      flags: flags ?? this.flags,
      banned: banned ?? this.banned,
      banReason: clearBanReason ? null : (banReason ?? this.banReason),
      deleted: clearDelete ? false : (deleted ?? this.deleted),
      deleteReason: clearDelete ? null : (deleteReason ?? this.deleteReason),
      deletedAt: clearDelete ? null : (deletedAt ?? this.deletedAt),
    );
  }

  factory AdminUserFeatures.fromMap(Map<String, dynamic> raw) {
    final flagsRaw = raw['flags'];
    final flags = <String, bool>{};
    if (flagsRaw is Map) {
      for (final flag in FeatureFlag.values) {
        final value = flagsRaw[flag.key];
        flags[flag.key] = value is bool ? value : flag.defaultEnabled;
      }
    } else {
      for (final flag in FeatureFlag.values) {
        flags[flag.key] = flag.defaultEnabled;
      }
    }
    final reason = raw['ban_reason'];
    final deleteReason = raw['delete_reason'];
    DateTime? deletedAt;
    final deletedAtRaw = raw['deleted_at'];
    if (deletedAtRaw is String && deletedAtRaw.isNotEmpty) {
      deletedAt = DateTime.tryParse(deletedAtRaw);
    }
    return AdminUserFeatures(
      userId: (raw['user_id'] ?? '').toString(),
      flags: flags,
      banned: raw['banned'] == true,
      banReason: reason is String && reason.trim().isNotEmpty
          ? reason.trim()
          : null,
      deleted: raw['deleted'] == true,
      deleteReason: deleteReason is String && deleteReason.trim().isNotEmpty
          ? deleteReason.trim()
          : null,
      deletedAt: deletedAt,
    );
  }
}

/// Row from admin users list / archive.
class AdminUserSummary {
  final String userId;
  final String? email;
  final String? name;
  final bool banned;
  final String? banReason;
  final bool deleted;
  final String? deleteReason;
  final DateTime? deletedAt;

  const AdminUserSummary({
    required this.userId,
    this.email,
    this.name,
    required this.banned,
    this.banReason,
    this.deleted = false,
    this.deleteReason,
    this.deletedAt,
  });

  factory AdminUserSummary.fromMap(Map<String, dynamic> raw) {
    final reason = raw['ban_reason'];
    final deleteReason = raw['delete_reason'];
    DateTime? deletedAt;
    final deletedAtRaw = raw['deleted_at'];
    if (deletedAtRaw is String && deletedAtRaw.isNotEmpty) {
      deletedAt = DateTime.tryParse(deletedAtRaw);
    }
    return AdminUserSummary(
      userId: (raw['user_id'] ?? '').toString(),
      email: raw['email'] as String?,
      name: raw['name'] as String?,
      banned: raw['banned'] == true,
      banReason: reason is String && reason.trim().isNotEmpty
          ? reason.trim()
          : null,
      deleted: raw['deleted'] == true,
      deleteReason: deleteReason is String && deleteReason.trim().isNotEmpty
          ? deleteReason.trim()
          : null,
      deletedAt: deletedAt,
    );
  }
}

/// Fetches [GET /features] and exposes flags to the UI.
///
/// Values live only in memory. Call [refresh] after sign-in; [clear] on logout.
class FeatureFlagsController extends ChangeNotifier {
  FeatureFlagsController._();

  static final FeatureFlagsController instance = FeatureFlagsController._();

  /// Same allowlist as backend `OWNER_IOT_USER_ID` — may mutate personal flags.
  static const String adminUserId = '6c5e9eaf-d146-451f-8936-2e02d8d720bd';

  static bool isAdminUid(String? uid) =>
      uid != null && uid == adminUserId;

  final ApiClient _api = ApiClient.instance;
  final Map<String, bool> _flags = {};
  bool _loaded = false;
  bool _saving = false;

  bool get isLoaded => _loaded;

  bool get isSaving => _saving;

  bool get canManageFlags =>
      isAdminUid(AuthService().currentUser?.uid);

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

  /// Persist a personal override for the signed-in owner account.
  Future<void> setFlag(FeatureFlag flag, bool enabled) async {
    if (!canManageFlags) {
      throw StateError('Feature flag admin only');
    }
    final previous = isEnabled(flag);
    _flags[flag.key] = enabled;
    _saving = true;
    notifyListeners();
    try {
      final raw = await _api.patch('/features', body: {flag.key: enabled});
      if (raw is Map) {
        _applyMap(raw);
      } else {
        _flags[flag.key] = enabled;
        _loaded = true;
      }
    } catch (_) {
      _flags[flag.key] = previous;
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<AdminUserFeatures> loadUserFeatures(String userId) async {
    final target = userId.trim();
    try {
      final raw = await _api.get('/features/admin/users/$target');
      if (raw is! Map) {
        throw ApiException(500, 'Invalid admin features response');
      }
      return AdminUserFeatures.fromMap(Map<String, dynamic>.from(raw));
    } on ApiException catch (error) {
      // Older backends / self: fall back to GET /features for current user.
      final selfId = AuthService().currentUser?.uid;
      if (error.isNotFound && selfId != null && target == selfId) {
        final raw = await _api.get('/features');
        if (raw is! Map) {
          throw ApiException(500, 'Invalid features response');
        }
        final flags = <String, bool>{};
        for (final flag in FeatureFlag.values) {
          final value = raw[flag.key];
          flags[flag.key] = value is bool ? value : flag.defaultEnabled;
        }
        return AdminUserFeatures(
          userId: target,
          flags: flags,
          banned: false,
        );
      }
      rethrow;
    }
  }

  Future<List<AdminUserSummary>> listUsers() async {
    final raw = await _api.get('/features/admin/users');
    if (raw is! List) {
      throw ApiException(500, 'Invalid admin users response');
    }
    return raw
        .whereType<Map>()
        .map((e) => AdminUserSummary.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<AdminUserSummary>> listArchivedUsers() async {
    final raw = await _api.get('/features/admin/users/archived');
    if (raw is! List) {
      throw ApiException(500, 'Invalid admin archive response');
    }
    return raw
        .whereType<Map>()
        .map((e) => AdminUserSummary.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AdminUserFeatures> setUserFlag({
    required String userId,
    required FeatureFlag flag,
    required bool enabled,
  }) async {
    final target = userId.trim();
    final selfId = AuthService().currentUser?.uid;
    try {
      final raw = await _api.patch(
        '/features/admin/users/$target',
        body: {flag.key: enabled},
      );
      if (raw is! Map) {
        throw ApiException(500, 'Invalid admin features response');
      }
      final snapshot =
          AdminUserFeatures.fromMap(Map<String, dynamic>.from(raw));
      if (selfId != null && target == selfId) {
        _applyMap(snapshot.flags);
        notifyListeners();
      }
      return snapshot;
    } on ApiException catch (error) {
      if (error.isNotFound && selfId != null && target == selfId) {
        await setFlag(flag, enabled);
        return AdminUserFeatures(
          userId: target,
          flags: Map<String, bool>.from(_flags),
          banned: false,
        );
      }
      rethrow;
    }
  }

  Future<AdminUserFeatures> banUser({
    required String userId,
    required String reason,
  }) async {
    final target = userId.trim();
    await _api.post(
      '/features/admin/users/$target/ban',
      body: {'reason': reason.trim()},
      ping: false,
    );
    return loadUserFeatures(target);
  }

  Future<AdminUserFeatures> unbanUser(String userId) async {
    final target = userId.trim();
    await _api.delete('/features/admin/users/$target/ban', ping: false);
    return loadUserFeatures(target);
  }

  Future<AdminUserFeatures> softDeleteUser({
    required String userId,
    required String reason,
  }) async {
    final target = userId.trim();
    final raw = await _api.post(
      '/features/admin/users/$target/delete',
      body: {'reason': reason.trim()},
      ping: false,
    );
    if (raw is Map) {
      return AdminUserFeatures.fromMap(Map<String, dynamic>.from(raw));
    }
    return loadUserFeatures(target);
  }

  Future<AdminUserFeatures> restoreUser(String userId) async {
    final target = userId.trim();
    final raw = await _api.delete(
      '/features/admin/users/$target/delete',
      ping: false,
    );
    if (raw is Map) {
      return AdminUserFeatures.fromMap(Map<String, dynamic>.from(raw));
    }
    return loadUserFeatures(target);
  }

  void clear() {
    if (_flags.isEmpty && !_loaded && !_saving) return;
    _flags.clear();
    _loaded = false;
    _saving = false;
    notifyListeners();
  }
}
