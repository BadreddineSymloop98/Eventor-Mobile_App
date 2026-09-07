import 'package:eventor/core/constants/input_rules.dart';
import 'package:eventor/core/widgets/main_button.dart';
import 'package:eventor/core/widgets/app_text_field.dart';
import 'package:eventor/features/home/view/home_view.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/onboarding/view/onboarding_view.dart';
import 'package:eventor/features/splash/view/splash_view.dart';
import 'package:eventor/features/welcome/view/welcome_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_app.dart';

void main() {
  /// Walks through every onboarding section and out the other side.
  Future<void> completeOnboarding(WidgetTester tester) async {
    final AppLocalizations strings = l10n(tester);

    await tester.tap(find.text(strings.next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.getStarted));
    await tester.pumpAndSettle();
  }

  /// From the welcome screen through to the login form.
  Future<void> goToLogin(WidgetTester tester) async {
    await tester.tap(find.text(l10n(tester).welcomeHaveAccount));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byType(AppTextField).first, email);
    await tester.enterText(find.byType(AppTextField).last, password);
    // Let the button pick up that the form is now fillable before tapping it.
    await tester.pump();
    // Targeted at the button rather than at the copy, which a language is
    // free to share between the heading and the button.
    await tester.tap(find.widgetWithText(MainButton, l10n(tester).logIn));
    await tester.pumpAndSettle();
  }

  group('app flow', () {
    testWidgets('every launch opens on the splash', (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp());
      await tester.pump();

      // Before anything else, and regardless of what follows it.
      expect(find.byType(SplashView), findsOneWidget);
      expect(find.text(l10n(tester).splashTagline), findsOneWidget);

      await passSplash(tester);
      expect(find.byType(SplashView), findsNothing);
    });

    testWidgets('the splash hands over and cannot be returned to',
        (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp(hasSeenOnboarding: true));
      await passSplash(tester);
      await goToLogin(tester);

      // Replaced rather than pushed, so there is nothing underneath it.
      expect(find.byType(WelcomeView), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(WelcomeView))).canPop(),
        isFalse,
      );
    });

    testWidgets('first launch opens on onboarding', (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp());
      await passSplash(tester);

      expect(find.byType(OnboardingView), findsOneWidget);
      expect(
        find.text(l10n(tester).onboardingServicesTitle),
        findsOneWidget,
      );
    });

    testWidgets('later launches skip onboarding', (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp(hasSeenOnboarding: true));
      await passSplash(tester);
      await goToLogin(tester);

      expect(find.byType(OnboardingView), findsNothing);
      expect(find.byType(WelcomeView), findsOneWidget);
    });

    testWidgets('onboarding -> login -> home', (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp());
      await passSplash(tester);

      await completeOnboarding(tester);

      expect(find.byType(OnboardingView), findsNothing);
      expect(find.byType(WelcomeView), findsOneWidget);

      await goToLogin(tester);
      expect(find.text(l10n(tester).loginTitle), findsOneWidget);

      await signIn(tester, email: 'user@example.com', password: 'password');

      expect(find.byType(LoginView), findsNothing);
      expect(find.byType(HomeView), findsOneWidget);
      expect(find.text(l10n(tester).homeTitle), findsOneWidget);
    });

    testWidgets('the whole flow also works in Arabic',
        (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp(locale: arabicLocale));
      await passSplash(tester);

      // The layout mirrors, which is what the direction check below is for;
      // the flow itself must behave identically.
      expect(
        Directionality.of(tester.element(find.byType(OnboardingView))),
        TextDirection.rtl,
      );

      await completeOnboarding(tester);
      await goToLogin(tester);
      expect(find.byType(LoginView), findsOneWidget);

      await signIn(tester, email: 'user@example.com', password: 'password');

      expect(find.byType(HomeView), findsOneWidget);
    });

    testWidgets('Sign In stays disabled until both fields have a value',
        (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp(hasSeenOnboarding: true));
      await passSplash(tester);
      await goToLogin(tester);

      final AppLocalizations strings = l10n(tester);

      await tester.tap(find.widgetWithText(MainButton, strings.logIn));
      await tester.pumpAndSettle();

      // Nothing happened: not even a validation error.
      expect(find.text(strings.emailRequired), findsNothing);

      await tester.enterText(find.byType(AppTextField).first, 'user@example.com');
      await tester.pump();

      // Still disabled while the password is empty.
      await tester.tap(find.widgetWithText(MainButton, strings.logIn));
      await tester.pumpAndSettle();
      expect(find.byType(LoginView), findsOneWidget);

      await tester.enterText(find.byType(AppTextField).last, 'password');
      await tester.pump();
      await tester.tap(find.widgetWithText(MainButton, strings.logIn));
      await tester.pumpAndSettle();

      expect(find.byType(HomeView), findsOneWidget);
    });

    testWidgets('an invalid form cannot be submitted from the button',
        (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp(hasSeenOnboarding: true));
      await passSplash(tester);
      await goToLogin(tester);

      await tester.enterText(find.byType(AppTextField).first, 'nope');
      await tester.enterText(find.byType(AppTextField).last, 'abc');
      await tester.pump();

      await tester.tap(find.widgetWithText(MainButton, l10n(tester).logIn));
      await tester.pumpAndSettle();

      expect(find.byType(HomeView), findsNothing);
      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('submitting an invalid form from the keyboard shows why',
        (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp(hasSeenOnboarding: true));
      await passSplash(tester);
      await goToLogin(tester);

      await tester.enterText(find.byType(AppTextField).first, 'nope');
      await tester.enterText(find.byType(AppTextField).last, 'abc');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final AppLocalizations strings = l10n(tester);

      expect(find.byType(LoginView), findsOneWidget);
      expect(find.text(strings.emailInvalid), findsOneWidget);
      expect(
        find.text(strings.passwordTooShort(InputRules.minPasswordLength)),
        findsOneWidget,
      );
    });

    testWidgets('completing onboarding records that it was seen',
        (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp());
      await passSplash(tester);
      await completeOnboarding(tester);

      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      expect(preferences.getBool('has_seen_onboarding'), isTrue);
    });

    testWidgets('skipping onboarding also records it and goes to welcome',
        (WidgetTester tester) async {
      await tester.pumpWidget(await buildTestApp());
      await passSplash(tester);

      await tester.tap(find.text(l10n(tester).skip));
      await tester.pumpAndSettle();

      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      expect(preferences.getBool('has_seen_onboarding'), isTrue);
      expect(find.byType(WelcomeView), findsOneWidget);
    });
  });
}
