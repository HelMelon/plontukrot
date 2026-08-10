import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/privacy/device_consent_store.dart';
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

  /// Malformed email address.
  invalidEmail,

  /// Password does not meet Firebase strength rules.
  weakPassword,

  /// Email is already registered.
  emailAlreadyInUse,

  /// Wrong password, unknown user, or invalid credential.
  invalidCredentials,

  /// Firebase rate limit.
  tooManyRequests,

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

  /// Fires on sign-in/out and after [User.reload] (e.g. email verification).
  Stream<AppUser?> watchAuthState() {
    return _auth.userChanges().map(_mapUser);
  }

  bool _hasPasswordProvider(User user) {
    return user.providerData.any((info) => info.providerId == 'password');
  }

  /// Password-provider accounts must verify email before using the app.
  bool get needsEmailVerification {
    final user = _auth.currentUser;
    if (user == null) return false;
    return _hasPasswordProvider(user) && !user.emailVerified;
  }

  /// True when account deletion must reauthenticate with the account password.
  bool get requiresPasswordToDelete {
    final user = _auth.currentUser;
    return user != null && _hasPasswordProvider(user);
  }

  String? get currentUserEmail => _auth.currentUser?.email;

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
        case 'invalid-email':
          return AuthFailureKind.invalidEmail;
        case 'weak-password':
          return AuthFailureKind.weakPassword;
        case 'email-already-in-use':
          return AuthFailureKind.emailAlreadyInUse;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
        case 'missing-password':
          return AuthFailureKind.invalidCredentials;
        case 'too-many-requests':
          return AuthFailureKind.tooManyRequests;
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

  Future<void> _recordAuthError(Object error, StackTrace stack, String reason) async {
    if (classifyFailure(error) != AuthFailureKind.cancelled) {
      await AppCrashReporting.instance.recordError(
        error,
        stack,
        reason: reason,
      );
    }
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
      await _recordAuthError(error, stack, 'auth_sign_in_failed');
      rethrow;
    }
  }

  /// Creates an email/password account, optionally sets site display name,
  /// sends verification email, and seeds the Firestore profile.
  Future<void> registerWithEmail({
    required String email,
    required String password,
    String displayName = '',
    bool recordConsent = false,
  }) async {
    final trimmedName = displayName.trim();
    final trimmedEmail = email.trim();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('User missing after registration');
      }
      // Send verification before profile updates — the first send right after
      // create+updateDisplayName often never arrives; resend then works.
      await _sendEmailVerificationReliably(user, retryAfterCreate: true);
      if (trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
      }
      await FirestoreService().createUserDocument(
        recordConsent: recordConsent,
        displayName: trimmedName.isEmpty ? null : trimmedName,
      );
    } catch (error, stack) {
      await _recordAuthError(error, stack, 'auth_register_failed');
      rethrow;
    }
  }

  /// Updates Auth `displayName` and Firestore `users/{uid}.name`.
  Future<void> updateSiteDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }
    final trimmed = displayName.trim();
    try {
      await user.updateDisplayName(trimmed.isEmpty ? null : trimmed);
      await FirestoreService().updateUserDisplayName(trimmed);
    } catch (error, stack) {
      await _recordAuthError(error, stack, 'auth_update_display_name_failed');
      rethrow;
    }
  }

  /// Signs in with email/password and ensures the Firestore profile exists.
  Future<void> signInWithEmail({
    required String email,
    required String password,
    bool recordConsent = false,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await FirestoreService().createUserDocument(recordConsent: recordConsent);
    } catch (error, stack) {
      await _recordAuthError(error, stack, 'auth_email_sign_in_failed');
      rethrow;
    }
  }

  /// Reloads the Firebase user so [needsEmailVerification] can clear.
  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  /// Resends the verification email for the signed-in password user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }
    try {
      await _sendEmailVerificationReliably(user, retryAfterCreate: false);
    } catch (error, stack) {
      await _recordAuthError(error, stack, 'auth_send_verification_failed');
      rethrow;
    }
  }

  /// Firebase Auth often accepts the first [User.sendEmailVerification] call
  /// after account creation without delivering mail; a short delayed retry
  /// matches the manual "resend" that users otherwise need.
  Future<void> _sendEmailVerificationReliably(
    User user, {
    required bool retryAfterCreate,
  }) async {
    Future<void> sendOnce() async {
      final fresh = _auth.currentUser ?? user;
      await fresh.sendEmailVerification();
    }

    try {
      await sendOnce();
    } catch (_) {
      await Future<void>.delayed(const Duration(seconds: 1));
      await _auth.currentUser?.reload();
      await sendOnce();
      return;
    }

    if (!retryAfterCreate) return;

    await Future<void>.delayed(const Duration(seconds: 1));
    try {
      await _auth.currentUser?.reload();
      await sendOnce();
    } on FirebaseAuthException catch (e) {
      // Rate limit / duplicate send — first attempt may still arrive.
      if (e.code == 'too-many-requests') return;
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

  Future<void> _reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-email');
    }
    if (password.isEmpty) {
      throw FirebaseAuthException(code: 'missing-password');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Reauthenticates, wipes Firestore + Storage user data, then deletes Auth.
  ///
  /// Password accounts require [password]; Google accounts use Google reauth.
  Future<void> deleteAccount({String? password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw StateError('No signed-in user');
      }

      if (_hasPasswordProvider(user)) {
        await _reauthenticateWithPassword(password ?? '');
      } else {
        await _reauthenticateWithGoogle();
      }

      await FirestoreService().deleteAllUserData();

      final freshUser = _auth.currentUser;
      if (freshUser == null) {
        throw StateError('User missing after data wipe');
      }
      await freshUser.delete();

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          await _initializeGoogleSignIn();
          await _googleSignIn.signOut();
        } catch (_) {
          // Auth user already deleted; ignore Google sign-out failures.
        }
      }

      await AppCrashReporting.instance.setUserId(null);
      await DeviceConsentStore.instance.clear();
    } catch (error, stack) {
      await _recordAuthError(error, stack, 'auth_delete_account_failed');
      rethrow;
    }
  }
}
