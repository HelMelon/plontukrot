import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../services/auth_service.dart';

/// Localized message for [kind], or `null` when the UI should stay silent
/// (user cancelled the sign-in flow).
String? authFailureMessage(AuthFailureKind kind, AppLocalizations l10n) {
  switch (kind) {
    case AuthFailureKind.cancelled:
      return null;
    case AuthFailureKind.network:
      return l10n.authSignInNetworkError;
    case AuthFailureKind.missingIdToken:
      return l10n.authGoogleIdTokenMissing;
    case AuthFailureKind.invalidEmail:
      return l10n.authInvalidEmail;
    case AuthFailureKind.weakPassword:
      return l10n.authWeakPassword;
    case AuthFailureKind.emailAlreadyInUse:
      return l10n.authEmailAlreadyInUse;
    case AuthFailureKind.invalidCredentials:
      return l10n.authInvalidCredentials;
    case AuthFailureKind.tooManyRequests:
      return l10n.authTooManyRequests;
    case AuthFailureKind.unknown:
      return l10n.authSignInFailed;
  }
}
