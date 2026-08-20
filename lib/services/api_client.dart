import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'api_refresh.dart';
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
    } on SocketException {
      rethrow;
    } on TimeoutException {
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
      throw ApiException(
        response.statusCode,
        _extractMessage(response),
        body: response.body,
      );
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

String isoDate(DateTime value) => value.toUtc().toIso8601String();

String? isoDateOrNull(DateTime? value) =>
    value == null ? null : isoDate(value);
