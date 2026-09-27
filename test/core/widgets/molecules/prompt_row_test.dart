import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_spinner.dart';
import 'package:eventor/core/widgets/molecules/prompt_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  const String question = 'Already have an account ?';
  const String action = 'Log in';

  /// The size the given copy is actually painted at.
  double? sizeOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.fontSize;

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  group('PromptRow', () {
    testWidgets('sets the question and the action at the same size',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        PromptRow(question: question, actionLabel: action, onTap: () {}),
      );

      // The line is one sentence: only colour and weight may separate its
      // two halves.
      expect(sizeOf(tester, action), sizeOf(tester, question));
      expect(sizeOf(tester, action), isNotNull);
    });

    testWidgets('keeps them the same size in Arabic, on its own ramp',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        PromptRow(question: question, actionLabel: action, onTap: () {}),
        locale: arabicLocale,
      );

      expect(sizeOf(tester, action), sizeOf(tester, question));
    });

    testWidgets('colours the question grey and the action brand',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        PromptRow(question: question, actionLabel: action, onTap: () {}),
      );

      expect(colorOf(tester, question), AppColors.textSecondary);
      expect(colorOf(tester, action), AppColors.textBrand);
    });

    testWidgets('puts the action after the question in either language',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        PromptRow(question: question, actionLabel: action, onTap: () {}),
        locale: arabicLocale,
      );

      // After, in Arabic, is to the left.
      expect(
        tester.getCenter(find.text(action)).dx,
        lessThan(tester.getCenter(find.text(question)).dx),
      );
    });

    testWidgets('marks the action as a button', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        PromptRow(question: question, actionLabel: action, onTap: () {}),
      );

      expect(
        tester.getSemantics(find.text(action)),
        isSemantics(isButton: true, label: action),
      );
    });

    testWidgets('reports the tap', (WidgetTester tester) async {
      int taps = 0;
      await pumpAppWidget(
        tester,
        PromptRow(
          question: question,
          actionLabel: action,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.text(action));
      expect(taps, 1);
    });

    testWidgets('puts the spinner where the label was, not elsewhere',
        (WidgetTester tester) async {
      int taps = 0;
      await pumpAppWidget(
        tester,
        PromptRow(
          question: question,
          actionLabel: action,
          isLoading: true,
          onTap: () => taps++,
        ),
      );

      expect(find.text(action), findsNothing);
      expect(find.byType(AppSpinner), findsOneWidget);
      // The question stays put; only the action it belongs to changed.
      expect(find.text(question), findsOneWidget);

      // A second tap cannot start the work again while it is running.
      await tester.tap(find.byType(AppSpinner));
      expect(taps, 0);
    });

    testWidgets('still names the action while it spins',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        PromptRow(
          question: question,
          actionLabel: action,
          isLoading: true,
          onTap: () {},
        ),
      );

      final Semantics wrapper = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byType(AppSpinner),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(wrapper.properties.label, action);
      // Not a button while a tap would do nothing.
      expect(wrapper.properties.button, isFalse);
    });

    testWidgets('reads as plain copy when there is nothing to tap',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const PromptRow(
          question: question,
          actionLabel: action,
          onTap: null,
        ),
      );

      // No brand colour to promise something a tap would do.
      expect(colorOf(tester, action), colorOf(tester, question));
    });
  });
}
