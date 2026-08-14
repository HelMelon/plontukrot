import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/core/theme/app_theme.dart';
import 'package:plontukrot/features/plants/widgets/selectors/fertilizing_frequency_field.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

/// Parent that recomputes frequency on stage change and calls setState — the
/// exact scenario that used to crash with a black screen when the field called
/// onFrequencyChanged from didUpdateWidget during the build phase.
class _StageHost extends StatefulWidget {
  const _StageHost();

  @override
  State<_StageHost> createState() => _StageHostState();
}

class _StageHostState extends State<_StageHost> {
  int _stage = 1;
  int? _days = 21;
  bool _custom = false;

  void _changeStage(int next) {
    setState(() {
      _stage = next;
      // Parent recomputes auto value for the new stage (spring/summer: 14).
      _days = next == 2 ? 14 : 21;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FertilizingFrequencyField(
            stage: _stage,
            frequencyDays: _days,
            isCustom: _custom,
            onFrequencyChanged: (v) => setState(() => _days = v),
            onCustomChanged: (v) => setState(() => _custom = v),
          ),
          TextButton(
            onPressed: () => _changeStage(2),
            child: const Text('to-baby'),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('stage change does not crash (no setState during build)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _StageHost(),
      ),
    );

    // Trigger the stage change that previously crashed.
    await tester.tap(find.text('to-baby'));
    await tester.pump();

    // No exception thrown; field still present and reflects the new value.
    expect(tester.takeException(), isNull);
    expect(find.byType(FertilizingFrequencyField), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
  });
}
