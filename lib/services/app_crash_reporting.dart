import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin Crashlytics wrapper: mobile only (no-op on web).
///
/// Collection is enabled outside debug builds. Use [recordError] for caught
/// failures (startup, auth, storage) so they appear in the Firebase console.
class AppCrashReporting {
  AppCrashReporting._();

  static final AppCrashReporting instance = AppCrashReporting._();

  bool get _supported => !kIsWeb;

  /// Call once after [Firebase.initializeApp].
  Future<void> install() async {
    if (!_supported) return;

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> setUserId(String? uid) async {
    if (!_supported) return;
    final trimmed = uid?.trim();
    await FirebaseCrashlytics.instance.setUserIdentifier(
      (trimmed == null || trimmed.isEmpty) ? '' : trimmed,
    );
  }

  Future<void> log(String message) async {
    if (!_supported) return;
    await FirebaseCrashlytics.instance.log(message);
  }

  Future<void> setCustomKey(String key, Object value) async {
    if (!_supported) return;
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Non-fatal by default — use for caught failures the UI already handles.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    bool printDetails = true,
  }) async {
    if (!_supported) {
      if (printDetails && kDebugMode) {
        debugPrint('CrashReporting(web noop): $reason $error');
      }
      return;
    }

    await FirebaseCrashlytics.instance.recordError(
      error,
      stack ?? StackTrace.current,
      reason: reason,
      fatal: fatal,
      printDetails: printDetails,
    );
  }
}
