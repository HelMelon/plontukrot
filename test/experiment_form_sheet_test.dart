import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/core/theme/app_theme.dart';
import 'package:plontukrot/features/experiments/widgets/_variant_draft_row.dart';
import 'package:plontukrot/features/experiments/widgets/variant_draft.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

void main() {
  test('restoreIfCleared puts back a wiped description only', () {
    final draft = VariantDraft(
      label: 'mesh pot',
      description: 'sphagnum and bark',
    );
    draft.description.clear();
    draft.restoreIfCleared(
      label: 'mesh pot',
      description: 'sphagnum and bark',
    );
    expect(draft.label.text, 'mesh pot');
    expect(draft.description.text, 'sphagnum and bark');

    draft.description.clear();
    draft.restoreIfCleared(label: 'mesh pot', description: '');
    expect(draft.description.text, isEmpty);
    draft.dispose();
  });

  testWidgets('first variant description survives adding another variant',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _VariantListHost(),
      ),
    );

    const description = 'sphagnum, coco chips, pine bark';
    await tester.enterText(_fieldWith(hint: 'in coconut'), 'hanging mesh pot');
    await tester.enterText(
      _fieldWith(label: 'Variant description (optional)'),
      description,
    );
    await tester.pump();

    await tester.tap(find.text('Add variant'));
    await tester.pump();

    expect(find.text(description), findsOneWidget);
    expect(find.text('hanging mesh pot'), findsOneWidget);
  });
}

/// One variant card plus the same add-row rebuild the form does.
class _VariantListHost extends StatefulWidget {
  const _VariantListHost();

  @override
  State<_VariantListHost> createState() => _VariantListHostState();
}

class _VariantListHostState extends State<_VariantListHost> {
  final _variants = [VariantDraft.empty()];

  void _add() {
    final snapshots = [
      for (final variant in _variants)
        (label: variant.label.text, description: variant.description.text),
    ];
    setState(() => _variants.add(VariantDraft.empty()));
    for (var i = 0; i < snapshots.length; i++) {
      _variants[i].restoreIfCleared(
        label: snapshots[i].label,
        description: snapshots[i].description,
      );
    }
  }

  @override
  void dispose() {
    for (final variant in _variants) {
      variant.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          for (var i = 0; i < _variants.length; i++)
            VariantDraftRow(
              key: ObjectKey(_variants[i]),
              draft: _variants[i],
              index: i,
              canRemove: _variants.length > 1,
              onRemove: () {},
              onChanged: () {},
              onRemoveExisting: () async => false,
            ),
          TextButton(
            onPressed: _add,
            child: const Text('Add variant'),
          ),
        ],
      ),
    );
  }
}

Finder _fieldWith({String? label, String? hint}) {
  return find.byWidgetPredicate((widget) {
    if (widget is! TextField) return false;
    final decoration = widget.decoration;
    if (label != null && decoration?.labelText == label) return true;
    if (hint != null && decoration?.hintText == hint) return true;
    return false;
  });
}
