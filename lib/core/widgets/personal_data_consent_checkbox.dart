import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../privacy/privacy_constants.dart';
import '../theme/theme_context.dart';

/// Checkbox + Privacy Policy link used on login and the consent gate.
class PersonalDataConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PersonalDataConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final linkColor = context.screens.profile.privacyLinkColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: (next) => onChanged(next ?? false),
          activeColor: colors.primary,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: spacing.sm),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${l10n.authConsentLabel}. ',
                  style: typography.bodyMedium.copyWith(
                    color: colors.heading,
                  ),
                ),
                GestureDetector(
                  onTap: _openPrivacyPolicy,
                  child: Text(
                    l10n.privacyPolicyLink,
                    style: typography.bodyMedium.copyWith(
                      color: linkColor,
                      decoration: TextDecoration.underline,
                      decorationColor: linkColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
