import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/core/theme/app_theme.dart';
import 'package:plontukrot/features/plants/widgets/cards/plant_card.dart';
import 'package:plontukrot/features/plants/widgets/common/plant_image.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/plant.dart';

/// Phone-sized surface: the layout the home grid actually uses.
const Size _phoneSize = Size(390, 844);

/// Landscape desktop surface: the card falls back to the wide layout, whose
/// cell height the grid asks [PlantCard.gridMainAxisExtent] for.
const Size _landscapeSize = Size(1200, 800);

/// Grid cell width used by the tests.
const double _cellWidth = 200;

Widget _wrap(
  Widget child, {
  Size screen = _phoneSize,
  bool compactGrid = true,
}) {
  return MaterialApp(
    theme: AppTheme.theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(size: screen),
      child: Builder(
        builder: (context) {
          // Same geometry the home grid computes for this cell, instead of a
          // hand-picked height that can hide a real overflow.
          final height = PlantCard.gridMainAxisExtent(
                context,
                cellWidth: _cellWidth,
                compactGrid: compactGrid,
              ) ??
              _cellWidth / 0.625; // home grid's childAspectRatio fallback
          return Scaffold(
            body: SizedBox(
              width: _cellWidth,
              height: height,
              child: child,
            ),
          );
        },
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

  testWidgets('PlantCard fits the wide grid cell on a landscape screen',
      (tester) async {
    const plant = Plant(
      id: '1',
      genus: 'Monstera',
      species: 'deliciosa var. borsigiana',
      nickname: 'With photo in the wide layout',
      stage: 1,
      imageUrl: 'https://example.com/full.jpg',
      imageThumbUrl: 'https://example.com/thumb.jpg',
    );

    // Overflow throws inside the test, so a passing pump is the assertion.
    await tester.pumpWidget(
      _wrap(
        PlantCard(plant: plant, onTap: () {}),
        screen: _landscapeSize,
        compactGrid: false,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
