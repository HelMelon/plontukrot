import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = e is FirebaseAuthException &&
              e.code == 'google-id-token-null'
          ? l10n.authGoogleIdTokenMissing
          : l10n.authSignInError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.dark2,
          content: Text(
            message,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Image.asset(
                    'assets/images/big-logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 42),
                Text(
                  l10n.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'NordicStyle',
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.brandTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 54),
                SizedBox(
                  width: double.infinity,
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : signIn,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.dark1,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      isLoading ? l10n.authSigningIn : l10n.authSignInGoogle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
