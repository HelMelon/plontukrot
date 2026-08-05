import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'package:plontukrot/core/theme/theme_context.dart';

import '../../../core/currency/app_currency.dart';
import '../../../core/currency/app_currency_controller.dart';
import '../../../core/locale/app_locale_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _currencyLabel(AppLocalizations l10n, AppCurrency currency) {
    return switch (currency) {
      AppCurrency.usd => l10n.settingsCurrencyUsd,
      AppCurrency.eur => l10n.settingsCurrencyEur,
      AppCurrency.rub => l10n.settingsCurrencyRub,
      AppCurrency.byn => l10n.settingsCurrencyByn,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeController = AppLocaleController.instance;
    final currencyController = AppCurrencyController.instance;
    final checkIconColor = context.screens.settings.checkIconColor;

    final languageOptions = <({String code, String label})>[
      (code: AppLocaleController.systemCode, label: l10n.settingsLanguageSystem),
      (code: 'en', label: l10n.settingsLanguageEnglish),
      (code: 'ru', label: l10n.settingsLanguageRussian),
      (code: 'de', label: l10n.settingsLanguageGerman),
      (code: 'fr', label: l10n.settingsLanguageFrench),
    ];

    final currencyOptions = AppCurrency.values;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.settingsTitle),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([localeController, currencyController]),
        builder: (context, _) {
          final selectedLanguage = localeController.preferenceCode;
          final selectedCurrency = currencyController.currency;
          return ListView(
            children: [
              ListTile(title: Text(l10n.settingsLanguage)),
              for (final option in languageOptions)
                ListTile(
                  title: Text(option.label),
                  trailing: selectedLanguage == option.code
                      ? Icon(Icons.check, color: checkIconColor)
                      : null,
                  onTap: () => localeController.setPreference(option.code),
                ),
              const Divider(),
              ListTile(title: Text(l10n.settingsCurrency)),
              for (final currency in currencyOptions)
                ListTile(
                  title: Text(_currencyLabel(l10n, currency)),
                  subtitle: Text('${currency.code} · ${currency.symbol}'),
                  trailing: selectedCurrency == currency
                      ? Icon(Icons.check, color: checkIconColor)
                      : null,
                  onTap: () => currencyController.setCurrency(currency),
                ),
            ],
          );
        },
      ),
    );
  }
}
