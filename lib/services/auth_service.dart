import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import 'app_crash_reporting.dart';
import 'firestore_service.dart';

/// User-facing category for Google / Firebase Auth failures.
enum AuthFailureKind {
  /// User dismissed the account picker / popup — usually no snackbar.
  cancelled,

  /// Offline or network failure (including offline disguised as cancel/reauth).
  network,

  /// Google returned no ID token.
  missingIdToken,

  /// Anything else — show a generic retry message.
  unknown,
}

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

  /// Maps a thrown auth error to a UI category (no raw exception text).
  static AuthFailureKind classifyFailure(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
        case 'web-context-cancelled':
          return AuthFailureKind.cancelled;
        case 'network-request-failed':
          return AuthFailureKind.network;
        case 'google-id-token-null':
          return AuthFailureKind.missingIdToken;
      }
    }

    if (error is GoogleSignInException) {
      final description = (error.description ?? '').toLowerCase();
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          // Offline sign-in often surfaces as canceled + "Account reauth failed".
          if (_looksLikeNetworkFailure(description)) {
            return AuthFailureKind.network;
          }
          return AuthFailureKind.cancelled;
        case GoogleSignInExceptionCode.uiUnavailable:
          return AuthFailureKind.cancelled;
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
        case GoogleSignInExceptionCode.userMismatch:
        case GoogleSignInExceptionCode.unknownError:
          break;
      }
    }

    if (error is SocketException) {
      return AuthFailureKind.network;
    }

    final message = error.toString().toLowerCase();
    if (_looksLikeNetworkFailure(message)) {
      return AuthFailureKind.network;
    }
    if (message.contains('popup-closed-by-user') ||
        message.contains('cancelled-popup-request') ||
        message.contains('web-context-cancelled')) {
      return AuthFailureKind.cancelled;
    }
    if (message.contains('canceled') || message.contains('cancelled')) {
      if (_looksLikeNetworkFailure(message) || message.contains('reauth')) {
        return AuthFailureKind.network;
      }
      return AuthFailureKind.cancelled;
    }
    if (message.contains('google-id-token-null')) {
      return AuthFailureKind.missingIdToken;
    }

    return AuthFailureKind.unknown;
  }

  static bool _looksLikeNetworkFailure(String lowercased) {
    return lowercased.contains('network') ||
        lowercased.contains('socket') ||
        lowercased.contains('failed host lookup') ||
        lowercased.contains('connection abort') ||
        lowercased.contains('connection reset') ||
        lowercased.contains('connection refused') ||
        lowercased.contains('timed out') ||
        lowercased.contains('timeout') ||
        lowercased.contains('offline') ||
        lowercased.contains('reauth failed') ||
        lowercased.contains('account reauth');
  }

  /// [recordConsent] writes `personalDataConsentAt` on the user document.
  Future<void> signInWithGoogle({bool recordConsent = false}) async {
    try {
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
    } catch (error, stack) {
      if (classifyFailure(error) != AuthFailureKind.cancelled) {
        await AppCrashReporting.instance.recordError(
          error,
          stack,
          reason: 'auth_sign_in_failed',
        );
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _initializeGoogleSignIn();
      await _googleSignIn.signOut();
    }

    await _auth.signOut();
    await AppCrashReporting.instance.setUserId(null);
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
    try {
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

      await AppCrashReporting.instance.setUserId(null);
    } catch (error, stack) {
      if (classifyFailure(error) != AuthFailureKind.cancelled) {
        await AppCrashReporting.instance.recordError(
          error,
          stack,
          reason: 'auth_delete_account_failed',
        );
      }
      rethrow;
    }
  }
}
