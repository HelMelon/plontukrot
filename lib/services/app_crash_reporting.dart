import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Local persistent error reporting and diagnostics logger.
class AppCrashReporting {
  AppCrashReporting._();

  static final AppCrashReporting instance = AppCrashReporting._();

  static const int _maxInMemoryEntries = 200;
  static const int _maxLogFileBytes = 512 * 1024; // 512 KB
  static const int _trimmedLogFileBytes = 256 * 1024; // 256 KB

  final ListQueue<String> _inMemoryLogs = ListQueue<String>(_maxInMemoryEntries);
  File? _logFile;
  bool _initialized = false;
  String? _userId;

  Future<void> install() async {
    await _initLogFile();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      final message = details.exceptionAsString();
      final stack = details.stack;
      unawaited(
        recordError(
          message,
          stack,
          reason: 'flutter_uncaught_error',
          fatal: true,
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        recordError(
          error,
          stack,
          reason: 'platform_uncaught_error',
          fatal: true,
        ),
      );
      return true;
    };

    await log('AppCrashReporting installed');
  }

  Future<void> _initLogFile() async {
    if (kIsWeb || _initialized) return;
    try {
      Directory? dir;
      try {
        dir = await getApplicationSupportDirectory();
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }
      _logFile = File('${dir.path}/app_errors.log');
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppCrashReporting: failed to init log file: $e');
      }
    }
  }

  Future<void> setUserId(String? uid) async {
    _userId = uid;
    await log('User session: ${uid ?? "(signed out)"}');
  }

  Future<void> log(String message) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final entry = '[$timestamp] [INFO] [user: ${_userId ?? "anon"}] $message';
    _appendEntry(entry);
    if (kDebugMode) {
      debugPrint('CrashReporting: $message');
    }
  }

  Future<void> setCustomKey(String key, Object value) async {
    await log('key $key=$value');
  }

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    bool printDetails = true,
  }) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final level = fatal ? 'FATAL' : 'ERROR';
    final reasonPart = reason != null ? ' [$reason]' : '';
    final userPart = ' [user: ${_userId ?? "anon"}]';
    final buffer = StringBuffer();
    buffer.writeln('[$timestamp] [$level]$userPart$reasonPart $error');
    if (stack != null) {
      buffer.writeln(stack.toString().trim());
    }
    final formatted = buffer.toString().trimRight();

    _appendEntry(formatted);

    if (printDetails && kDebugMode) {
      debugPrint('CrashReporting($reason): $error');
      if (stack != null) debugPrint('$stack');
    }
  }

  void _appendEntry(String entry) {
    if (_inMemoryLogs.length >= _maxInMemoryEntries) {
      _inMemoryLogs.removeFirst();
    }
    _inMemoryLogs.add(entry);

    if (!kIsWeb && _logFile != null) {
      unawaited(_writeToFile(entry));
    }
  }

  Future<void> _writeToFile(String entry) async {
    try {
      final file = _logFile;
      if (file == null) return;
      await file.writeAsString('$entry\n\n', mode: FileMode.append, flush: false);

      if (await file.length() > _maxLogFileBytes) {
        await _trimLogFile(file);
      }
    } catch (_) {
      // Avoid throwing from logging
    }
  }

  Future<void> _trimLogFile(File file) async {
    try {
      final content = await file.readAsString();
      if (content.length > _trimmedLogFileBytes) {
        final keep = content.substring(content.length - _trimmedLogFileBytes);
        await file.writeAsString('[...trimmed earlier logs...]\n$keep');
      }
    } catch (_) {}
  }

  /// Get recent logs (from memory or file)
  Future<String> getRecentLogs() async {
    if (!kIsWeb && _logFile != null && await _logFile!.exists()) {
      try {
        return await _logFile!.readAsString();
      } catch (_) {}
    }
    return _inMemoryLogs.join('\n\n');
  }

  /// Get the log file path if on disk
  Future<String?> getLogFilePath() async {
    if (!kIsWeb && _logFile != null) {
      return _logFile!.path;
    }
    return null;
  }

  /// Clear stored logs
  Future<void> clearLogs() async {
    _inMemoryLogs.clear();
    if (!kIsWeb && _logFile != null && await _logFile!.exists()) {
      try {
        await _logFile!.writeAsString('');
      } catch (_) {}
    }
  }
}

