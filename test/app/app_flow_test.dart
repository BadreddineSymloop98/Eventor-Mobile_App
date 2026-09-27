import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/widgets/molecules/app_text_field.dart';
import 'package:eventor/core/widgets/molecules/code_input.dart';
import 'package:eventor/core/widgets/molecules/inline_banner.dart';
import 'package:eventor/features/documents/view/documents_view.dart';
import 'package:eventor/features/home/view/home_view.dart';
import 'package:eventor/features/provider_home/view/provider_home_view.dart';
import 'package:eventor/features/shell/view/client_shell.dart';
import 'package:eventor/features/shell/view/provider_shell.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/onboarding/view/onboarding_view.dart';
import 'package:eventor/features/register/view/register_view.dart';
import 'package:eventor/features/reset_password/view/reset_code_view.dart';
import 'package:eventor/features/reset_password/view/reset_password_view.dart';
import 'package:eventor/features/role_selection/view/role_selection_view.dart';
import 'package:eventor/features/set_password/view/set_password_view.dart';
import 'package:eventor/features/splash/view/splash_view.dart';
import 'package:eventor/features/verify_email/view/verify_email_view.dart';
import 'package:eventor/features/welcome/view/welcome_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/feature_test_helpers.dart';
import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  const String email = 'amina@example.com';
  const String password = 'secret12345';

  Finder field(String label) => find.widgetWithText(AppTextField, label);

  /// A returning user who opens the app signed in as [user].
  Future<TestApp> startSignedIn(WidgetTester tester, AppUser user) async {
    final FakeAuthRepository auth = FakeAuthRepository()..restoredUser = user;
    final TestApp app = await buildTestApp(hasSeenOnboarding: true, auth: auth);
    await startApp(tester, app);
    return app;
  }

  /// Welcome → role → register for [role], with the form filled in.
  Future<void> signUpAs(WidgetTester tester, UserRole role) async {
    final AppLocalizations strings = l10n(tester);
    await tapAndSettle(tester, button(strings.createAccount));
    expect(find.byType(RoleSelectionView), findsOneWidget);

    await tapAndSettle(
      tester,
      find.text(
        role == UserRole.client
            ? strings.roleClientTitle
            : strings.roleProviderTitle,
      ),
    );
    await tapAndSettle(tester, button(strings.continueAction));
    expect(find.byType(RegisterView), findsOneWidget);

    await typeInto(tester, field(strings.nameLabel), 'Amina Benali');
    await typeInto(tester, field(strings.emailLabel), email);
    await typeInto(tester, field(strings.phoneLabel), '0555123456');
    await typeInto(tester, field(strings.passwordLabel), password);

    if (role == UserRole.provider) {
      await typeInto(tester, field(strings.businessNameLabel), 'Studio 21');
      await tapAndSettle(tester, find.text(strings.categoryPlaceholder));
      await tapAndSettle(tester, find.text('Photography'));
      await tapAndSettle(tester, find.text(strings.wilayasServedPlaceholder));
      await tapAndSettle(tester, find.text('16 — Alger'));
      await tapAndSettle(tester, button(strings.selectionDoneCount(1)));
    }

    await tapAndSettle(tester, button(strings.registerCreateAccount));
    expect(find.byType(VerifyEmailView), findsOneWidget);
  }

  /// Types a whole code into the six boxes, which submits it.
  Future<void> enterCode(WidgetTester tester) async {
    await tester.enterText(find.byType(CodeInput), '123456');
    await tester.pumpAndSettle();
  }

  Future<void> logIn(WidgetTester tester) async {
    final AppLocalizations strings = l10n(tester);
    await typeInto(tester, field(strings.emailLabel), email);
    await typeInto(tester, field(strings.passwordLabel), password);
    await tapAndSettle(tester, button(strings.logIn));
  }

  group('app start', () {
    testWidgets('opens on the splash until startup is ready', (
      WidgetTester tester,
    ) async {
      usePhoneSurface(tester);
      final TestApp app = await buildTestApp();
      await tester.pumpWidget(app.widget);
      await tester.pump();

      expect(find.byType(SplashView), findsOneWidget);
      expect(app.services.startup.isReady, isFalse);
    });

    testWidgets('first launch: onboarding, then welcome', (
      WidgetTester tester,
    ) async {
      final TestApp app = await buildTestApp();
      await startApp(tester, app);
      expect(find.byType(OnboardingView), findsOneWidget);

      final AppLocalizations strings = l10n(tester);
      await tapAndSettle(tester, button(strings.next));
      await tapAndSettle(tester, button(strings.next));
      await tapAndSettle(tester, button(strings.getStarted));

      expect(find.byType(WelcomeView), findsOneWidget);
      expect(app.services.preferences.hasSeenOnboarding, isTrue);
    });

    testWidgets('a returning user lands on welcome', (
      WidgetTester tester,
    ) async {
      await startApp(tester, await buildTestApp(hasSeenOnboarding: true));

      expect(find.byType(OnboardingView), findsNothing);
      expect(find.byType(WelcomeView), findsOneWidget);
    });

    testWidgets('Welcome is shown once, then launches open on login', (
      WidgetTester tester,
    ) async {
      final TestApp first = await buildTestApp(hasSeenOnboarding: true);
      await startApp(tester, first);
      expect(find.byType(WelcomeView), findsOneWidget);
      await tapAndSettle(tester, button(l10n(tester).welcomeHaveAccount));
      expect(first.services.preferences.hasSeenWelcome, isTrue);

      // The next launch, on the same stored preferences. The first app's tree
      // is torn down first so none of its state carries over.
      await tester.pumpWidget(const SizedBox());
      final TestApp next = await buildTestApp(
        hasSeenOnboarding: true,
        hasSeenWelcome: first.services.preferences.hasSeenWelcome,
      );
      await startApp(tester, next);

      expect(find.byType(WelcomeView), findsNothing);
      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('a restored session lands home', (WidgetTester tester) async {
      final TestApp app = await startSignedIn(tester, testUser());

      expect(find.byType(HomeView), findsOneWidget);
      // Home's header greets the client by name.
      expect(find.text('Amina Benali'), findsOneWidget);
      expect(app.session.isSignedIn, isTrue);
    });

    testWidgets('an invite link opened cold waits for the splash, then opens', (
      WidgetTester tester,
    ) async {
      // A first launch: without the link this would be onboarding.
      final TestApp app = await buildTestApp();
      await startApp(tester, app, deepLink: '/set-password?token=x');

      expect(find.byType(SetPasswordView), findsOneWidget);
      expect(find.byType(OnboardingView), findsNothing);

      final AppLocalizations strings = l10n(tester);
      await typeInto(tester, field(strings.newPasswordLabel), password);
      await typeInto(tester, field(strings.confirmPasswordLabel), password);
      await tapAndSettle(tester, button(strings.setPasswordAction));

      expect(app.auth.setPasswords.single.token, 'x');
      expect(find.byType(HomeView), findsOneWidget);
    });
  });

  group('sign-up', () {
    testWidgets('a client: role → register → confirm email → home', (
      WidgetTester tester,
    ) async {
      final TestApp app = await buildTestApp(hasSeenOnboarding: true);
      await startApp(tester, app);

      await signUpAs(tester, UserRole.client);
      await enterCode(tester);

      expect(app.auth.registrations.single.role, UserRole.client);
      expect(app.auth.verifications.single, (email: email, code: '123456'));
      expect(find.byType(HomeView), findsOneWidget);
      // A client has no review to wait for.
      expect(find.text(l10n(tester).providerFinishTitle), findsNothing);
    });

    testWidgets('a provider lands on their documents, then home', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository auth = FakeAuthRepository()
        ..user = testUser(role: UserRole.provider);
      final TestApp app = await buildTestApp(
        hasSeenOnboarding: true,
        auth: auth,
      );
      await startApp(tester, app);

      await signUpAs(tester, UserRole.provider);
      await enterCode(tester);

      expect(app.auth.registrations.single.role, UserRole.provider);
      expect(find.byType(DocumentsView), findsOneWidget);

      // "I'll do it later" — 21a then asks for what is still missing.
      await tapAndSettle(tester, button(l10n(tester).documentsLater));
      final AppLocalizations strings = l10n(tester);
      // The provider's own home — the client shell is not theirs.
      expect(find.byType(ProviderHomeView), findsOneWidget);
      expect(find.byType(ProviderShell), findsOneWidget);
      expect(find.byType(ClientShell), findsNothing);
      expect(find.text(strings.providerFinishTitle), findsOneWidget);
      expect(button(strings.homeUploadDocuments), findsOneWidget);
    });

    testWidgets('a wrong code on the way stops at 10c', (
      WidgetTester tester,
    ) async {
      final TestApp app = await buildTestApp(hasSeenOnboarding: true);
      app.auth.verifyError = apiFailure(ApiErrorCode.codeInvalid);
      await startApp(tester, app);

      await signUpAs(tester, UserRole.client);
      await enterCode(tester);

      expect(find.byType(VerifyEmailView), findsOneWidget);
      expect(find.text(l10n(tester).codeInvalidTitle), findsOneWidget);
      expect(app.session.isSignedIn, isFalse);
    });
  });

  group('log in and out', () {
    testWidgets('a wrong password shows 07b, the right one goes home', (
      WidgetTester tester,
    ) async {
      final TestApp app = await buildTestApp(hasSeenOnboarding: true);
      await startApp(tester, app);
      await tapAndSettle(tester, button(l10n(tester).welcomeHaveAccount));

      app.auth.loginError = apiFailure(
        ApiErrorCode.invalidCredentials,
        statusCode: 401,
      );
      await logIn(tester);
      expect(find.byType(LoginView), findsOneWidget);
      expect(
        find.widgetWithText(InlineBanner, l10n(tester).loginWrongTitle),
        findsOneWidget,
      );

      app.auth.loginError = null;
      await logIn(tester);

      expect(app.auth.logins, hasLength(2));
      expect(find.byType(HomeView), findsOneWidget);
      // The sign-in screens are gone from under it.
      expect(app.services.router.canPop(), isFalse);
    });

    testWidgets('logging out returns to welcome', (WidgetTester tester) async {
      final TestApp app = await startSignedIn(tester, testUser());

      // Log out lives on the Profile tab.
      await tapAndSettle(tester, find.text(l10n(tester).navProfile));
      await tapAndSettle(tester, button(l10n(tester).logOut));

      expect(app.auth.logoutCalls, 1);
      expect(app.session.isSignedIn, isFalse);
      expect(find.byType(WelcomeView), findsOneWidget);
    });

    testWidgets('a session that dies mid-use lands on login, explained', (
      WidgetTester tester,
    ) async {
      final TestApp app = await startSignedIn(tester, testUser());
      expect(find.byType(HomeView), findsOneWidget);

      app.session.expire();
      await tester.pumpAndSettle();

      expect(find.byType(LoginView), findsOneWidget);
      expect(
        find.widgetWithText(InlineBanner, l10n(tester).sessionExpiredTitle),
        findsOneWidget,
      );
    });
  });

  group('password reset', () {
    /// Welcome → login → 09 → 10, with a code sent to [email].
    Future<TestApp> reachResetCode(WidgetTester tester) async {
      final TestApp app = await buildTestApp(hasSeenOnboarding: true);
      await startApp(tester, app);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, button(strings.welcomeHaveAccount));
      await tapAndSettle(tester, button(strings.forgotPassword));
      await typeInto(tester, find.byType(AppTextField), email);
      await tapAndSettle(tester, button(strings.sendCode));

      expect(app.auth.forgotten, <String>[email]);
      expect(find.byType(ResetCodeView), findsOneWidget);
      return app;
    }

    Future<void> chooseNewPassword(WidgetTester tester) async {
      final AppLocalizations strings = l10n(tester);
      await typeInto(tester, field(strings.newPasswordLabel), 'newsecret123');
      await typeInto(
        tester,
        field(strings.confirmPasswordLabel),
        'newsecret123',
      );
      await tapAndSettle(tester, button(strings.resetPasswordAction));
    }

    testWidgets('forgot → code → new password → login, announced', (
      WidgetTester tester,
    ) async {
      final TestApp app = await reachResetCode(tester);

      await enterCode(tester);
      expect(find.byType(ResetPasswordView), findsOneWidget);

      await chooseNewPassword(tester);

      expect(app.auth.resets.single, (
        email: email,
        code: '123456',
        password: 'newsecret123',
      ));
      expect(find.byType(LoginView), findsOneWidget);
      expect(find.text(l10n(tester).passwordResetDone), findsOneWidget);
      expect(
        tester
            .widget<AppTextField>(field(l10n(tester).emailLabel))
            .controller
            .text,
        email,
      );
    });

    testWidgets('an expired code sends the user back to 10 to resend', (
      WidgetTester tester,
    ) async {
      final TestApp app = await reachResetCode(tester);
      app.auth.resetError = apiFailure(
        ApiErrorCode.codeExpired,
        statusCode: 410,
      );

      await enterCode(tester);
      await chooseNewPassword(tester);

      final AppLocalizations strings = l10n(tester);
      expect(find.byType(ResetCodeView), findsOneWidget);
      expect(find.text(strings.codeExpiredTitle), findsOneWidget);
      expect(find.text(strings.resend), findsOneWidget);
    });
  });
}
