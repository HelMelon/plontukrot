import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT issued by `POST /auth/login` and `POST /auth/register`.
class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const _key = 'api_access_token';

  String? _token;

  String? get token => _token;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_key);
  }

  Future<void> save(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<void> clear() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
