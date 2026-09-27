import 'package:eventor/core/widgets/layout/photo_backdrop.dart';
import 'package:eventor/core/widgets/molecules/back_icon_button.dart';
import 'package:eventor/core/widgets/molecules/language_switch.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/role_selection/view/role_selection_view.dart';
import 'package:eventor/features/welcome/view/welcome_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  Future<TestApp> pumpWelcome(WidgetTester tester, {Locale? locale}) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      locale: locale,
    );
    await startApp(tester, app);
    expect(find.byType(WelcomeView), findsOneWidget);
    return app;
  }

  group('WelcomeView', () {
    testWidgets('asks the one question over a photograph', (
      WidgetTester tester,
    ) async {
      await pumpWelcome(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.byType(PhotoBackdrop), findsOneWidget);
      expect(find.text(strings.welcomeTitle), findsOneWidget);
      expect(find.text(strings.welcomeSubtitle), findsOneWidget);
      expect(button(strings.createAccount), findsOneWidget);
      expect(button(strings.welcomeHaveAccount), findsOneWidget);
      // The start of the auth flow: a language switch, and no way back.
      expect(find.byType(LanguageSwitch), findsOneWidget);
      expect(find.byType(BackIconButton), findsNothing);
    });

    testWidgets('Create account pushes role selection, and Back returns', (
      WidgetTester tester,
    ) async {
      await pumpWelcome(tester);

      await tapAndSettle(tester, button(l10n(tester).createAccount));
      expect(find.byType(RoleSelectionView), findsOneWidget);

      await tapAndSettle(tester, find.byType(BackIconButton));
      expect(find.byType(WelcomeView), findsOneWidget);
    });

    testWidgets('I have an account pushes the login form', (
      WidgetTester tester,
    ) async {
      await pumpWelcome(tester);

      await tapAndSettle(tester, button(l10n(tester).welcomeHaveAccount));

      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('is not remembered as seen until a door is taken', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpWelcome(tester);

      expect(app.services.preferences.hasSeenWelcome, isFalse);
    });

    testWidgets('Create account remembers Welcome as seen', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpWelcome(tester);

      await tapAndSettle(tester, button(l10n(tester).createAccount));

      expect(app.services.preferences.hasSeenWelcome, isTrue);
    });

    testWidgets('I have an account remembers Welcome as seen', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpWelcome(tester);

      await tapAndSettle(tester, button(l10n(tester).welcomeHaveAccount));

      expect(app.services.preferences.hasSeenWelcome, isTrue);
    });

    testWidgets('mirrors in Arabic', (WidgetTester tester) async {
      await pumpWelcome(tester, locale: arabicLocale);

      expect(
        Directionality.of(tester.element(find.byType(WelcomeView))),
        TextDirection.rtl,
      );
      expect(find.text(l10n(tester).welcomeTitle), findsOneWidget);
    });
  });
}
