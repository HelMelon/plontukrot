import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      });
    }
  }

  Stream<DocumentSnapshot> getUserData() {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}
