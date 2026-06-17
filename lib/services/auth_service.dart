import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();

      provider.addScope('email');
      provider.addScope('profile');

      final userCredential = await _auth.signInWithPopup(provider);

      await FirestoreService().createUserDocument();

      return userCredential;
    }

    // 1. Объявляем переменную класса в самом верху (вне методов)
    final GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'https://googleapis.com',
      ],
    );

    // Ваш метод входа (замените старое содержимое на это)
    Future<UserCredential?> signInWithGoogle() async {
      // Больше никаких .instance, .initialize() и .authenticate()
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // Пользователь отменил вход
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      await FirestoreService().createUserDocument();

      return userCredential;
    }

    // Метод выхода
    Future<void> signOut() async {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Используем объявленный выше экземпляр класса вместо .instance
        await _googleSignIn.signOut();
      }

      await _auth.signOut();
    }

  }
