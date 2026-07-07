import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();

      provider.addScope('email');
      provider.addScope('profile');

      final credential = await _auth.signInWithPopup(provider);

      await FirestoreService().createUserDocument();

      return credential;
    }

    await _initializeGoogleSignIn();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-id-token-null',
        message: 'Google did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    await FirestoreService().createUserDocument();

    return userCredential;
  }

  Future<void> signOut() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _initializeGoogleSignIn();
      await _googleSignIn.signOut();
    }

    await _auth.signOut();
  }
}
