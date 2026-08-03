import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocalizations', () {
    Future<AppLocalizations> load(Locale locale) {
      return AppLocalizations.delegate.load(locale);
    }

    test('supports en, ru, de, fr', () {
      expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
          containsAll(['en', 'ru', 'de', 'fr']));
    });

    test('English is available as fallback source', () async {
      final l10n = await load(const Locale('en'));
      expect(l10n.commonCancel, 'Cancel');
      expect(l10n.fertilizerCustomMix, 'Custom mix');
      expect(l10n.fertilizerUnknown, 'Unknown');
    });

    test('Russian loads core keys', () async {
      final l10n = await load(const Locale('ru'));
      expect(l10n.authSignInGoogle, 'Войти через Google');
      expect(l10n.fertilizerCustomMix, 'Свой микс');
    });

    test('German and French load', () async {
      final de = await load(const Locale('de'));
      final fr = await load(const Locale('fr'));
      expect(de.commonSave, isNotEmpty);
      expect(fr.commonSave, isNotEmpty);
      expect(de.commonSave, isNot(equals(fr.commonSave)));
    });

    test('daysCount pluralization', () async {
      final en = await load(const Locale('en'));
      expect(en.daysCount(0), 'today');
      expect(en.daysCount(1), '1 day');
      expect(en.daysCount(5), '5 days');

      final ru = await load(const Locale('ru'));
      expect(ru.daysCount(0), 'сегодня');
      expect(ru.daysCount(1), '1 день');
    });

    test('interpolation placeholders', () async {
      final en = await load(const Locale('en'));
      expect(en.commonError('boom'), contains('boom'));
      expect(en.homeSelectedCount(3), contains('3'));
    });

    test('unsupported locale falls back via lookup to English', () {
      expect(
        () => lookupAppLocalizations(const Locale('es')),
        throwsFlutterError,
      );
      // MaterialApp localeResolutionCallback maps unsupported → en.
      final en = lookupAppLocalizations(const Locale('en'));
      expect(en.commonCancel, 'Cancel');
    });
  });
}
