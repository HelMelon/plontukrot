import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/currency/app_currency_controller.dart';
import '../core/locale/app_locale_controller.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> createUserDocument() async {
    final user = FirebaseAuth.instance.currentUser!;

    final userDoc = _firestore.collection('users').doc(user.uid);

    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'name': user.displayName,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'localeCode': AppLocaleController.instance.preferenceCode,
        'currencyCode': AppCurrencyController.instance.currency.code,
      });
    }
  }

  Stream<bool> watchUserDocumentExists() {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
