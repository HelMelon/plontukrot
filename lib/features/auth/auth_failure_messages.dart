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
    case AuthFailureKind.unknown:
      return l10n.authSignInFailed;
  }
}
