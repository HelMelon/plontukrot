import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/core/text/locale_safe_text.dart';

void main() {
  group('sanitizeLocaleText', () {
    test('keeps Cyrillic and Latin text', () {
      const input = 'Аденium, Пахиподиум, например свет';
      expect(sanitizeLocaleText(input), input);
    });

    test('removes Arabic characters', () {
      expect(
        sanitizeLocaleText('Аден\u064A\u0648\u043C'),
        'Аденм',
      );
    });

    test('removes bidi control characters', () {
      expect(
        sanitizeLocaleText('текст\u200F\u202Bсмесью\u202C'),
        'текстсмесью',
      );
    });
  });
}
