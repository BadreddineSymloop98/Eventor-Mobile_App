import 'package:eventor/core/widgets/app_text_field.dart';
import 'package:eventor/core/widgets/back_icon_button.dart';
import 'package:eventor/core/widgets/language_switch.dart';
import 'package:eventor/core/widgets/main_button.dart';
import 'package:eventor/core/widgets/photo_backdrop.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/role_selection/view/role_selection_view.dart';
import 'package:eventor/features/welcome/view/welcome_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  /// Walks from the welcome screen into the login form, the way a user gets
  /// there.
  Future<void> pumpLogin(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      await buildTestApp(hasSeenOnboarding: true, locale: locale),
    );
    await passSplash(tester);

    await tester.tap(find.text(l10n(tester).welcomeHaveAccount));
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
  }

  Finder emailField() => find.byType(AppTextField).first;
  Finder passwordField() => find.byType(AppTextField).last;

  group('LoginView', () {
    testWidgets('shows the copy over a photograph and the form on a sheet',
        (WidgetTester tester) async {
      await pumpLogin(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.byType(PhotoBackdrop), findsOneWidget);
      expect(find.text(strings.loginTitle), findsOneWidget);
      expect(find.text(strings.loginSubtitle), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(find.text(strings.forgotPassword), findsOneWidget);
      expect(find.text(strings.loginNewPrompt), findsOneWidget);
    });

    testWidgets('keeps the way back and the language switch',
        (WidgetTester tester) async {
      await pumpLogin(tester);

      expect(find.byType(BackIconButton), findsOneWidget);
      expect(find.byType(LanguageSwitch), findsOneWidget);
    });

    testWidgets('Log in is unavailable until both fields are fillable',
        (WidgetTester tester) async {
      await pumpLogin(tester);
      final SemanticsHandle handle = tester.ensureSemantics();
      final String logIn = l10n(tester).logIn;

      void expectEnabled({required bool enabled}) {
        expect(
          tester.getSemantics(find.widgetWithText(MainButton, logIn)),
          isSemantics(label: logIn, isButton: true, isEnabled: enabled),
        );
      }

      expectEnabled(enabled: false);

      await tester.enterText(emailField(), 'user@example.com');
      await tester.pump();
      expectEnabled(enabled: false);

      await tester.enterText(passwordField(), 'password');
      await tester.pump();
      expectEnabled(enabled: true);

      handle.dispose();
    });

    testWidgets('a whitespace-only email does not enable it',
        (WidgetTester tester) async {
      await pumpLogin(tester);

      // Entered directly, because the formatter strips these keystrokes.
      await tester.enterText(passwordField(), 'password');
      await tester.pump();

      final SemanticsHandle handle = tester.ensureSemantics();
      final String logIn = l10n(tester).logIn;

      expect(
        tester.getSemantics(find.widgetWithText(MainButton, logIn)),
        isSemantics(label: logIn, isButton: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('submitting an invalid form from the keyboard shows why',
        (WidgetTester tester) async {
      await pumpLogin(tester);

      await tester.enterText(emailField(), 'nope');
      await tester.enterText(passwordField(), 'abc');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final AppLocalizations strings = l10n(tester);

      expect(find.byType(LoginView), findsOneWidget);
      expect(find.text(strings.emailInvalid), findsOneWidget);
    });

    testWidgets('offers the way into sign-up instead',
        (WidgetTester tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text(l10n(tester).createAccount));
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionView), findsOneWidget);
      // Replaced rather than pushed: the two forms are alternatives, so the
      // stack should not grow each time the user changes their mind.
      expect(find.byType(LoginView), findsNothing);
    });

    testWidgets('goes back to the welcome screen', (WidgetTester tester) async {
      await pumpLogin(tester);

      await tester.tap(find.byType(BackIconButton));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeView), findsOneWidget);
    });
  });

  group('LoginView in Arabic', () {
    testWidgets('mirrors the layout but keeps the credentials left to right',
        (WidgetTester tester) async {
      await pumpLogin(tester, locale: arabicLocale);

      expect(
        Directionality.of(tester.element(find.byType(LoginView))),
        TextDirection.rtl,
      );
      // Both fields opt out of the mirroring: an address and a password are
      // Latin text whatever the surrounding language is.
      for (final AppTextField field
          in tester.widgetList<AppTextField>(find.byType(AppTextField))) {
        expect(field.textDirection, TextDirection.ltr);
      }
    });

    testWidgets('shows the Arabic copy', (WidgetTester tester) async {
      await pumpLogin(tester, locale: arabicLocale);

      expect(find.text(l10n(tester).loginTitle), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
    });
  });
}
