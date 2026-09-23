import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/family_care_guide.dart';

void main() {
  group('FamilyCareGuide', () {
    test('empty check works correctly', () {
      const emptyGuide = FamilyCareGuide(family: 'Araceae');
      expect(emptyGuide.isEmpty, isTrue);
      expect(emptyGuide.isNotEmpty, isFalse);

      const guideWithOrigin = FamilyCareGuide(
        family: 'Araceae',
        origin: 'Tropical regions',
      );
      expect(guideWithOrigin.isEmpty, isFalse);
      expect(guideWithOrigin.isNotEmpty, isTrue);
    });

    test('serialization roundtrip and snake_case compatibility', () {
      final map = {
        'family': 'Araceae',
        'origin': 'Тропические и субтропические регионы',
        'light': 'Яркий рассеянный свет',
        'watering': 'Умеренный, после просыхания верхнего слоя',
        'fertilizing': 'Раз в 2 недели весной и летом',
        'soil': 'Воздухопроницаемый микс',
        'humidity': 'Повышенная (60-70%)',
        'toxicity': 'Многие виды токсичны для кошек и собак',
      };

      final guide = FamilyCareGuide.fromMap(map);

      expect(guide.family, 'Araceae');
      expect(guide.origin, 'Тропические и субтропические регионы');
      expect(guide.light, 'Яркий рассеянный свет');
      expect(guide.watering, 'Умеренный, после просыхания верхнего слоя');
      expect(guide.fertilizing, 'Раз в 2 недели весной и летом');
      expect(guide.soil, 'Воздухопроницаемый микс');
      expect(guide.humidity, 'Повышенная (60-70%)');
      expect(guide.toxicity, 'Многие виды токсичны для кошек и собак');

      final serialized = guide.toMap();
      expect(serialized['family'], 'Araceae');
      expect(serialized['origin'], 'Тропические и субтропические регионы');
      expect(serialized['light'], 'Яркий рассеянный свет');
      expect(serialized['watering'], 'Умеренный, после просыхания верхнего слоя');
      expect(serialized['fertilizing'], 'Раз в 2 недели весной и летом');
      expect(serialized['soil'], 'Воздухопроницаемый микс');
      expect(serialized['humidity'], 'Повышенная (60-70%)');
      expect(serialized['toxicity'], 'Многие виды токсичны для кошек и собак');
    });
  });
}
