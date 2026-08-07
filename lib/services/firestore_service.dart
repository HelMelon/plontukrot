import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/currency/app_currency_controller.dart';
import '../core/locale/app_locale_controller.dart';
import '../core/privacy/privacy_constants.dart';
import 'plant_service.dart';
import 'storage_service.dart';

/// Snapshot of the signed-in user's Firestore profile document.
class UserProfileDoc {
  final String? name;
  final String? email;
  final DateTime? personalDataConsentAt;

  const UserProfileDoc({
    this.name,
    this.email,
    this.personalDataConsentAt,
  });

  bool get hasPersonalDataConsent => personalDataConsentAt != null;

  factory UserProfileDoc.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const UserProfileDoc();
    }
    final rawConsent = data[kPersonalDataConsentAtField];
    DateTime? consentAt;
    if (rawConsent is Timestamp) {
      consentAt = rawConsent.toDate();
    } else if (rawConsent is DateTime) {
      consentAt = rawConsent;
    }
    return UserProfileDoc(
      name: (data['name'] as String?)?.trim(),
      email: (data['email'] as String?)?.trim(),
      personalDataConsentAt: consentAt,
    );
  }
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(uid);

  Future<void> createUserDocument({bool recordConsent = false}) async {
    final user = FirebaseAuth.instance.currentUser!;

    final userDoc = _userDoc;
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'name': user.displayName,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'localeCode': AppLocaleController.instance.preferenceCode,
        'currencyCode': AppCurrencyController.instance.currency.code,
        if (recordConsent)
          kPersonalDataConsentAtField: FieldValue.serverTimestamp(),
      });
      return;
    }

    if (recordConsent) {
      await recordPersonalDataConsent();
    }
  }

  Future<void> recordPersonalDataConsent() async {
    await _userDoc.set({
      kPersonalDataConsentAtField: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<UserProfileDoc> watchUserProfile() {
    return _userDoc.snapshots().map(
      (snapshot) => UserProfileDoc.fromMap(snapshot.data()),
    );
  }

  Stream<bool> watchUserDocumentExists() {
    return _userDoc.snapshots().map((snapshot) => snapshot.exists);
  }

  Stream<bool> watchHasPersonalDataConsent() {
    return watchUserProfile().map((profile) => profile.hasPersonalDataConsent);
  }

  /// Deletes every document under `users/{uid}` plus Storage plant images.
  /// Does not delete the Auth user — call [AuthService.deleteAccount] for that.
  Future<void> deleteAllUserData() async {
    final plantService = PlantService();
    await plantService.deleteAllUserPlants();

    final topLevel = <String>[
      'propagations',
      'fertilizers',
      'fertilizerComponents',
      'soils',
      'components',
      'wishList',
      'financeEntries',
    ];

    for (final name in topLevel) {
      final col = _userDoc.collection(name);
      if (name == 'propagations') {
        await _deletePropagationsWithHistory(col);
      } else {
        await _deleteQueryInBatches(col);
      }
    }

    await StorageService().deleteAllUserPlantImages();
    await _userDoc.delete();
  }

  Future<void> _deletePropagationsWithHistory(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    while (true) {
      final snapshot = await col.limit(50).get();
      if (snapshot.docs.isEmpty) break;
      for (final doc in snapshot.docs) {
        await _deleteQueryInBatches(doc.reference.collection('stageHistory'));
        await doc.reference.delete();
      }
      if (snapshot.docs.length < 50) break;
    }
  }

  Future<void> _deleteQueryInBatches(
    Query<Map<String, dynamic>> query, {
    int pageSize = 200,
  }) async {
    while (true) {
      final snapshot = await query.limit(pageSize).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < pageSize) break;
    }
  }
}
