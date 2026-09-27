import 'package:eventor/core/widgets/organisms/selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// Few enough to fit without a search field.
const List<SelectionOption<int>> _few = <SelectionOption<int>>[
  SelectionOption<int>(value: 9, label: 'Blida'),
  SelectionOption<int>(value: 16, label: 'Alger'),
  SelectionOption<int>(value: 42, label: 'Tipaza'),
];

/// Nine wilayas: one past the search threshold.
const List<SelectionOption<int>> _many = <SelectionOption<int>>[
  SelectionOption<int>(value: 1, label: 'Adrar'),
  SelectionOption<int>(value: 2, label: 'Chlef'),
  SelectionOption<int>(value: 3, label: 'Laghouat'),
  SelectionOption<int>(value: 4, label: 'Oum El Bouaghi'),
  SelectionOption<int>(value: 5, label: 'Batna'),
  SelectionOption<int>(value: 6, label: 'Béjaïa'),
  SelectionOption<int>(value: 7, label: 'Biskra'),
  SelectionOption<int>(value: 8, label: 'Béchar'),
  SelectionOption<int>(value: 9, label: 'Blida'),
];

void main() {
  /// Opens the sheet from a button and records what it answered.
  Future<List<Set<int>?>> openSheet(
    WidgetTester tester, {
    List<SelectionOption<int>> options = _few,
    bool multiple = false,
    Set<int> selected = const <int>{},
    Locale locale = englishLocale,
  }) async {
    final List<Set<int>?> answers = <Set<int>?>[];

    await pumpAppWidget(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async => answers.add(
            await showSelectionSheet<int>(
              context,
              title: 'Wilaya',
              options: options,
              multiple: multiple,
              selected: selected,
            ),
          ),
          child: const Text('open'),
        ),
      ),
      locale: locale,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return answers;
  }

  group('showSelectionSheet, single choice', () {
    testWidgets('lists every option under the title',
        (WidgetTester tester) async {
      await openSheet(tester);

      expect(find.text('Wilaya'), findsOneWidget);
      for (final SelectionOption<int> option in _few) {
        expect(find.text(option.label), findsOneWidget);
      }
    });

    testWidgets('picks and closes on a tap', (WidgetTester tester) async {
      final List<Set<int>?> answers = await openSheet(tester);

      await tester.tap(find.text('Alger'));
      await tester.pumpAndSettle();

      expect(answers, <Set<int>?>[<int>{16}]);
      expect(find.text('Wilaya'), findsNothing);
    });

    testWidgets('has no Done button', (WidgetTester tester) async {
      await openSheet(tester);

      expect(find.text(l10n(tester).selectionDone), findsNothing);
    });

    testWidgets('answers nothing when dismissed', (WidgetTester tester) async {
      final List<Set<int>?> answers = await openSheet(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(answers, <Set<int>?>[null]);
    });
  });

  group('showSelectionSheet, multiple choice', () {
    testWidgets('toggles rows and returns the set on Done',
        (WidgetTester tester) async {
      final List<Set<int>?> answers = await openSheet(tester, multiple: true);

      await tester.tap(find.text('Blida'));
      await tester.pump();
      await tester.tap(find.text('Tipaza'));
      await tester.pump();

      // Tapping a row does not close the sheet in this mode.
      expect(find.text('Wilaya'), findsOneWidget);

      await tester.tap(find.text(l10n(tester).selectionDoneCount(2)));
      await tester.pumpAndSettle();

      expect(answers.single, <int>{9, 42});
    });

    testWidgets('starts from what was already chosen, and can drop it',
        (WidgetTester tester) async {
      final List<Set<int>?> answers = await openSheet(
        tester,
        multiple: true,
        selected: <int>{9, 16},
      );

      expect(find.text(l10n(tester).selectionDoneCount(2)), findsOneWidget);

      await tester.tap(find.text('Blida'));
      await tester.pump();
      await tester.tap(find.text(l10n(tester).selectionDoneCount(1)));
      await tester.pumpAndSettle();

      expect(answers.single, <int>{16});
    });

    testWidgets('says plain Done with nothing chosen',
        (WidgetTester tester) async {
      final List<Set<int>?> answers = await openSheet(tester, multiple: true);

      await tester.tap(find.text(l10n(tester).selectionDone));
      await tester.pumpAndSettle();

      expect(answers.single, isEmpty);
    });

    testWidgets('answers nothing when dismissed, whatever was toggled',
        (WidgetTester tester) async {
      // A dismissal must not overwrite the choice the form already holds.
      final List<Set<int>?> answers = await openSheet(
        tester,
        multiple: true,
        selected: <int>{16},
      );

      await tester.tap(find.text('Blida'));
      await tester.pump();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(answers, <Set<int>?>[null]);
    });
  });

  group('showSelectionSheet search', () {
    testWidgets('is left out for a short list', (WidgetTester tester) async {
      await openSheet(tester);

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('is left out at exactly eight options',
        (WidgetTester tester) async {
      await openSheet(tester, options: _many.take(8).toList());

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('appears past eight options', (WidgetTester tester) async {
      await openSheet(tester, options: _many);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(l10n(tester).searchHint), findsOneWidget);
    });

    testWidgets('filters as it is typed, ignoring case',
        (WidgetTester tester) async {
      await openSheet(tester, options: _many);

      await tester.enterText(find.byType(TextField), 'BLI');
      await tester.pump();

      expect(find.text('Blida'), findsOneWidget);
      expect(find.text('Adrar'), findsNothing);
      expect(find.text('Biskra'), findsNothing);
    });

    testWidgets('picks from the filtered list', (WidgetTester tester) async {
      final List<Set<int>?> answers = await openSheet(tester, options: _many);

      await tester.enterText(find.byType(TextField), 'chl');
      await tester.pump();
      await tester.tap(find.text('Chlef'));
      await tester.pumpAndSettle();

      expect(answers, <Set<int>?>[<int>{2}]);
    });

    testWidgets('says so when nothing matches', (WidgetTester tester) async {
      await openSheet(tester, options: _many);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.text(l10n(tester).selectionNoMatch), findsOneWidget);
    });

    testWidgets('keeps choices made before the filter changed',
        (WidgetTester tester) async {
      final List<Set<int>?> answers = await openSheet(
        tester,
        options: _many,
        multiple: true,
      );

      await tester.tap(find.text('Adrar'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'bli');
      await tester.pump();
      await tester.tap(find.text('Blida'));
      await tester.pump();
      await tester.tap(find.text(l10n(tester).selectionDoneCount(2)));
      await tester.pumpAndSettle();

      expect(answers.single, <int>{1, 9});
    });
  });

  group('showSelectionSheet in Arabic', () {
    testWidgets('lists the options and answers the same way',
        (WidgetTester tester) async {
      final List<Set<int>?> answers = await openSheet(
        tester,
        options: const <SelectionOption<int>>[
          SelectionOption<int>(value: 9, label: 'البليدة'),
          SelectionOption<int>(value: 16, label: 'الجزائر'),
        ],
        locale: arabicLocale,
      );

      await tester.tap(find.text('الجزائر'));
      await tester.pumpAndSettle();

      expect(answers, <Set<int>?>[<int>{16}]);
    });
  });
}
