import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../privacy/privacy_constants.dart';
import '../theme/theme_context.dart';
import 'focusable_tap.dart';

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

    final labelStyle = typography.bodyMedium.copyWith(
      color: colors.heading,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shrink the Material tap target so the box lines up with the
        // first line of body text instead of floating in a 48px square.
        ExcludeSemantics(
          child: Checkbox(
            value: value,
            onChanged: (next) => onChanged(next ?? false),
            activeColor: colors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        spacing.hXs,
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                checked: value,
                button: true,
                label: l10n.authConsentLabel,
                child: FocusableTap(
                  onTap: () => onChanged(!value),
                  child: Text(
                    '${l10n.authConsentLabel}. ',
                    style: labelStyle,
                  ),
                ),
              ),
              Semantics(
                link: true,
                button: true,
                label: l10n.privacyPolicyLink,
                child: FocusableTap(
                  onTap: _openPrivacyPolicy,
                  child: Text(
                    l10n.privacyPolicyLink,
                    style: labelStyle.copyWith(
                      color: linkColor,
                      decoration: TextDecoration.underline,
                      decorationColor: linkColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
