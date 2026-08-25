import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'api_refresh.dart';
import 'app_crash_reporting.dart';
import 'token_store.dart';

/// Thin REST client for the FastAPI backend.
///
/// Attaches `Authorization: Bearer <JWT>` when a token is stored.
/// On HTTP 401, clears the token and invokes [onUnauthorized] (logout).
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  factory ApiClient() => instance;

  final http.Client _http = http.Client();

  /// Set by [AuthService] so a stale JWT signs the user out.
  Future<void> Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalized').replace(
      queryParameters: query,
    );
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      // Tell the backend the client's UTC offset (minutes) so any server-side
      // date math can stay in the user's local day. E.g. UTC+3 → "+180".
      'X-Timezone-Offset': deviceUtcOffsetMinutes().toString(),
    };
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    final token = TokenStore.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
  }) {
    return request('GET', path, query: query);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? query,
    bool ping = true,
  }) {
    return request('POST', path, body: body, query: query, pingOnSuccess: ping);
  }

  /// Upload a binary file as multipart/form-data and return parsed JSON.
  ///
  /// The body is expected to be a map of string fields (values must be
  /// strings). The `fileField` names the file part. Attaches the bearer token.
  Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required String filename,
    required List<int> fileBytes,
    Map<String, String> fields = const {},
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers());
    for (final entry in fields.entries) {
      request.fields[entry.key] = entry.value;
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: filename,
      ),
    );
    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);
    if (kDebugMode) {
      debugPrint('[ApiClient] POST Multipart $path -> status ${response.statusCode}, body: ${response.body}');
    }
    if (response.statusCode == 401) {
      await TokenStore.instance.clear();
      final callback = onUnauthorized;
      if (callback != null) {
        await callback();
      }
      throw ApiException(401, _extractMessage(response), body: response.body);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final exception = ApiException(
        response.statusCode,
        _extractMessage(response),
        body: response.body,
      );
      unawaited(
        AppCrashReporting.instance.recordError(
          exception,
          StackTrace.current,
          reason: 'api_multipart_http_${response.statusCode}: $path',
        ),
      );
      throw exception;
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, String>? query,
    bool ping = true,
  }) {
    return request('PATCH', path, body: body, query: query, pingOnSuccess: ping);
  }

  Future<dynamic> put(String path, {Object? body, bool ping = true}) {
    return request('PUT', path, body: body, pingOnSuccess: ping);
  }

  Future<dynamic> delete(String path, {bool ping = true}) {
    return request('DELETE', path, pingOnSuccess: ping);
  }

  Future<dynamic> request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool pingOnSuccess = false,
  }) async {
    final uri = _uri(path, query);
    final encoded = body == null ? null : jsonEncode(body);
    final headers = _headers(jsonBody: encoded != null);

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _http.get(uri, headers: headers);
        case 'POST':
          response = await _http.post(uri, headers: headers, body: encoded);
        case 'PATCH':
          response = await _http.patch(uri, headers: headers, body: encoded);
        case 'PUT':
          response = await _http.put(uri, headers: headers, body: encoded);
        case 'DELETE':
          response = await _http.delete(uri, headers: headers);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } on SocketException catch (error, stack) {
      unawaited(
        AppCrashReporting.instance.recordError(
          error,
          stack,
          reason: 'network_socket_error: $method $path',
        ),
      );
      rethrow;
    } on TimeoutException catch (error, stack) {
      unawaited(
        AppCrashReporting.instance.recordError(
          error,
          stack,
          reason: 'network_timeout_error: $method $path',
        ),
      );
      rethrow;
    }

    if (response.statusCode == 401) {
      final isAuthForm = path.startsWith('/auth/login') ||
          path.startsWith('/auth/register');
      if (!isAuthForm) {
        await TokenStore.instance.clear();
        final callback = onUnauthorized;
        if (callback != null) {
          await callback();
        }
      }
      throw ApiException(401, _extractMessage(response), body: response.body);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final exception = ApiException(
        response.statusCode,
        _extractMessage(response),
        body: response.body,
      );
      if (response.statusCode >= 500 ||
          response.statusCode == 400 ||
          response.statusCode == 422) {
        unawaited(
          AppCrashReporting.instance.recordError(
            exception,
            StackTrace.current,
            reason: 'api_http_${response.statusCode}: $method $path',
          ),
        );
      }
      throw exception;
    }

    if (pingOnSuccess) {
      ApiRefresh.instance.ping();
    }

    if (response.statusCode == 204 || response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body);
  }

  String _extractMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail != null) return detail.toString();
      }
    } catch (_) {
      // Fall through to status text.
    }
    if (response.body.isNotEmpty) return response.body;
    return 'HTTP ${response.statusCode}';
  }
}

/// Convert a JSON array into a list of maps.
List<Map<String, dynamic>> jsonMapList(dynamic json) {
  if (json is! List) return const [];
  return json
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Map<String, dynamic> jsonMap(dynamic json) {
  if (json is Map<String, dynamic>) return json;
  if (json is Map) return Map<String, dynamic>.from(json);
  return <String, dynamic>{};
}

String isoDate(DateTime value) {
  // Date-only values (midnight local) must keep their calendar day. Converting
  // to UTC shifts them back a day for positive offsets (e.g. UTC+3 → 23rd),
  // which corrupts repotting/watering/fertilizing dates. Real timestamps with
  // a time component still serialize as UTC.
  if (value.hour == 0 &&
      value.minute == 0 &&
      value.second == 0 &&
      value.millisecond == 0) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-${d}T00:00:00';
  }
  return value.toUtc().toIso8601String();
}

String? isoDateOrNull(DateTime? value) =>
    value == null ? null : isoDate(value);

/// The device's current UTC offset in minutes (e.g. UTC+3 → 180, UTC-5 → -300).
///
/// Sent to the backend as `X-Timezone-Offset` so any server-side date math
/// stays in the user's local day. Uses the local [DateTime]'s offset, which
/// already reflects DST.
int deviceUtcOffsetMinutes() {
  final now = DateTime.now();
  return now.timeZoneOffset.inMinutes;
}
