import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/privacy/device_consent_store.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/personal_data_consent_checkbox.dart';
import '../../../services/user_profile_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

/// Blocks Home until `personalDataConsentAt` exists on the user document.
///
/// If the user already accepted on this device (login checkbox), consent is
/// synced to Firestore automatically — no second consent screen after Google
/// / email sign-in (Auth can open this gate before `createUserDocument` finishes).
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
  late final Stream<bool> _consentStream;
  bool _accepted = false;
  bool _deviceConsentLoaded = false;
  bool _saving = false;
  bool _readySignaled = false;
  bool _consentError = false;
  bool _autoSyncStarted = false;

  /// True only if consent was already stored on this device BEFORE this
  /// screen opened. Not affected by toggling the checkbox, so the form stays
  /// visible until the user actually submits (consent is persisted on submit).
  bool _consentRememberedOnDevice = false;

  @override
  void initState() {
    super.initState();
    _consentStream = UserProfileService().watchHasPersonalDataConsent();
    _loadDeviceConsent();
  }

  Future<void> _loadDeviceConsent() async {
    final accepted = await DeviceConsentStore.instance.isAccepted();
    if (!mounted) return;
    setState(() {
      _accepted = accepted;
      _deviceConsentLoaded = true;
      _consentRememberedOnDevice = accepted;
    });
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

  Future<void> _submit() async {
    if (_saving) return;
    if (!_accepted) {
      setState(() => _consentError = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await UserProfileService().recordPersonalDataConsent();
      await DeviceConsentStore.instance.rememberAccepted();
      if (mounted) {
        setState(() => _consentRememberedOnDevice = true);
      }
    } catch (e) {
      await DeviceConsentStore.instance.rememberAccepted();
      if (mounted) {
        setState(() => _consentRememberedOnDevice = true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _autoSyncDeviceConsent() {
    if (_autoSyncStarted || _saving) return;
    _autoSyncStarted = true;
    unawaited(UserProfileService().recordPersonalDataConsent());
  }

  Widget _waitingPlaceholder(BuildContext context) {
    // Splash covers cold start; avoid a visible spinner flash.
    if (widget.onContentReady != null) {
      return const SizedBox.expand();
    }
    final colors = context.colors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AccessibleProgressIndicator(color: colors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _consentStream,
      builder: (context, snapshot) {
        if (!_deviceConsentLoaded &&
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _waitingPlaceholder(context);
        }

        if (snapshot.data == true || _consentRememberedOnDevice) {
          if (_consentRememberedOnDevice && snapshot.data != true) {
            _autoSyncDeviceConsent();
          }
          unawaited(DeviceConsentStore.instance.rememberAccepted());
          return widget.child;
        }

        // Wait until we know the device flag before choosing UI vs auto-sync.
        if (!_deviceConsentLoaded) {
          return _waitingPlaceholder(context);
        }

        _signalReadyOnce();

        final l10n = AppLocalizations.of(context);
        final colors = context.colors;
        final spacing = context.spacing;
        final typography = context.typography;
        final dimensions = context.dimensions;
        final canContinue = !_saving;

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
                      style: typography.titleSmall.copyWith(
                        color: colors.heading,
                      ),
                    ),
                    spacing.vMd,
                    Text(
                      l10n.authConsentGateBody,
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    spacing.vXl,
                    PersonalDataConsentCheckbox(
                      value: _accepted,
                      onChanged: (v) => setState(() {
                        _accepted = v;
                        if (v) _consentError = false;
                      }),
                      errorText:
                          _consentError ? l10n.authConsentRequired : null,
                    ),
                    spacing.vXl,
                    SizedBox(
                      height: dimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: canContinue ? _submit : null,
                        child: _saving
                            ? SizedBox(
                                width: dimensions.iconLg,
                                height: dimensions.iconLg,
                                child: AccessibleProgressIndicator(
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
