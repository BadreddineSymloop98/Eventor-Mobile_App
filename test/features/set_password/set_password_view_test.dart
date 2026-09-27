import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/molecules/app_text_field.dart';
import 'package:eventor/core/widgets/molecules/back_icon_button.dart';
import 'package:eventor/core/widgets/molecules/inline_banner.dart';
import 'package:eventor/core/widgets/molecules/main_button.dart';
import 'package:eventor/features/home/view/home_view.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/set_password/view/set_password_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  const String supportAddress = 'help@eventor.dz';

  Future<TestApp> pumpSetPassword(
    WidgetTester tester, {
    String? token = 'invite-token',
    String? supportEmail,
    Locale? locale,
  }) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      locale: locale,
      config: AppConfig(supportEmail: supportEmail),
    );
    await startAt(
      tester,
      app,
      token == null
          ? AppRoutes.setPassword
          : '${AppRoutes.setPassword}?token=$token',
    );
    expect(find.byType(SetPasswordView), findsOneWidget);
    return app;
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    final AppLocalizations strings = l10n(tester);
    await typeInto(
      tester,
      find.widgetWithText(AppTextField, strings.newPasswordLabel),
      'newsecret123',
    );
    await typeInto(
      tester,
      find.widgetWithText(AppTextField, strings.confirmPasswordLabel),
      'newsecret123',
    );
    await tapAndSettle(tester, button(strings.setPasswordAction));
  }

  MainButton mainButton(WidgetTester tester, String label) =>
      tester.widget<MainButton>(button(label));

  group('SetPasswordView (10f)', () {
    testWidgets('a working link offers the two fields and no way back', (
      WidgetTester tester,
    ) async {
      await pumpSetPassword(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.setPasswordTitle), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(button(strings.setPasswordAction), findsOneWidget);
      expect(find.byType(InlineBanner), findsNothing);
      // Opened from an email, usually as the first screen: nothing behind it.
      expect(find.byType(BackIconButton), findsNothing);
      // No support address published, so no support link either.
      expect(button(strings.needHelpContactSupport), findsNothing);
    });

    testWidgets('offers help when the config names a support address', (
      WidgetTester tester,
    ) async {
      await pumpSetPassword(tester, supportEmail: supportAddress);

      expect(button(l10n(tester).needHelpContactSupport), findsOneWidget);
    });

    testWidgets('a new password signs the invitee in and goes home', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpSetPassword(tester);

      await fillAndSubmit(tester);

      expect(app.auth.setPasswords.single, (
        token: 'invite-token',
        password: 'newsecret123',
      ));
      expect(find.byType(HomeView), findsOneWidget);
    });

    testWidgets('PASSWORD_WEAK stays on the form with the reason', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpSetPassword(tester);
      app.auth.setPasswordError = apiFailure(ApiErrorCode.passwordWeak);

      await fillAndSubmit(tester);

      expect(find.text(l10n(tester).passwordWeak), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2));
    });
  });

  group('SetPasswordView problems (10g)', () {
    testWidgets('an expired link hides the fields and offers Back to log in', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpSetPassword(tester);
      app.auth.setPasswordError = apiFailure(
        ApiErrorCode.resetTokenExpired,
        statusCode: 410,
      );

      await fillAndSubmit(tester);
      final AppLocalizations strings = l10n(tester);

      expect(
        find.widgetWithText(InlineBanner, strings.inviteExpiredTitle),
        findsOneWidget,
      );
      expect(find.text(strings.inviteExpiredBody), findsOneWidget);
      // A dead link has nothing to type into.
      expect(find.byType(AppTextField), findsNothing);
      expect(button(strings.setPasswordAction), findsNothing);
      // Without a support address, the way out is the primary action.
      expect(button(strings.contactSupport), findsNothing);
      expect(
        mainButton(tester, strings.backToLogIn).style,
        MainButtonStyle.primary,
      );
    });

    testWidgets('an invalid link says it does not work', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpSetPassword(tester);
      app.auth.setPasswordError = apiFailure(
        ApiErrorCode.resetTokenInvalid,
        statusCode: 400,
      );

      await fillAndSubmit(tester);
      final AppLocalizations strings = l10n(tester);

      expect(
        find.widgetWithText(InlineBanner, strings.inviteInvalidTitle),
        findsOneWidget,
      );
      expect(find.byType(AppTextField), findsNothing);
    });

    testWidgets('a link without a token is invalid on arrival', (
      WidgetTester tester,
    ) async {
      await pumpSetPassword(tester, token: null);
      final AppLocalizations strings = l10n(tester);

      expect(
        find.widgetWithText(InlineBanner, strings.inviteInvalidTitle),
        findsOneWidget,
      );
      expect(find.byType(AppTextField), findsNothing);
      expect(button(strings.backToLogIn), findsOneWidget);
    });

    testWidgets('with a support address, Contact support leads', (
      WidgetTester tester,
    ) async {
      await pumpSetPassword(tester, token: null, supportEmail: supportAddress);
      final AppLocalizations strings = l10n(tester);

      expect(
        mainButton(tester, strings.contactSupport).style,
        MainButtonStyle.primary,
      );
      // Still a way out, but second to asking for help.
      expect(
        mainButton(tester, strings.backToLogIn).style,
        MainButtonStyle.ghost,
      );
      expect(button(strings.needHelpContactSupport), findsNothing);
    });

    testWidgets('Back to log in leaves for the login form', (
      WidgetTester tester,
    ) async {
      await pumpSetPassword(tester, token: null);

      await tapAndSettle(tester, button(l10n(tester).backToLogIn));

      expect(find.byType(LoginView), findsOneWidget);
    });
  });

  group('SetPasswordView in Arabic', () {
    testWidgets('mirrors the screen and reports the problem in Arabic', (
      WidgetTester tester,
    ) async {
      await pumpSetPassword(tester, token: null, locale: arabicLocale);
      final AppLocalizations strings = l10n(tester);

      expect(
        Directionality.of(tester.element(find.byType(SetPasswordView))),
        TextDirection.rtl,
      );
      expect(strings.localeName, 'ar');
      expect(find.text(strings.inviteInvalidTitle), findsOneWidget);
    });
  });
}
