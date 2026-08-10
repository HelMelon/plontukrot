import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/theme/theme_context.dart';

import '../../../core/widgets/personal_data_consent_checkbox.dart';
import '../../../services/auth_service.dart';
import '../auth_failure_messages.dart';
import '../widgets/sheets/email_sign_in_sheet.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;
  bool _consentAccepted = false;

  Future<void> _showAuthError(Object error) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final message =
        authFailureMessage(AuthService.classifyFailure(error), l10n);
    if (message == null) return;
    final colors = context.colors;
    final typography = context.typography;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.card,
        content: Text(
          message,
          style: typography.bodyMedium,
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (!_consentAccepted || isLoading) return;
    setState(() => isLoading = true);
    try {
      await AuthService().signInWithGoogle(recordConsent: true);
    } catch (e) {
      await _showAuthError(e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _openEmailSignIn() async {
    if (!_consentAccepted || isLoading) return;
    await showEmailSignInSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final dimensions = context.dimensions;
    final loginTheme = context.screens.login;
    final canSubmit = !isLoading && _consentAccepted;

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
                Text(
                  l10n.brandTagline,
                  textAlign: TextAlign.center,
                  style: loginTheme.subtitleStyle.copyWith(
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
                    onPressed: canSubmit ? _openEmailSignIn : null,
                    icon: const Icon(Icons.email_outlined),
                    label: Text(l10n.authSignInEmail),
                  ),
                ),
                spacing.vMd,
                SizedBox(
                  width: double.infinity,
                  height: dimensions.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: canSubmit ? _signInWithGoogle : null,
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
