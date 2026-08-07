import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/personal_data_consent_checkbox.dart';
import '../../../services/firestore_service.dart';

/// Blocks Home until `personalDataConsentAt` exists on the user document.
class PersonalDataConsentGatePage extends StatefulWidget {
  final Widget child;
  final VoidCallback? onContentReady;

  const PersonalDataConsentGatePage({
    super.key,
    required this.child,
    this.onContentReady,
  });

  @override
  State<PersonalDataConsentGatePage> createState() =>
      _PersonalDataConsentGatePageState();
}

class _PersonalDataConsentGatePageState
    extends State<PersonalDataConsentGatePage> {
  bool _accepted = false;
  bool _saving = false;
  bool _readySignaled = false;

  void _signalReadyOnce() {
    if (_readySignaled || widget.onContentReady == null) return;
    _readySignaled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onContentReady?.call();
      });
    });
  }

  Future<void> _submit() async {
    if (!_accepted || _saving) return;
    setState(() => _saving = true);
    try {
      await FirestoreService().recordPersonalDataConsent();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FirestoreService().watchHasPersonalDataConsent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          // Splash covers cold start; avoid a visible spinner flash.
          if (widget.onContentReady != null) {
            return const SizedBox.expand();
          }
          final colors = context.colors;
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: colors.primary),
            ),
          );
        }

        if (snapshot.data == true) {
          return widget.child;
        }

        _signalReadyOnce();

        final l10n = AppLocalizations.of(context);
        final colors = context.colors;
        final spacing = context.spacing;
        final typography = context.typography;
        final dimensions = context.dimensions;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: spacing.allXl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.authConsentGateTitle,
                      style: typography.titleMedium.copyWith(
                        color: colors.heading,
                      ),
                    ),
                    spacing.vMd,
                    Text(
                      l10n.authConsentGateBody,
                      style: typography.bodyLarge.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    spacing.vXl,
                    PersonalDataConsentCheckbox(
                      value: _accepted,
                      onChanged: (v) => setState(() => _accepted = v),
                    ),
                    spacing.vXl,
                    SizedBox(
                      height: dimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _accepted && !_saving ? _submit : null,
                        child: _saving
                            ? SizedBox(
                                width: dimensions.iconLg,
                                height: dimensions.iconLg,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : Text(l10n.authConsentContinue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
