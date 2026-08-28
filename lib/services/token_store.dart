import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Persists the JWT issued by `POST /auth/login` and `POST /auth/register`,
/// as well as the cached profile of the authenticated user.
class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const _keyToken = 'api_access_token';
  static const _keyUid = 'auth_user_uid';
  static const _keyEmail = 'auth_user_email';
  static const _keyName = 'auth_user_name';
  static const _keyPhotoUrl = 'auth_user_photo_url';

  String? _token;
  AppUser? _cachedUser;

  String? get token => _token;
  AppUser? get cachedUser => _cachedUser;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    final uid = prefs.getString(_keyUid);
    if (uid != null && uid.isNotEmpty) {
      _cachedUser = AppUser(
        uid: uid,
        email: prefs.getString(_keyEmail),
        name: prefs.getString(_keyName),
        photoUrl: prefs.getString(_keyPhotoUrl),
      );
    } else {
      _cachedUser = null;
    }
  }

  Future<void> save(String token, {AppUser? user}) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (user != null) {
      await saveUser(user);
    }
  }

  Future<void> saveUser(AppUser user) async {
    _cachedUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, user.uid);
    if (user.email != null) {
      await prefs.setString(_keyEmail, user.email!);
    } else {
      await prefs.remove(_keyEmail);
    }
    if (user.name != null) {
      await prefs.setString(_keyName, user.name!);
    } else {
      await prefs.remove(_keyName);
    }
    if (user.photoUrl != null) {
      await prefs.setString(_keyPhotoUrl, user.photoUrl!);
    } else {
      await prefs.remove(_keyPhotoUrl);
    }
  }

  Future<void> clear() async {
    _token = null;
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUid);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhotoUrl);
  }
}
