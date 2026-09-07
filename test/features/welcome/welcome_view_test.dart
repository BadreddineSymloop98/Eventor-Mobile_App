import 'package:eventor/core/widgets/language_switch.dart';
import 'package:eventor/core/widgets/main_button.dart';
import 'package:eventor/core/widgets/photo_backdrop.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/welcome/view/welcome_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  /// Launches straight onto the welcome screen, which is where a returning
  /// user who has seen onboarding but has no session lands.
  Future<void> pumpWelcome(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      await buildTestApp(hasSeenOnboarding: true, locale: locale),
    );
    await passSplash(tester);
    expect(find.byType(WelcomeView), findsOneWidget);
  }

  group('WelcomeView', () {
    testWidgets('shows the brand, the copy and both ways in',
        (WidgetTester tester) async {
      await pumpWelcome(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.byType(PhotoBackdrop), findsOneWidget);
      expect(find.text(strings.welcomeTitle), findsOneWidget);
      expect(find.text(strings.welcomeSubtitle), findsOneWidget);
      expect(find.text(strings.createAccount), findsOneWidget);
      expect(find.text(strings.welcomeHaveAccount), findsOneWidget);
    });

    testWidgets('offers the language switch but no way back',
        (WidgetTester tester) async {
      await pumpWelcome(tester);

      expect(find.byType(LanguageSwitch), findsOneWidget);
      // The splash replaced itself, so this is the bottom of the stack.
      expect(
        Navigator.of(tester.element(find.byType(WelcomeView))).canPop(),
        isFalse,
      );
      expect(find.text(l10n(tester).skip), findsNothing);
    });

    testWidgets('draws the two actions with different weight',
        (WidgetTester tester) async {
      await pumpWelcome(tester);
      final AppLocalizations strings = l10n(tester);

      MainButton buttonWith(String label) =>
          tester.widget<MainButton>(find.widgetWithText(MainButton, label));

      // Creating an account is the action the screen is asking for; signing in
      // is the alternative, so it is outlined rather than filled.
      expect(
        buttonWith(strings.createAccount).style,
        MainButtonStyle.primary,
      );
      expect(
        buttonWith(strings.welcomeHaveAccount).style,
        MainButtonStyle.secondary,
      );
      // Both sit on a photograph.
      expect(
        buttonWith(strings.createAccount).tone,
        MainButtonTone.inverse,
      );
      expect(
        buttonWith(strings.welcomeHaveAccount).tone,
        MainButtonTone.inverse,
      );
    });

    testWidgets('goes to the login form, and can come back',
        (WidgetTester tester) async {
      await pumpWelcome(tester);

      await tester.tap(find.text(l10n(tester).welcomeHaveAccount));
      await tester.pumpAndSettle();

      expect(find.byType(LoginView), findsOneWidget);
      // Pushed rather than replaced: the user chose one of two doors and must
      // be able to go back and choose the other.
      expect(
        Navigator.of(tester.element(find.byType(LoginView))).canPop(),
        isTrue,
      );
    });
  });

  group('WelcomeView in Arabic', () {
    testWidgets('shows the Arabic copy and mirrors the layout',
        (WidgetTester tester) async {
      await pumpWelcome(tester, locale: arabicLocale);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.welcomeTitle), findsOneWidget);
      expect(find.text(strings.createAccount), findsOneWidget);
      expect(find.text('Let’s get started'), findsNothing);
      expect(
        Directionality.of(tester.element(find.byType(WelcomeView))),
        TextDirection.rtl,
      );
    });
  });
}
