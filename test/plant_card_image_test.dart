import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/core/theme/app_theme.dart';
import 'package:plontukrot/features/plants/widgets/cards/plant_card.dart';
import 'package:plontukrot/features/plants/widgets/common/plant_image.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/plant.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 200,
        height: 350,
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('PlantCard without image shows asset placeholder path',
      (tester) async {
    const plant = Plant(
      id: '1',
      genus: 'Monstera',
      species: 'deliciosa',
      nickname: 'No photo',
      stage: 1,
    );

    await tester.pumpWidget(
      _wrap(
        PlantCard(
          plant: plant,
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PlantImage), findsNothing);
    expect(find.image(const AssetImage('assets/images/default-img.webp')),
        findsOneWidget);
  });

  testWidgets('PlantCard with urls builds PlantImage', (tester) async {
    const plant = Plant(
      id: '1',
      genus: 'Monstera',
      species: 'deliciosa',
      nickname: 'With photo',
      stage: 1,
      imageUrl: 'https://example.com/full.jpg',
      imageThumbUrl: 'https://example.com/thumb.jpg',
    );

    await tester.pumpWidget(
      _wrap(
        PlantCard(
          plant: plant,
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PlantImage), findsOneWidget);
    final image = tester.widget<PlantImage>(
      find.byType(PlantImage),
    );
    expect(image.imageUrl, 'https://example.com/thumb.jpg');
    expect(image.fallbackUrl, 'https://example.com/full.jpg');
  });
}
