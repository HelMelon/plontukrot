import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/locale/app_locale_controller.dart';
import '../../../core/theme/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppLocaleController.instance;

    final options = <({String code, String label})>[
      (code: AppLocaleController.systemCode, label: l10n.settingsLanguageSystem),
      (code: 'en', label: l10n.settingsLanguageEnglish),
      (code: 'ru', label: l10n.settingsLanguageRussian),
      (code: 'de', label: l10n.settingsLanguageGerman),
      (code: 'fr', label: l10n.settingsLanguageFrench),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.settingsTitle),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final selected = controller.preferenceCode;
          return ListView(
            children: [
              ListTile(title: Text(l10n.settingsLanguage)),
              for (final option in options)
                ListTile(
                  title: Text(option.label),
                  trailing: selected == option.code
                      ? const Icon(Icons.check, color: AppColors.goldAccent)
                      : null,
                  onTap: () => controller.setPreference(option.code),
                ),
            ],
          );
        },
      ),
    );
  }
}
