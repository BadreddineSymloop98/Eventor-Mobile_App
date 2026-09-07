import 'package:eventor/core/widgets/prompt_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  const String question = 'Already have an account ?';
  const String action = 'Log in';

  /// The size the given copy is actually painted at.
  double? sizeOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.fontSize;

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

    testWidgets('marks only the action as a button',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        PromptRow(question: question, actionLabel: action, onTap: () {}),
      );

      expect(
        tester.getSemantics(find.text(action)),
        matchesSemantics(isButton: true, label: action),
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
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The question stays put; only the action it belongs to changed.
      expect(find.text(question), findsOneWidget);

      // A second tap cannot start the work again while it is running.
      await tester.tap(find.byType(CircularProgressIndicator));
      expect(taps, 0);
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

      final Text label = tester.widget<Text>(find.text(action));
      final Text prompt = tester.widget<Text>(find.text(question));

      // No brand colour to promise something a tap would do.
      expect(label.style?.color, prompt.style?.color);
    });
  });
}
