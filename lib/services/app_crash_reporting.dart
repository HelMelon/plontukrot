import 'package:flutter/foundation.dart';

/// Local error reporting (replaces Crashlytics after Firebase removal).
class AppCrashReporting {
  AppCrashReporting._();

  static final AppCrashReporting instance = AppCrashReporting._();

  Future<void> install() async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('CrashReporting: ${details.exceptionAsString()}');
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('CrashReporting: $error\n$stack');
      }
      return true;
    };
  }

  Future<void> setUserId(String? uid) async {
    if (kDebugMode) {
      debugPrint('CrashReporting user: ${uid ?? '(signed out)'}');
    }
  }

  Future<void> log(String message) async {
    if (kDebugMode) debugPrint('CrashReporting: $message');
  }

  Future<void> setCustomKey(String key, Object value) async {
    if (kDebugMode) debugPrint('CrashReporting key $key=$value');
  }

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    bool printDetails = true,
  }) async {
    if (printDetails && kDebugMode) {
      debugPrint('CrashReporting($reason): $error');
      if (stack != null) debugPrint('$stack');
    }
  }
}
