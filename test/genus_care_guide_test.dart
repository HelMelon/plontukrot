import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/genus_care_guide.dart';

void main() {
  group('GenusCareGuide', () {
    test('empty check works correctly', () {
      const emptyGuide = GenusCareGuide(genus: 'Monstera');
      expect(emptyGuide.isEmpty, isTrue);
      expect(emptyGuide.isNotEmpty, isFalse);

      const guideWithOrigin = GenusCareGuide(
        genus: 'Monstera',
        origin: 'Central America',
      );
      expect(guideWithOrigin.isEmpty, isFalse);
      expect(guideWithOrigin.isNotEmpty, isTrue);
    });

    test('serialization roundtrip and snake_case compatibility', () {
      final map = {
        'genus': 'Monstera',
        'origin': 'Тропические леса Центральной Америки',
        'light': 'Яркий рассеянный свет',
        'watering': 'Умеренный, после просыхания верхнего слоя',
        'fertilizing': 'Раз в 2 недели весной и летом',
        'soil': 'Ароидный воздухопроницаемый микс',
        'humidity': 'Повышенная (60-70%)',
        'toxicity': 'Токсично для кошек и собак',
      };

      final guide = GenusCareGuide.fromMap(map);

      expect(guide.genus, 'Monstera');
      expect(guide.origin, 'Тропические леса Центральной Америки');
      expect(guide.light, 'Яркий рассеянный свет');
      expect(guide.watering, 'Умеренный, после просыхания верхнего слоя');
      expect(guide.fertilizing, 'Раз в 2 недели весной и летом');
      expect(guide.soil, 'Ароидный воздухопроницаемый микс');
      expect(guide.humidity, 'Повышенная (60-70%)');
      expect(guide.toxicity, 'Токсично для кошек и собак');

      final serialized = guide.toMap();
      expect(serialized['genus'], 'Monstera');
      expect(serialized['origin'], 'Тропические леса Центральной Америки');
      expect(serialized['light'], 'Яркий рассеянный свет');
      expect(serialized['watering'], 'Умеренный, после просыхания верхнего слоя');
      expect(serialized['fertilizing'], 'Раз в 2 недели весной и летом');
      expect(serialized['soil'], 'Ароидный воздухопроницаемый микс');
      expect(serialized['humidity'], 'Повышенная (60-70%)');
      expect(serialized['toxicity'], 'Токсично для кошек и собак');
    });
  });
}
