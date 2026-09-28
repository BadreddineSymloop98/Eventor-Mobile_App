import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/molecules/app_text_field.dart';
import 'package:eventor/features/forgot_password/view/forgot_password_view.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/reset_password/view/reset_code_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  /// Login, then 09 pushed over it — Back to log in pops to it.
  Future<TestApp> pumpForgot(WidgetTester tester, {Locale? locale}) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      locale: locale,
    );
    await startAt(tester, app, AppRoutes.login);
    app.services.router.push(AppRoutes.forgotPassword);
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordView), findsOneWidget);
    return app;
  }

  group('ForgotPasswordView (09)', () {
    testWidgets('asks for the address and waits for a valid one', (
      WidgetTester tester,
    ) async {
      await pumpForgot(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.forgotPasswordTitle), findsOneWidget);
      expect(isTappable(tester, strings.sendCode), isFalse);

      await typeInto(tester, find.byType(AppTextField), 'amina@example.com');
      expect(isTappable(tester, strings.sendCode), isTrue);
    });

    testWidgets('Send code asks for one and moves on to 10', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpForgot(tester);

      await typeInto(tester, find.byType(AppTextField), 'amina@example.com');
      await tapAndSettle(tester, button(l10n(tester).sendCode));

      expect(app.auth.forgotten, <String>['amina@example.com']);
      expect(find.byType(ResetCodeView), findsOneWidget);
      expect(
        find.text(l10n(tester).resetCodeSubtitle('amina@example.com')),
        findsOneWidget,
      );
    });

    testWidgets('a request that never arrived is toasted, and stays', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpForgot(tester);
      app.auth.forgotError = const NetworkFailure();

      await typeInto(tester, find.byType(AppTextField), 'amina@example.com');
      await tapAndSettle(tester, button(l10n(tester).sendCode));

      expect(find.text(l10n(tester).errorNetwork), findsOneWidget);
      expect(find.byType(ForgotPasswordView), findsOneWidget);
    });

    testWidgets('Back to log in returns to the form underneath', (
      WidgetTester tester,
    ) async {
      await pumpForgot(tester);

      await tapAndSettle(tester, button(l10n(tester).backToLogIn));

      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('keeps the address left to right in Arabic', (
      WidgetTester tester,
    ) async {
      await pumpForgot(tester, locale: arabicLocale);

      expect(
        Directionality.of(tester.element(find.byType(ForgotPasswordView))),
        TextDirection.rtl,
      );
      expect(
        tester.widget<AppTextField>(find.byType(AppTextField)).textDirection,
        TextDirection.ltr,
      );
    });
  });
}
