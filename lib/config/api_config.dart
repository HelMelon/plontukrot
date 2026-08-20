/// REST backend base URL.
///
/// Override at build time:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
/// (Android emulator → host machine). Physical device: LAN IP of the API host.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
