import 'package:eventor/core/constants/input_rules.dart';
import 'package:eventor/core/widgets/app_text_field.dart';
import 'package:eventor/features/register/view/register_view.dart';
import 'package:eventor/features/role_selection/view/widgets/role_card.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  /// Walks from the welcome screen into the register form, the way a user
  /// gets there: pick a role, then continue.
  Future<void> pumpRegister(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      await buildTestApp(hasSeenOnboarding: true, locale: locale),
    );
    await passSplash(tester);

    await tester.tap(find.text(l10n(tester).createAccount));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(RoleCard).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n(tester).continueAction));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterView), findsOneWidget);
  }

  Finder nameField() => find.byType(AppTextField).at(0);
  Finder emailField() => find.byType(AppTextField).at(1);
  Finder phoneField() => find.byType(AppTextField).at(2);
  Finder passwordField() => find.byType(AppTextField).at(3);

  group('RegisterView instructions', () {
    testWidgets('says nothing under any field until one is tapped into',
        (WidgetTester tester) async {
      await pumpRegister(tester);
      final AppLocalizations strings = l10n(tester);

      expect(
        find.text(strings.nameHint(InputRules.minNameLength)),
        findsNothing,
      );
      expect(find.text(strings.emailHint), findsNothing);
      expect(
        find.text(strings.phoneHint(
          InputRules.phoneLength,
          InputRules.phoneLeadingDigit,
        )),
        findsNothing,
      );
      expect(
        find.text(strings.passwordHint(InputRules.minPasswordLength)),
        findsNothing,
      );
    });

    testWidgets('states a field\'s rule the moment that field takes focus',
        (WidgetTester tester) async {
      await pumpRegister(tester);
      final AppLocalizations strings = l10n(tester);

      await tester.tap(nameField());
      await tester.pump();

      expect(
        find.text(strings.nameHint(InputRules.minNameLength)),
        findsOneWidget,
      );
      // Only the focused field explains itself.
      expect(find.text(strings.emailHint), findsNothing);
    });

    testWidgets('drops the rule as soon as the value meets it',
        (WidgetTester tester) async {
      await pumpRegister(tester);
      final AppLocalizations strings = l10n(tester);

      await tester.tap(nameField());
      await tester.pump();
      await tester.enterText(nameField(), 'Z');
      await tester.pump();

      // One letter is still short of the minimum, so the rule stands.
      expect(
        find.text(strings.nameHint(InputRules.minNameLength)),
        findsOneWidget,
      );

      await tester.enterText(nameField(), 'Zaki');
      await tester.pump();

      expect(
        find.text(strings.nameHint(InputRules.minNameLength)),
        findsNothing,
      );
    });

    testWidgets('keeps the rule up while a value is only half typed',
        (WidgetTester tester) async {
      await pumpRegister(tester);
      final AppLocalizations strings = l10n(tester);

      await tester.tap(emailField());
      await tester.pump();
      await tester.enterText(emailField(), 'zaki@ex');
      await tester.pump();

      expect(find.text(strings.emailHint), findsOneWidget);

      await tester.enterText(emailField(), 'zaki@example.com');
      await tester.pump();

      expect(find.text(strings.emailHint), findsNothing);
    });

    testWidgets('explains the phone and password rules too',
        (WidgetTester tester) async {
      await pumpRegister(tester);
      final AppLocalizations strings = l10n(tester);

      await tester.tap(phoneField());
      await tester.pump();
      expect(
        find.text(strings.phoneHint(
          InputRules.phoneLength,
          InputRules.phoneLeadingDigit,
        )),
        findsOneWidget,
      );

      await tester.tap(passwordField());
      await tester.pump();
      expect(
        find.text(strings.passwordHint(InputRules.minPasswordLength)),
        findsOneWidget,
      );
      // Focus moved on, so the phone's rule went with it.
      expect(
        find.text(strings.phoneHint(
          InputRules.phoneLength,
          InputRules.phoneLeadingDigit,
        )),
        findsNothing,
      );
    });

    testWidgets('states its rules in Arabic too', (WidgetTester tester) async {
      await pumpRegister(tester, locale: arabicLocale);
      final AppLocalizations strings = l10n(tester);

      await tester.tap(phoneField());
      await tester.pump();

      expect(
        find.text(strings.phoneHint(
          InputRules.phoneLength,
          InputRules.phoneLeadingDigit,
        )),
        findsOneWidget,
      );
    });
  });

  group('RegisterView keyboard', () {
    testWidgets('carries focus from each field to the next',
        (WidgetTester tester) async {
      await pumpRegister(tester);
      final AppLocalizations strings = l10n(tester);

      await tester.tap(nameField());
      await tester.pump();

      // The keyboard's action key on every field but the last is "next", and
      // it hands the caret to the field below.
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(find.text(strings.emailHint), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(
        find.text(strings.phoneHint(
          InputRules.phoneLength,
          InputRules.phoneLeadingDigit,
        )),
        findsOneWidget,
      );

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(
        find.text(strings.passwordHint(InputRules.minPasswordLength)),
        findsOneWidget,
      );
    });
  });
}
