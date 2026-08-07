import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/theme/theme_context.dart';

import '../../../core/widgets/personal_data_consent_checkbox.dart';
import '../../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;
  bool _consentAccepted = false;

  Future<void> signIn() async {
    if (!_consentAccepted || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      await AuthService().signInWithGoogle(recordConsent: true);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final colors = context.colors;
      final typography = context.typography;
      final message = e is FirebaseAuthException &&
              e.code == 'google-id-token-null'
          ? l10n.authGoogleIdTokenMissing
          : l10n.authSignInError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.card,
          content: Text(
            message,
            style: typography.bodyLarge,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final dimensions = context.dimensions;
    final typography = context.typography;
    final loginTheme = context.screens.login;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: spacing.allXl,
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
                spacing.vXxxl,
                Text(
                  l10n.appName,
                  textAlign: TextAlign.center,
                  style: loginTheme.brandStyle,
                ),
                spacing.vMd,
                Text(
                  l10n.brandTagline,
                  textAlign: TextAlign.center,
                  style: typography.bodyLarge.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
                spacing.vXxxl,
                PersonalDataConsentCheckbox(
                  value: _consentAccepted,
                  onChanged: (v) => setState(() => _consentAccepted = v),
                ),
                spacing.vXl,
                SizedBox(
                  width: double.infinity,
                  height: dimensions.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed:
                        isLoading || !_consentAccepted ? null : signIn,
                    icon: isLoading
                        ? SizedBox(
                            width: dimensions.iconLg,
                            height: dimensions.iconLg,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onPrimary,
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
