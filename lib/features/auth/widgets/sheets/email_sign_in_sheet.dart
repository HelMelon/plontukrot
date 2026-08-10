import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../services/auth_service.dart';
import '../../auth_failure_messages.dart';
import 'email_register_sheet.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

Future<void> showEmailSignInSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    builder: (_) => const EmailSignInSheet(),
  );
}

class EmailSignInSheet extends StatefulWidget {
  const EmailSignInSheet({super.key});

  @override
  State<EmailSignInSheet> createState() => _EmailSignInSheetState();
}

class _EmailSignInSheetState extends State<EmailSignInSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return context.components.inputs.decoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

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
        content: Text(message, style: typography.bodyMedium),
      ),
    );
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await AuthService().signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        recordConsent: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      await _showAuthError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openRegister() async {
    if (_isLoading) return;
    Navigator.of(context).pop();
    if (!mounted) return;
    await showEmailRegisterSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.92;
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final dimensions = context.dimensions;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: colors.modal,
            borderRadius: sheets.topBorderRadius,
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: sheets.contentPadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: const SheetDragHandle()),
                      spacing.vLg,
                      Text(
                        l10n.authSignInEmailTitle,
                        style: sheets.titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      spacing.vLg,
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          labelText: l10n.authEmailLabel,
                          prefixIcon: ExcludeSemantics(
                            child: Icon(
                              Icons.email_outlined,
                              color: colors.icon,
                              size: dimensions.iconLg,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) return l10n.authFieldRequired;
                          if (!trimmed.contains('@')) {
                            return l10n.authInvalidEmail;
                          }
                          return null;
                        },
                      ),
                      spacing.vMd,
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _signIn(),
                        decoration: _fieldDecoration(
                          labelText: l10n.authPasswordLabel,
                          prefixIcon: ExcludeSemantics(
                            child: Icon(
                              Icons.lock_outline,
                              color: colors.icon,
                              size: dimensions.iconLg,
                            ),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? l10n.a11yShowPassword
                                : l10n.a11yHidePassword,
                            onPressed: _isLoading
                                ? null
                                : () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: colors.icon,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authFieldRequired;
                          }
                          return null;
                        },
                      ),
                      spacing.vXl,
                      SizedBox(
                        height: dimensions.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: Text(
                            _isLoading
                                ? l10n.authSigningIn
                                : l10n.authSignInEmailSubmit,
                          ),
                        ),
                      ),
                      spacing.vMd,
                      TextButton(
                        onPressed: _isLoading ? null : _openRegister,
                        child: Text(l10n.authNoAccountRegister),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
