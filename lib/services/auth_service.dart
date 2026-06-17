import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Инициализируем GoogleSignIn как поле класса сверху, чтобы оно было доступно везде
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://googleapis.com',
    ],
  );

  Future<UserCredential?> signInWithGoogle() async {
    // Сценарий для WEB-версии
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');

      final userCredential = await _auth.signInWithPopup(provider);
      await FirestoreService().createUserDocument();
      return userCredential;
    }

    // Сценарий для мобильных платформ (Android / iOS)
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      return null; // Пользователь закрыл окно авторизации
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    await FirestoreService().createUserDocument();
    return userCredential;
  }

  Future<void> signOut() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}
