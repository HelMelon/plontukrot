import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/core/privacy/device_consent_store.dart';
import 'package:plontukrot/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceConsentStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      DeviceConsentStore.instance.resetCache();
    });

    test('defaults to false when empty', () async {
      expect(await DeviceConsentStore.instance.isAccepted(), isFalse);
    });

    test('remembers acceptance', () async {
      await DeviceConsentStore.instance.rememberAccepted();
      expect(await DeviceConsentStore.instance.isAccepted(), isTrue);
    });

    test('clears acceptance', () async {
      await DeviceConsentStore.instance.rememberAccepted();
      expect(await DeviceConsentStore.instance.isAccepted(), isTrue);

      await DeviceConsentStore.instance.clear();
      expect(await DeviceConsentStore.instance.isAccepted(), isFalse);
    });
  });

  group('UserProfileDoc personal data consent parsing', () {
    test('parses snake_case personal_data_consent_at', () {
      final doc = UserProfileDoc.fromMap({
        'name': 'Test',
        'email': 'test@example.com',
        'personal_data_consent_at': '2026-08-21T10:00:00.000Z',
      });
      expect(doc.hasPersonalDataConsent, isTrue);
      expect(doc.personalDataConsentAt, isNotNull);
    });

    test('parses camelCase personalDataConsentAt fallback', () {
      final doc = UserProfileDoc.fromMap({
        'name': 'Test',
        'email': 'test@example.com',
        'personalDataConsentAt': '2026-08-21T10:00:00.000Z',
      });
      expect(doc.hasPersonalDataConsent, isTrue);
      expect(doc.personalDataConsentAt, isNotNull);
    });

    test('handles null consent', () {
      final doc = UserProfileDoc.fromMap({
        'name': 'Test',
        'email': 'test@example.com',
      });
      expect(doc.hasPersonalDataConsent, isFalse);
      expect(doc.personalDataConsentAt, isNull);
    });
  });
}
