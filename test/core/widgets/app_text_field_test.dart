import 'package:eventor/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  group('AppTextField', () {
    late TextEditingController controller;

    setUp(() => controller = TextEditingController());
    tearDown(() => controller.dispose());

    /// Pumps one field, optionally with an instruction and a validation
    /// message, and hands back the node so a test can drive focus itself.
    Future<FocusNode> pumpField(
      WidgetTester tester, {
      String? helperText,
      String? errorText,
    }) async {
      final FocusNode focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpAppWidget(
        tester,
        AppTextField(
          controller: controller,
          focusNode: focusNode,
          label: 'Password',
          helperText: helperText,
          errorText: errorText,
        ),
      );

      return focusNode;
    }

    testWidgets('keeps the instruction off screen until the field is focused',
        (WidgetTester tester) async {
      final FocusNode focusNode = await pumpField(
        tester,
        helperText: 'At least 6 characters, no spaces.',
      );

      expect(find.text('At least 6 characters, no spaces.'), findsNothing);

      focusNode.requestFocus();
      await tester.pump();

      expect(find.text('At least 6 characters, no spaces.'), findsOneWidget);
    });

    testWidgets('drops the instruction again when focus leaves',
        (WidgetTester tester) async {
      final FocusNode focusNode = await pumpField(
        tester,
        helperText: 'At least 6 characters, no spaces.',
      );

      focusNode.requestFocus();
      await tester.pump();
      focusNode.unfocus();
      await tester.pump();

      expect(find.text('At least 6 characters, no spaces.'), findsNothing);
    });

    testWidgets('shows nothing at all once the caller withdraws the '
        'instruction', (WidgetTester tester) async {
      // The caller passes `null` once the value satisfies the rule, so a
      // focused field with an acceptable value says nothing.
      final FocusNode focusNode = await pumpField(tester);

      focusNode.requestFocus();
      await tester.pump();

      expect(find.byType(Text), findsOneWidget); // The label, and only it.
    });

    testWidgets('shows the error whether or not the field is focused',
        (WidgetTester tester) async {
      await pumpField(tester, errorText: 'Enter your password.');

      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('prefers the error over the instruction',
        (WidgetTester tester) async {
      final FocusNode focusNode = await pumpField(
        tester,
        helperText: 'At least 6 characters, no spaces.',
        errorText: 'Enter your password.',
      );

      focusNode.requestFocus();
      await tester.pump();

      expect(find.text('Enter your password.'), findsOneWidget);
      expect(find.text('At least 6 characters, no spaces.'), findsNothing);
    });
  });
}
