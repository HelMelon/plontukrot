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

  /// Current session mapped for UI (null when signed out).
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  Stream<AppUser?> watchAuthState() {
    return _auth.authStateChanges().map(_mapUser);
  }

  /// [recordConsent] writes `personalDataConsentAt` on the user document.
  Future<void> signInWithGoogle({bool recordConsent = false}) async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();

      provider.addScope('email');
      provider.addScope('profile');

      await _auth.signInWithPopup(provider);

      await FirestoreService().createUserDocument(recordConsent: recordConsent);
      return;
    }

    await _initializeGoogleSignIn();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-id-token-null',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    await _auth.signInWithCredential(credential);

    await FirestoreService().createUserDocument(recordConsent: recordConsent);
  }

  Future<void> signOut() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _initializeGoogleSignIn();
      await _googleSignIn.signOut();
    }

    await _auth.signOut();
  }

  Future<void> _reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      await user.reauthenticateWithPopup(provider);
      return;
    }

    await _initializeGoogleSignIn();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(code: 'google-id-token-null');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await user.reauthenticateWithCredential(credential);
  }

  /// Reauthenticates, wipes Firestore + Storage user data, then deletes Auth.
  Future<void> deleteAccount() async {
    await _reauthenticateWithGoogle();
    await FirestoreService().deleteAllUserData();

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User missing after data wipe');
    }
    await user.delete();

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await _initializeGoogleSignIn();
        await _googleSignIn.signOut();
      } catch (_) {
        // Auth user already deleted; ignore Google sign-out failures.
      }
    }
  }
}
