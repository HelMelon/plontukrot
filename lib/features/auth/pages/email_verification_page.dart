import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/theme/theme_context.dart';

import '../../../services/auth_service.dart';
import '../auth_failure_messages.dart';

/// Shown for password-provider users until Firebase marks email as verified.
class EmailVerificationPage extends StatefulWidget {
  final VoidCallback? onContentReady;

  const EmailVerificationPage({super.key, this.onContentReady});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _busy = false;
  bool _readySignaled = false;

  @override
  void initState() {
    super.initState();
    _signalReadyOnce();
  }

  void _signalReadyOnce() {
    if (_readySignaled || widget.onContentReady == null) return;
    _readySignaled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onContentReady?.call();
      });
    });
  }

  Future<void> _showError(Object error) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final message =
        authFailureMessage(AuthService.classifyFailure(error), l10n) ??
            l10n.authSignInFailed;
    final colors = context.colors;
    final typography = context.typography;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.card,
        content: Text(message, style: typography.bodyMedium),
      ),
    );
  }

  Future<void> _checkVerified() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final auth = AuthService();
      await auth.reloadCurrentUser();
      if (!mounted) return;
      if (auth.needsEmailVerification) {
        final colors = context.colors;
        final typography = context.typography;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.card,
            content: Text(
              l10n.authEmailVerificationPending,
              style: typography.bodyMedium,
            ),
          ),
        );
      }
      // If verified, AuthGate rebuilds via userChanges and leaves this page.
    } catch (e) {
      await _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await AuthService().sendEmailVerification();
      if (!mounted) return;
      final colors = context.colors;
      final typography = context.typography;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.card,
          content: Text(
            l10n.authEmailVerificationResent,
            style: typography.bodyMedium,
          ),
        ),
      );
    } catch (e) {
      await _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AuthService().signOut();
    } catch (e) {
      await _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final dimensions = context.dimensions;
    final typography = context.typography;
    final email = AuthService().currentUserEmail ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: spacing.allXl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  context.icons.emailUnread,
                  size: dimensions.iconXl * 2,
                  color: colors.primary,
                ),
                spacing.vXxxl,
                Text(
                  l10n.authEmailVerificationTitle,
                  textAlign: TextAlign.center,
                  style: typography.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                spacing.vMd,
                Text(
                  l10n.authEmailVerificationBody(email),
                  textAlign: TextAlign.center,
                  style: typography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
                spacing.vXxxl,
                SizedBox(
                  width: double.infinity,
                  height: dimensions.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _checkVerified,
                    child: Text(
                      _busy
                          ? l10n.authEmailVerificationChecking
                          : l10n.authEmailVerificationCheck,
                    ),
                  ),
                ),
                spacing.vMd,
                SizedBox(
                  width: double.infinity,
                  height: dimensions.buttonHeight,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _resend,
                    child: Text(l10n.authEmailVerificationResend),
                  ),
                ),
                spacing.vMd,
                TextButton(
                  onPressed: _busy ? null : _signOut,
                  child: Text(l10n.authSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
