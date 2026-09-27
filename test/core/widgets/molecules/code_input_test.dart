import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/molecules/code_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  /// The digit boxes, left to right as laid out. The row of boxes is the
  /// first row in the input; the invisible field behind it has rows of its
  /// own, which must not be counted.
  Finder boxes() => find.descendant(
        of: find
            .descendant(
              of: find.byType(CodeInput),
              matching: find.byType(Row),
            )
            .first,
        matching: find.byType(Container),
      );

  BorderSide edgeOf(WidgetTester tester, int index) =>
      ((tester.widget<Container>(boxes().at(index)).decoration!
                  as BoxDecoration)
              .border! as Border)
          .top;

  Future<List<String>> pumpCode(
    WidgetTester tester, {
    bool hasError = false,
    bool enabled = true,
    Locale locale = englishLocale,
  }) async {
    final List<String> completed = <String>[];
    await pumpAppWidget(
      tester,
      CodeInput(
        controller: controller,
        hasError: hasError,
        enabled: enabled,
        onCompleted: completed.add,
      ),
      locale: locale,
    );
    return completed;
  }

  group('CodeInput', () {
    testWidgets('draws one box per digit', (WidgetTester tester) async {
      await pumpCode(tester);

      expect(boxes(), findsNWidgets(6));
    });

    testWidgets('paints each typed digit into its own box',
        (WidgetTester tester) async {
      await pumpCode(tester);

      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('outlines the box the next digit lands in',
        (WidgetTester tester) async {
      await pumpCode(tester);

      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();

      expect(edgeOf(tester, 2).color, AppColors.borderBrand);
      expect(edgeOf(tester, 2).width, 2);
      expect(edgeOf(tester, 0).color, AppColors.borderDefault);
      expect(edgeOf(tester, 3).color, AppColors.borderDefault);
    });

    testWidgets('outlines every box in red for a wrong code',
        (WidgetTester tester) async {
      await pumpCode(tester, hasError: true);

      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();

      for (int i = 0; i < 6; i++) {
        expect(edgeOf(tester, i).color, AppColors.borderDanger, reason: '$i');
        // The error outranks the active box: the whole code was wrong, not
        // the next digit.
        expect(edgeOf(tester, i).width, 1, reason: '$i');
      }
    });

    testWidgets('hands over the code once the last box is filled',
        (WidgetTester tester) async {
      final List<String> completed = await pumpCode(tester);

      await tester.enterText(find.byType(TextField), '12345');
      expect(completed, isEmpty);

      await tester.enterText(find.byType(TextField), '123456');
      expect(completed, <String>['123456']);
    });

    testWidgets('accepts digits only, and no more than six',
        (WidgetTester tester) async {
      await pumpCode(tester);

      await tester.enterText(find.byType(TextField), '12a3456789');
      await tester.pump();

      expect(controller.text, '123456');
    });

    testWidgets('stops input while disabled', (WidgetTester tester) async {
      await pumpCode(tester, enabled: false);

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('keeps digit one on the left in Arabic',
        (WidgetTester tester) async {
      // A code is a number; the box a digit lands in must not move because
      // the interface language did.
      await pumpCode(tester, locale: arabicLocale);

      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();

      expect(
        tester.getCenter(find.text('1')).dx,
        lessThan(tester.getCenter(find.text('2')).dx),
      );
    });
  });
}
