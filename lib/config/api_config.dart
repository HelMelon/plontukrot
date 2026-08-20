/// REST backend base URL.
///
/// Override at build time:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
/// (Android emulator → host machine). Default is the production server.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://91.149.167.7:8000',
  );
}
