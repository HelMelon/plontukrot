import '../core/privacy/privacy_constants.dart';
import '../models/collection_visibility.dart';
import '../models/model_helpers.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import 'plant_service.dart';
import 'rest_stream.dart';

/// Snapshot of the signed-in user's profile (`GET /auth/me`).
class UserProfileDoc {
  final String? name;
  final String? email;
  final DateTime? personalDataConsentAt;
  final CollectionVisibility collectionVisibility;

  const UserProfileDoc({
    this.name,
    this.email,
    this.personalDataConsentAt,
    this.collectionVisibility = CollectionVisibility.friends,
  });

  bool get hasPersonalDataConsent => personalDataConsentAt != null;

  factory UserProfileDoc.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const UserProfileDoc();
    }
    return UserProfileDoc(
      name: readString(data, 'name')?.trim(),
      email: readString(data, 'email')?.trim(),
      personalDataConsentAt: readDate(data, kPersonalDataConsentAtField) ??
          readDate(data, 'personalDataConsentAt'),
      collectionVisibility: CollectionVisibility.fromCode(
        readString(data, 'collectionVisibility'),
      ),
    );
  }
}

class UserProfileService {
  final ApiClient _api = ApiClient.instance;

  String get uid => AuthService().requireUid;

  Future<Map<String, dynamic>> fetchMe() async {
    return jsonMap(await _api.get('/auth/me'));
  }

  /// Ensures profile extras after login/register. User row already exists.
  Future<void> createUserDocument({
    bool recordConsent = false,
    String? displayName,
  }) async {
    final json = await fetchMe();
    if (recordConsent && readDate(json, kPersonalDataConsentAtField) == null) {
      await recordPersonalDataConsent();
    }
  }

  Future<void> recordPersonalDataConsent() async {
    try {
      await _api.patch('/auth/me', body: {
        'personal_data_consent_at': isoDate(DateTime.now()),
      });
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> patchProfile(Map<String, dynamic> body) async {
    try {
      await _api.patch('/auth/me', body: body);
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Stream<UserProfileDoc> watchUserProfile() {
    return restPollStream(() async {
      return UserProfileDoc.fromMap(await fetchMe());
    });
  }

  Stream<bool> watchUserDocumentExists() {
    return watchUserProfile().map((profile) => profile.email != null);
  }

  Stream<bool> watchHasPersonalDataConsent() {
    return watchUserProfile().map((profile) => profile.hasPersonalDataConsent);
  }

  Future<void> deleteAllUserData() async {
    await PlantService().deleteAllUserPlants();
    try {
      await _api.delete('/auth/me');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }
}
