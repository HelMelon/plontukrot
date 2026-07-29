import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  Future<void> _initializeGoogleSignIn() async {
    if (_initialized) return;

    await _googleSignIn.initialize();

    _initialized = true;
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      photoUrl: user.photoURL,
    );
  }

  Stream<AppUser?> watchAuthState() {
    return _auth.authStateChanges().map(_mapUser);
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();

      provider.addScope('email');
      provider.addScope('profile');

      await _auth.signInWithPopup(provider);

      await FirestoreService().createUserDocument();
      return;
    }

    await _initializeGoogleSignIn();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-id-token-null',
        message: 'Google не вернул ID-токен.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    await _auth.signInWithCredential(credential);

    await FirestoreService().createUserDocument();
  }

  Future<void> signOut() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _initializeGoogleSignIn();
      await _googleSignIn.signOut();
    }

    await _auth.signOut();
  }
}
