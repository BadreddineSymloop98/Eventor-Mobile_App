import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/molecules/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

const String _helper = 'At least 10 characters, with a letter and a digit.';
const String _error = 'Enter your password.';

/// The box around the value.
BoxDecoration _box(WidgetTester tester) => tester
    .widget<AnimatedContainer>(find.descendant(
      of: find.byType(AppTextField),
      matching: find.byType(AnimatedContainer),
    ))
    .decoration! as BoxDecoration;

BorderSide _edge(WidgetTester tester) => (_box(tester).border! as Border).top;

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

Finder _icon(AppIcons icon) => find.byWidgetPredicate(
      (Widget widget) => widget is AppIcon && widget.icon == icon,
    );

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  /// Pumps one field and hands back its focus node so a test can drive it.
  Future<FocusNode> pumpField(
    WidgetTester tester, {
    String label = 'Password',
    String? helperText,
    String? errorText,
    String? hintText,
    bool enabled = true,
    bool obscureText = false,
    TextDirection? textDirection,
    Locale locale = englishLocale,
  }) async {
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await pumpAppWidget(
      tester,
      AppTextField(
        controller: controller,
        focusNode: focusNode,
        label: label,
        helperText: helperText,
        errorText: errorText,
        hintText: hintText,
        enabled: enabled,
        obscureText: obscureText,
        textDirection: textDirection,
      ),
      locale: locale,
    );

    return focusNode;
  }

  group('AppTextField message line', () {
    testWidgets('shows the helper in grey, focused or not',
        (WidgetTester tester) async {
      final FocusNode focusNode = await pumpField(tester, helperText: _helper);

      expect(find.text(_helper), findsOneWidget);
      expect(_colorOf(tester, _helper), AppColors.textSecondary);

      focusNode.requestFocus();
      await tester.pump();

      expect(find.text(_helper), findsOneWidget);
    });

    testWidgets('shows the error in red', (WidgetTester tester) async {
      await pumpField(tester, errorText: _error);

      expect(find.text(_error), findsOneWidget);
      expect(_colorOf(tester, _error), AppColors.statusDeclined);
    });

    testWidgets('replaces the helper with the error, never adds to it',
        (WidgetTester tester) async {
      await pumpField(tester, helperText: _helper, errorText: _error);

      expect(find.text(_error), findsOneWidget);
      expect(find.text(_helper), findsNothing);
    });

    testWidgets('says nothing when there is nothing to say',
        (WidgetTester tester) async {
      await pumpField(tester);

      expect(find.byType(Text), findsOneWidget); // The label, and only it.
    });
  });

  group('AppTextField box', () {
    testWidgets('is a thin grey outline at rest', (WidgetTester tester) async {
      await pumpField(tester);

      expect(_edge(tester).color, AppColors.borderDefault);
      expect(_edge(tester).width, 1);
      expect(_box(tester).color, AppColors.bgSurface);
      expect(_box(tester).boxShadow, isNull);
    });

    testWidgets('thickens to brand with a focus ring when focused',
        (WidgetTester tester) async {
      final FocusNode focusNode = await pumpField(tester);

      focusNode.requestFocus();
      await tester.pump();

      expect(_edge(tester).color, AppColors.borderBrand);
      expect(_edge(tester).width, 1.5);
      expect(_box(tester).boxShadow, AppElevation.focusRing);
    });

    testWidgets('thickens to red when wrong', (WidgetTester tester) async {
      await pumpField(tester, errorText: _error);

      expect(_edge(tester).color, AppColors.statusDeclined);
      expect(_edge(tester).width, 1.5);
    });

    testWidgets('stays red while focused, without the ring',
        (WidgetTester tester) async {
      // The error is what the user must notice; the brand focus colour would
      // hide it.
      final FocusNode focusNode = await pumpField(tester, errorText: _error);

      focusNode.requestFocus();
      await tester.pump();

      expect(_edge(tester).color, AppColors.statusDeclined);
      expect(_box(tester).boxShadow, isNull);
    });

    testWidgets('goes grey and stops input when disabled',
        (WidgetTester tester) async {
      controller.text = 'amina@example.com';
      await pumpField(tester, enabled: false);

      expect(_box(tester).color, AppColors.bgDisabled);
      expect(_edge(tester).width, 1);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(
        tester.widget<TextField>(find.byType(TextField)).style?.color,
        AppColors.textSecondary,
      );
    });

    testWidgets('does not show an error outline while disabled',
        (WidgetTester tester) async {
      await pumpField(tester, enabled: false, errorText: _error);

      expect(_edge(tester).color, AppColors.borderDefault);
    });
  });

  group('AppTextField password', () {
    testWidgets('starts hidden, with the eye to show it',
        (WidgetTester tester) async {
      await pumpField(tester, obscureText: true);

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
          isTrue);
      expect(_icon(AppIcons.eye), findsOneWidget);
      expect(_icon(AppIcons.eyeOff), findsNothing);
    });

    testWidgets('shows the value when the eye is tapped, and hides it again',
        (WidgetTester tester) async {
      await pumpField(tester, obscureText: true);

      await tester.tap(_icon(AppIcons.eye));
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
          isFalse);
      expect(_icon(AppIcons.eyeOff), findsOneWidget);

      await tester.tap(_icon(AppIcons.eyeOff));
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
          isTrue);
    });

    testWidgets('names what the eye will do', (WidgetTester tester) async {
      /// The label the toggle announces, read off its [Semantics].
      String? toggleLabel() => tester
          .widget<Semantics>(find
              .ancestor(
                of: find.byType(AppIcon),
                matching: find.byWidgetPredicate(
                  (Widget widget) =>
                      widget is Semantics && widget.properties.button == true,
                ),
              )
              .first)
          .properties
          .label;

      await pumpField(tester, obscureText: true);

      expect(toggleLabel(), l10n(tester).showPassword);

      await tester.tap(_icon(AppIcons.eye));
      await tester.pump();

      expect(toggleLabel(), l10n(tester).hidePassword);
    });

    testWidgets('keeps the eye shut while disabled',
        (WidgetTester tester) async {
      await pumpField(tester, obscureText: true, enabled: false);

      await tester.tap(_icon(AppIcons.eye));
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
          isTrue);
    });

    testWidgets('has no eye for an ordinary field',
        (WidgetTester tester) async {
      await pumpField(tester);

      expect(_icon(AppIcons.eye), findsNothing);
    });
  });

  group('AppTextField alignment', () {
    TextAlign alignOf(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).textAlign;

    testWidgets('starts the value on the left in English',
        (WidgetTester tester) async {
      await pumpField(tester, label: 'Email');

      expect(alignOf(tester), TextAlign.left);
    });

    testWidgets('starts the value on the right in Arabic',
        (WidgetTester tester) async {
      await pumpField(
        tester,
        label: 'البريد الإلكتروني',
        locale: arabicLocale,
      );

      expect(alignOf(tester), TextAlign.right);
    });

    testWidgets('keeps a Latin value on the Arabic side of the form',
        (WidgetTester tester) async {
      // The regression this guards: an address is laid out left to right, and
      // `TextAlign.start` resolves against *that*, so the field ended up flush
      // left while the name field beside it sat flush right.
      await pumpField(
        tester,
        label: 'البريد الإلكتروني',
        textDirection: TextDirection.ltr,
        locale: arabicLocale,
      );

      expect(alignOf(tester), TextAlign.right);
      // The value still reads left to right; only where it sits changed.
      expect(
        tester.widget<TextField>(find.byType(TextField)).textDirection,
        TextDirection.ltr,
      );
    });

    testWidgets('puts the eye on the left in Arabic',
        (WidgetTester tester) async {
      await pumpField(tester, obscureText: true, locale: arabicLocale);

      expect(
        tester.getCenter(_icon(AppIcons.eye)).dx,
        lessThan(tester.getCenter(find.byType(TextField)).dx),
      );
    });
  });

  group('AppTextField placeholder', () {
    testWidgets('shows the example while the field is empty',
        (WidgetTester tester) async {
      await pumpField(tester, label: 'Email', hintText: 'name@example.com');

      expect(find.text('name@example.com'), findsOneWidget);
    });

    testWidgets('gives the example up to the value',
        (WidgetTester tester) async {
      await pumpField(tester, label: 'Email', hintText: 'name@example.com');

      await tester.enterText(find.byType(TextField), 'zaki@example.com');
      await tester.pumpAndSettle();

      // Flutter keeps the hint in the tree (InputDecoration.maintainHintSize)
      // and fades it out, so "gone" means fully transparent, not absent.
      final AnimatedOpacity hintFade = tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.text('name@example.com'),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(hintFade.opacity, 0);
      expect(find.text('zaki@example.com'), findsOneWidget);
    });

    testWidgets('sits alongside the rule rather than repeating it',
        (WidgetTester tester) async {
      await pumpField(
        tester,
        label: 'Email',
        // The example shows the shape; the helper states the constraint.
        hintText: 'name@example.com',
        helperText: 'No spaces, and one @.',
      );

      expect(find.text('name@example.com'), findsOneWidget);
      expect(find.text('No spaces, and one @.'), findsOneWidget);
    });
  });
}
