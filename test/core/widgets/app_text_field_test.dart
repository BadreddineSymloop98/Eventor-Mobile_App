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

  group('AppTextField alignment', () {
    late TextEditingController controller;

    setUp(() => controller = TextEditingController());
    tearDown(() => controller.dispose());

    /// The rendered alignment of the field's value.
    TextAlign alignOf(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).textAlign;

    testWidgets('starts the value on the left in English',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        AppTextField(controller: controller, label: 'Email'),
      );

      expect(alignOf(tester), TextAlign.left);
    });

    testWidgets('starts the value on the right in Arabic',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        AppTextField(controller: controller, label: 'البريد الإلكتروني'),
        locale: arabicLocale,
      );

      expect(alignOf(tester), TextAlign.right);
    });

    testWidgets('keeps a Latin value on the Arabic side of the form',
        (WidgetTester tester) async {
      // The regression this guards: an address is laid out left to right, and
      // `TextAlign.start` resolves against *that*, so the field ended up flush
      // left while the name field beside it sat flush right.
      await pumpAppWidget(
        tester,
        AppTextField(
          controller: controller,
          label: 'البريد الإلكتروني',
          textDirection: TextDirection.ltr,
        ),
        locale: arabicLocale,
      );

      expect(alignOf(tester), TextAlign.right);
      // The value still reads left to right; only where it sits changed.
      expect(
        tester.widget<TextField>(find.byType(TextField)).textDirection,
        TextDirection.ltr,
      );
    });
  });

  group('AppTextField placeholder', () {
    late TextEditingController controller;

    setUp(() => controller = TextEditingController());
    tearDown(() => controller.dispose());

    testWidgets('shows the example while the field is empty',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        AppTextField(
          controller: controller,
          label: 'Email',
          hintText: 'name@example.com',
        ),
      );

      expect(find.text('name@example.com'), findsOneWidget);
    });

    testWidgets('gives the example up to the value', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        AppTextField(
          controller: controller,
          label: 'Email',
          hintText: 'name@example.com',
        ),
      );

      await tester.enterText(find.byType(TextField), 'zaki@example.com');
      await tester.pump();

      expect(find.text('name@example.com'), findsNothing);
      expect(find.text('zaki@example.com'), findsOneWidget);
    });

    testWidgets('sits alongside the rule rather than repeating it',
        (WidgetTester tester) async {
      final FocusNode focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpAppWidget(
        tester,
        AppTextField(
          controller: controller,
          focusNode: focusNode,
          label: 'Email',
          // The example shows the shape; the helper states the constraint.
          hintText: 'name@example.com',
          helperText: 'No spaces, and one @.',
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      expect(find.text('name@example.com'), findsOneWidget);
      expect(find.text('No spaces, and one @.'), findsOneWidget);
    });
  });
}
