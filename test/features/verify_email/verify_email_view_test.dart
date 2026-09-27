import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/molecules/app_text_field.dart';
import 'package:eventor/core/widgets/molecules/back_icon_button.dart';
import 'package:eventor/core/widgets/molecules/code_input.dart';
import 'package:eventor/core/widgets/molecules/inline_banner.dart';
import 'package:eventor/core/widgets/molecules/prompt_row.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/verify_email/view/verify_email_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  const String email = 'amina@example.com';

  Future<TestApp> pumpVerify(
    WidgetTester tester, {
    int resendAfterSeconds = 60,
    Locale? locale,
  }) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      locale: locale,
    );
    await startAt(
      tester,
      app,
      AppRoutes.verifyEmail,
      extra: VerifyEmailArgs(
        email: email,
        resendAfterSeconds: resendAfterSeconds,
      ),
    );
    expect(find.byType(VerifyEmailView), findsOneWidget);
    return app;
  }

  /// Types a whole code, which submits it on the last digit.
  Future<void> enterCode(WidgetTester tester, [String code = '123456']) async {
    await tester.enterText(find.byType(CodeInput), code);
    await tester.pumpAndSettle();
  }

  CodeInput codeInput(WidgetTester tester) =>
      tester.widget<CodeInput>(find.byType(CodeInput));

  group('VerifyEmailView (10b)', () {
    testWidgets('names the address and holds Resend for the cooldown', (
      WidgetTester tester,
    ) async {
      await pumpVerify(tester, resendAfterSeconds: 45);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.verifyEmailTitle), findsOneWidget);
      expect(find.text(strings.verifyEmailSubtitle(email)), findsOneWidget);
      expect(find.byType(InlineBanner), findsNothing);
      expect(find.text(strings.resendIn('0:45')), findsOneWidget);
      expect(isTappable(tester, strings.verifyAction), isFalse);
    });

    testWidgets('the countdown runs and then offers Resend', (
      WidgetTester tester,
    ) async {
      await pumpVerify(tester, resendAfterSeconds: 2);
      final AppLocalizations strings = l10n(tester);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text(strings.resendIn('0:01')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text(strings.resend), findsOneWidget);
    });

    testWidgets('a whole code is sent without reaching for the button', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpVerify(tester);

      await enterCode(tester);

      expect(app.auth.verifications.single, (email: email, code: '123456'));
    });

    testWidgets('10c: a wrong code outlines the boxes and says so', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpVerify(tester);
      app.auth.verifyError = apiFailure(ApiErrorCode.codeInvalid);

      await enterCode(tester);
      final AppLocalizations strings = l10n(tester);

      expect(
        find.widgetWithText(InlineBanner, strings.codeInvalidTitle),
        findsOneWidget,
      );
      expect(find.text(strings.codeInvalidBody), findsOneWidget);
      expect(codeInput(tester).hasError, isTrue);
    });

    testWidgets('10d: an expired code offers Resend straight away', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpVerify(tester);
      app.auth.verifyError = apiFailure(
        ApiErrorCode.codeExpired,
        statusCode: 410,
      );

      await enterCode(tester);
      final AppLocalizations strings = l10n(tester);

      expect(
        find.widgetWithText(InlineBanner, strings.codeExpiredTitle),
        findsOneWidget,
      );
      expect(find.text(strings.codeExpiredBody), findsOneWidget);
      // The boxes are emptied, not outlined: the code was fine, only old.
      expect(codeInput(tester).hasError, isFalse);
      expect(codeInput(tester).controller.text, isEmpty);
      expect(find.text(strings.resend), findsOneWidget);
    });

    testWidgets('Resend after 10d clears the banner and says a code is sent', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpVerify(tester);
      app.auth.verifyError = apiFailure(
        ApiErrorCode.codeExpired,
        statusCode: 410,
      );
      await enterCode(tester);

      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byType(PromptRow),
          matching: find.text(l10n(tester).resend),
        ),
      );
      final AppLocalizations strings = l10n(tester);

      expect(app.auth.resends, <String>[email]);
      expect(find.byType(InlineBanner), findsNothing);
      expect(find.text(strings.verifyCodeResent), findsOneWidget);
      expect(find.text(strings.resendIn('1:00')), findsOneWidget);
    });

    testWidgets('Back goes to Login with the address, not to the form', (
      WidgetTester tester,
    ) async {
      await pumpVerify(tester);

      await tapAndSettle(tester, find.byType(BackIconButton));

      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(VerifyEmailView), findsNothing);
      expect(
        tester
            .widget<AppTextField>(find.byType(AppTextField).first)
            .controller
            .text,
        email,
      );
    });

    testWidgets('without its arguments the route falls back to Login', (
      WidgetTester tester,
    ) async {
      final TestApp app = await buildTestApp(hasSeenOnboarding: true);
      await startAt(tester, app, AppRoutes.verifyEmail);

      expect(find.byType(LoginView), findsOneWidget);
    });
  });

  group('VerifyEmailView in Arabic', () {
    testWidgets('mirrors the sheet but keeps the digits left to right', (
      WidgetTester tester,
    ) async {
      await pumpVerify(tester, locale: arabicLocale);

      expect(
        Directionality.of(tester.element(find.byType(VerifyEmailView))),
        TextDirection.rtl,
      );
      expect(
        find.text(l10n(tester).verifyEmailSubtitle(email)),
        findsOneWidget,
      );
      // Digit one is the leftmost box whatever the language.
      final Finder boxes = find.descendant(
        of: find.byType(CodeInput),
        matching: find.byType(Row),
      );
      expect(Directionality.of(tester.element(boxes.first)), TextDirection.ltr);
    });
  });
}
