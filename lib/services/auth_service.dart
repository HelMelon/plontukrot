import 'dart:async';
import 'dart:io';

import '../core/privacy/device_consent_store.dart';
import '../models/app_user.dart';
import '../models/model_helpers.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'app_crash_reporting.dart';
import 'user_profile_service.dart';
import 'token_store.dart';

/// User-facing category for auth failures.
enum AuthFailureKind {
  /// User dismissed a flow — usually no snackbar.
  cancelled,

  /// Offline or network failure.
  network,

  /// Google returned no ID token (unused after Google sign-in removal).
  missingIdToken,

  /// Malformed email address.
  invalidEmail,

  /// Password does not meet strength rules.
  weakPassword,

  /// Email is already registered.
  emailAlreadyInUse,

  /// Wrong password or unknown user.
  invalidCredentials,

  /// Rate limit.
  tooManyRequests,

  /// Anything else — show a generic retry message.
  unknown,
}

/// Email/password auth against the FastAPI backend (JWT).
///
/// `AuthService()` is a singleton so [watchAuthState] is shared across the tree.
class AuthService {
  AuthService._() {
    ApiClient.instance.onUnauthorized = () async {
      await _clearSession();
    };
  }

  static final AuthService instance = AuthService._();

  factory AuthService() => instance;

  final ApiClient _api = ApiClient.instance;
  final StreamController<AppUser?> _authChanges =
      StreamController<AppUser?>.broadcast();

  AppUser? _user;
  String? _email;

  AppUser? get currentUser => _user;

  String? get currentUserEmail => _email ?? _user?.email;

  String get requireUid {
    final uid = _user?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Not signed in');
    }
    return uid;
  }

  /// Backend v1 has no email verification; always false.
  bool get needsEmailVerification => false;

  /// Password reauth is used for account deletion.
  bool get requiresPasswordToDelete => currentUser != null;

  Stream<AppUser?> watchAuthState() async* {
    yield _user;
    yield* _authChanges.stream;
  }

  Future<void> restoreSession() async {
    await TokenStore.instance.load();
    if (!TokenStore.instance.hasToken) {
      _emit(null);
      return;
    }
    try {
      await _loadMe();
    } on ApiException catch (error) {
      if (error.isUnauthorized || error.isNotFound) {
        await _clearSession();
        return;
      }
      rethrow;
    } catch (_) {
      // Keep the JWT if the backend is unreachable.
      _emit(null);
    }
  }

  Future<void> _loadMe() async {
    final json = jsonMap(await _api.get('/auth/me'));
    final id = readString(json, 'id') ?? '';
    _email = readString(json, 'email');
    _emit(
      AppUser(
        uid: id,
        email: _email,
        name: readString(json, 'name'),
        photoUrl: readString(json, 'photoUrl'),
      ),
    );
  }

  void _emit(AppUser? user) {
    _user = user;
    if (user == null) _email = null;
    if (!_authChanges.isClosed) {
      _authChanges.add(user);
    }
  }

  Future<void> _clearSession() async {
    await TokenStore.instance.clear();
    _emit(null);
    await AppCrashReporting.instance.setUserId(null);
  }

  static AuthFailureKind classifyFailure(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 409) return AuthFailureKind.emailAlreadyInUse;
      if (error.statusCode == 401) return AuthFailureKind.invalidCredentials;
      if (error.statusCode == 422 || error.statusCode == 400) {
        final lower = error.message.toLowerCase();
        if (lower.contains('email')) return AuthFailureKind.invalidEmail;
        if (lower.contains('password')) return AuthFailureKind.weakPassword;
        return AuthFailureKind.invalidCredentials;
      }
      if (error.statusCode == 429) return AuthFailureKind.tooManyRequests;
    }
    if (error is SocketException) return AuthFailureKind.network;
    final message = error.toString().toLowerCase();
    if (_looksLikeNetworkFailure(message)) return AuthFailureKind.network;
    return AuthFailureKind.unknown;
  }

  static bool _looksLikeNetworkFailure(String lowercased) {
    return lowercased.contains('network') ||
        lowercased.contains('socket') ||
        lowercased.contains('failed host lookup') ||
        lowercased.contains('connection abort') ||
        lowercased.contains('connection reset') ||
        lowercased.contains('connection refused') ||
        lowercased.contains('timed out') ||
        lowercased.contains('timeout') ||
        lowercased.contains('clientexception') ||
        lowercased.contains('httpexception') ||
        lowercased.contains('failed to connect') ||
        lowercased.contains('offline');
  }

  Future<void> _recordAuthError(
    Object error,
    StackTrace stack,
    String reason,
  ) async {
    if (classifyFailure(error) != AuthFailureKind.cancelled) {
      await AppCrashReporting.instance.recordError(
        error,
        stack,
        reason: reason,
      );
    }
  }

  Future<void> _persistToken(dynamic json) async {
    final map = jsonMap(json);
    final token = readString(map, 'accessToken') ??
        readString(map, 'access_token') ??
        '';
    if (token.isEmpty) {
      throw StateError('Missing access_token');
    }
    await TokenStore.instance.save(token);
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    bool recordConsent = false,
  }) async {
    final trimmedName = displayName.trim();
    final trimmedEmail = email.trim();
    try {
      await _persistToken(
        await _api.post(
          '/auth/register',
          body: {
            'email': trimmedEmail,
            'password': password,
            if (trimmedName.isNotEmpty) 'name': trimmedName,
          },
          ping: false,
        ),
      );
      await _loadMe();
      await UserProfileService().createUserDocument(
        recordConsent: recordConsent,
        displayName: trimmedName,
      );
    } catch (error, stack) {
      await _recordAuthError(error, stack, 'auth_register_failed');
      rethrow;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
    bool recordConsent = false,
  }) async {
    try {
      await _persistToken(
        await _api.post(
          '/auth/login',
          body: {
            'email': email.trim(),
            'password': password,
          },
          ping: false,
        ),
      );
      await _loadMe();
      await UserProfileService().createUserDocument(recordConsent: recordConsent);
    } catch (error, stack) {
      await _recordAuthError(error, stack, 'auth_email_sign_in_failed');
      rethrow;
    }
  }

  /// Kept so older call sites compile; Google sign-in is removed.
  Future<void> signInWithGoogle({bool recordConsent = false}) async {
    throw UnsupportedError('Google sign-in is no longer available');
  }

  Future<void> reloadCurrentUser() async {
    if (!TokenStore.instance.hasToken) return;
    await _loadMe();
  }

  Future<void> sendEmailVerification() async {
    // Email verification is deferred on the FastAPI backend (ADR-033).
  }

  Future<void> signOut() async {
    await _clearSession();
  }

  /// Deletes account data when the backend supports it, then signs out.
  Future<void> deleteAccount({String? password}) async {
    try {
      if (currentUser == null) {
        throw StateError('No signed-in user');
      }
      if (password == null || password.isEmpty) {
        throw ApiException(400, 'missing-password');
      }
      // Re-check credentials before destructive delete.
      await _api.post(
        '/auth/login',
        body: {
          'email': currentUserEmail ?? '',
          'password': password,
        },
        ping: false,
      );
      try {
        await UserProfileService().deleteAllUserData();
      } catch (_) {
        // Best-effort wipe; still sign out.
      }
      try {
        await _api.delete('/auth/me');
      } on ApiException catch (error) {
        if (!error.isNotFound) rethrow;
      }
      await DeviceConsentStore.instance.clear();
      await _clearSession();
    } catch (error, stack) {
      await _recordAuthError(error, stack, 'auth_delete_account_failed');
      rethrow;
    }
  }
}
