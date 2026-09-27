import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/molecules/app_text_field.dart';
import 'package:eventor/core/widgets/molecules/back_icon_button.dart';
import 'package:eventor/core/widgets/molecules/inline_banner.dart';
import 'package:eventor/features/forgot_password/view/forgot_password_view.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/login/view_model/login_view_model.dart';
import 'package:eventor/features/role_selection/view/role_selection_view.dart';
import 'package:eventor/features/verify_email/view/verify_email_view.dart';
import 'package:eventor/features/welcome/view/welcome_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Only DateFormat: intl's own TextDirection would shadow Flutter's.
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  /// Welcome, then the login form pushed over it — the way a user arrives,
  /// so Back has somewhere to go. [query] is added to the login route.
  Future<TestApp> pumpLogin(
    WidgetTester tester, {
    Locale? locale,
    String location = AppRoutes.login,
  }) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      locale: locale,
    );
    await startApp(tester, app);
    app.services.router.push(location);
    await tester.pumpAndSettle();
    expect(find.byType(LoginView), findsOneWidget);
    return app;
  }

  Finder emailField() => find.byType(AppTextField).first;
  Finder passwordField() => find.byType(AppTextField).last;

  Future<void> signIn(
    WidgetTester tester, {
    String email = 'amina@example.com',
    String password = 'secret12345',
  }) async {
    await typeInto(tester, emailField(), email);
    await typeInto(tester, passwordField(), password);
    await tapAndSettle(tester, button(l10n(tester).logIn));
  }

  LoginViewModel viewModelOf(WidgetTester tester) =>
      tester.element(find.byType(LoginView)).read<LoginViewModel>();

  Finder banner(String title) => find.widgetWithText(InlineBanner, title);

  group('LoginView form', () {
    testWidgets('shows the form with no banner', (WidgetTester tester) async {
      await pumpLogin(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.loginTitle), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(find.byType(InlineBanner), findsNothing);
      expect(isTappable(tester, strings.logIn), isFalse);
    });

    testWidgets('Log in waits for an address and a password', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);
      final String logIn = l10n(tester).logIn;

      await typeInto(tester, emailField(), 'amina@example.com');
      expect(isTappable(tester, logIn), isFalse);

      // Any length: login has no password minimum.
      await typeInto(tester, passwordField(), 'a');
      expect(isTappable(tester, logIn), isTrue);
    });

    testWidgets('prefills the address from ?email=', (
      WidgetTester tester,
    ) async {
      await pumpLogin(
        tester,
        location: AppRoutes.loginWith(email: 'amina@example.com'),
      );

      expect(
        tester.widget<AppTextField>(emailField()).controller.text,
        'amina@example.com',
      );
    });

    testWidgets('a failure with no banner of its own is toasted', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpLogin(tester);
      app.auth.loginError = const NetworkFailure();

      await signIn(tester);

      expect(find.text(l10n(tester).errorNetwork), findsOneWidget);
      expect(find.byType(InlineBanner), findsNothing);
    });

    testWidgets('Forgot password pushes 09', (WidgetTester tester) async {
      await pumpLogin(tester);

      await tapAndSettle(tester, button(l10n(tester).forgotPassword));

      expect(find.byType(ForgotPasswordView), findsOneWidget);
    });

    testWidgets('Create account swaps the form for role selection', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);

      await tapAndSettle(tester, find.text(l10n(tester).createAccount));

      expect(find.byType(RoleSelectionView), findsOneWidget);
      expect(find.byType(LoginView), findsNothing);
    });

    testWidgets('Back returns to welcome', (WidgetTester tester) async {
      await pumpLogin(tester);

      await tapAndSettle(tester, find.byType(BackIconButton));

      expect(find.byType(WelcomeView), findsOneWidget);
    });

    group('as the landing, once Welcome has been seen', () {
      Future<void> launchOnLogin(WidgetTester tester) async {
        await startApp(
          tester,
          await buildTestApp(hasSeenOnboarding: true, hasSeenWelcome: true),
        );
        expect(find.byType(LoginView), findsOneWidget);
      }

      testWidgets('opens with no Back, since nothing is behind it', (
        WidgetTester tester,
      ) async {
        await launchOnLogin(tester);

        expect(find.byType(WelcomeView), findsNothing);
        expect(find.byType(BackIconButton), findsNothing);
      });

      testWidgets('Create account opens role selection, and Back returns', (
        WidgetTester tester,
      ) async {
        await launchOnLogin(tester);

        await tapAndSettle(tester, find.text(l10n(tester).createAccount));
        expect(find.byType(RoleSelectionView), findsOneWidget);

        await tapAndSettle(tester, find.byType(BackIconButton));
        expect(find.byType(LoginView), findsOneWidget);
        expect(find.byType(BackIconButton), findsNothing);
      });

      testWidgets('keeps Back hidden after a screen on top is closed', (
        WidgetTester tester,
      ) async {
        // canPop is asked of Login's own route: while Forgot password sits
        // on top the router can pop, but Login still cannot.
        await launchOnLogin(tester);

        await tapAndSettle(tester, find.text(l10n(tester).forgotPassword));
        expect(find.byType(ForgotPasswordView), findsOneWidget);
        await tapAndSettle(tester, find.byType(BackIconButton));

        expect(find.byType(LoginView), findsOneWidget);
        expect(find.byType(BackIconButton), findsNothing);
      });
    });

    testWidgets('arriving from a reset says the password was updated', (
      WidgetTester tester,
    ) async {
      await pumpLogin(
        tester,
        location: AppRoutes.loginWith(
          email: 'amina@example.com',
          afterReset: true,
        ),
      );

      expect(find.text(l10n(tester).passwordResetDone), findsOneWidget);
    });
  });

  group('LoginView banners', () {
    testWidgets('07b: wrong email or password clears the password', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpLogin(tester);
      app.auth.loginError = apiFailure(
        ApiErrorCode.invalidCredentials,
        statusCode: 401,
      );

      await signIn(tester);
      final AppLocalizations strings = l10n(tester);

      expect(banner(strings.loginWrongTitle), findsOneWidget);
      expect(find.text(strings.loginWrongBody), findsOneWidget);
      expect(
        tester.widget<AppTextField>(passwordField()).controller.text,
        isEmpty,
      );
    });

    testWidgets('07c: unverified offers a new code and goes to 10b', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpLogin(tester);
      app.auth.loginError = apiFailure(
        ApiErrorCode.emailNotVerified,
        statusCode: 403,
        details: <String, Object?>{'email': 'amina@example.com'},
      );

      await signIn(tester);
      final AppLocalizations strings = l10n(tester);

      expect(banner(strings.loginUnverifiedTitle), findsOneWidget);
      expect(
        find.text(strings.loginUnverifiedBody('amina@example.com')),
        findsOneWidget,
      );

      await tapAndSettle(tester, find.text(strings.loginSendNewCode));

      expect(app.auth.resends, <String>['amina@example.com']);
      expect(find.byType(VerifyEmailView), findsOneWidget);
    });

    testWidgets('07d: locked shows the time and holds the button', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpLogin(tester);
      app.auth.loginError = apiFailure(
        ApiErrorCode.accountLocked,
        statusCode: 423,
        details: <String, Object?>{'retryAfterSeconds': 30},
      );

      await signIn(tester);
      final AppLocalizations strings = l10n(tester);
      final String clock = DateFormat.jm('en')
          .format(viewModelOf(tester).lockedUntil!);

      expect(banner(strings.loginLockedTitle), findsOneWidget);
      expect(find.text(strings.loginLockedBody(clock)), findsOneWidget);
      // The button states when it comes back rather than just greying out.
      expect(button(strings.loginTryAgainAt(clock)), findsOneWidget);
      expect(isTappable(tester, strings.loginTryAgainAt(clock)), isFalse);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(button(strings.logIn), findsOneWidget);
      expect(isTappable(tester, strings.logIn), isTrue);
      expect(find.byType(InlineBanner), findsNothing);
    });

    testWidgets('blocked shows the admin\'s message', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpLogin(tester);
      app.auth.loginError = apiFailure(
        ApiErrorCode.accountBlocked,
        statusCode: 403,
        details: <String, Object?>{'message': 'Suspended pending review.'},
      );

      await signIn(tester);

      expect(banner(l10n(tester).loginBlockedTitle), findsOneWidget);
      expect(find.text('Suspended pending review.'), findsOneWidget);
    });

    testWidgets('an admin account is told the app is not for it', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpLogin(tester);
      app.auth.loginError = apiFailure(
        ApiErrorCode.roleNotAllowedInApp,
        statusCode: 403,
        message: 'Admins use the dashboard.',
      );

      await signIn(tester);

      expect(banner(l10n(tester).loginNotAllowedTitle), findsOneWidget);
      expect(find.text('Admins use the dashboard.'), findsOneWidget);
    });

    testWidgets('an ended session is explained, as information', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester, location: '${AppRoutes.login}?expired=1');
      final AppLocalizations strings = l10n(tester);

      final Finder expired = banner(strings.sessionExpiredTitle);
      expect(expired, findsOneWidget);
      expect(find.text(strings.sessionExpiredBody), findsOneWidget);
      expect(tester.widget<InlineBanner>(expired).tone, InlineBannerTone.info);
    });
  });

  group('LoginView in Arabic', () {
    testWidgets('mirrors the layout but keeps the credentials left to right', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester, locale: arabicLocale);

      expect(
        Directionality.of(tester.element(find.byType(LoginView))),
        TextDirection.rtl,
      );
      for (final AppTextField field in tester.widgetList<AppTextField>(
        find.byType(AppTextField),
      )) {
        expect(field.textDirection, TextDirection.ltr);
      }
    });

    testWidgets('reports a wrong password in Arabic', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpLogin(tester, locale: arabicLocale);
      app.auth.loginError = apiFailure(
        ApiErrorCode.invalidCredentials,
        statusCode: 401,
      );

      await signIn(tester);
      final AppLocalizations strings = l10n(tester);

      expect(strings.localeName, 'ar');
      expect(banner(strings.loginWrongTitle), findsOneWidget);
      expect(find.text(strings.loginWrongBody), findsOneWidget);
    });
  });
}
