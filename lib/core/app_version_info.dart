import 'package:package_info_plus/package_info_plus.dart';

/// Cached app version from platform build metadata (`pubspec.yaml` at build time).
class AppVersionInfo {
  AppVersionInfo._();

  static PackageInfo? _cached;

  static Future<PackageInfo> load() async {
    _cached ??= await PackageInfo.fromPlatform();
    return _cached!;
  }

  /// User-visible semver without build number, e.g. `1.3.0`.
  static Future<String> versionLabel() async {
    final info = await load();
    return info.version;
  }
}
