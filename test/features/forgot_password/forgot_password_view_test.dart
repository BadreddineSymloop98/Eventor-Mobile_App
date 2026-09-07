import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/core/widgets/app_text_field.dart';
import 'package:eventor/core/widgets/back_icon_button.dart';
import 'package:eventor/core/widgets/main_button.dart';
import 'package:eventor/core/widgets/photo_sheet_layout.dart';
import 'package:eventor/features/forgot_password/view/forgot_password_view.dart';
import 'package:eventor/features/forgot_password/view_model/forgot_password_view_model.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  /// Walks from welcome through login into the reset form, the way a user
  /// gets there.
  Future<void> pumpForgotPassword(
    WidgetTester tester, {
    Locale? locale,
  }) async {
    await tester.pumpWidget(
      await buildTestApp(hasSeenOnboarding: true, locale: locale),
    );
    await passSplash(tester);

    await tester.tap(find.text(l10n(tester).welcomeHaveAccount));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n(tester).forgotPassword));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordView), findsOneWidget);
  }

  group('ForgotPasswordView', () {
    testWidgets('asks for one address and nothing else',
        (WidgetTester tester) async {
      await pumpForgotPassword(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.byType(PhotoSheetLayout), findsOneWidget);
      expect(find.text(strings.forgotPasswordTitle), findsOneWidget);
      expect(find.text(strings.forgotPasswordSubtitle), findsOneWidget);
      // One field: the whole point of the screen.
      expect(find.byType(AppTextField), findsOneWidget);
    });

    testWidgets('Send is unavailable until the address is plausible',
        (WidgetTester tester) async {
      await pumpForgotPassword(tester);
      final SemanticsHandle handle = tester.ensureSemantics();
      final String send = l10n(tester).sendResetLink;

      void expectEnabled({required bool enabled}) {
        expect(
          tester.getSemantics(find.widgetWithText(MainButton, send)),
          isSemantics(label: send, isButton: true, isEnabled: enabled),
        );
      }

      expectEnabled(enabled: false);

      await tester.enterText(find.byType(AppTextField), 'nope');
      await tester.pump();
      expectEnabled(enabled: false);

      await tester.enterText(find.byType(AppTextField), 'user@example.com');
      await tester.pump();
      expectEnabled(enabled: true);

      handle.dispose();
    });

    testWidgets('goes back to the login form it came from',
        (WidgetTester tester) async {
      await pumpForgotPassword(tester);

      await tester.tap(find.text(l10n(tester).backToLogIn));
      await tester.pumpAndSettle();

      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(ForgotPasswordView), findsNothing);
    });

    testWidgets('the back control returns to login too',
        (WidgetTester tester) async {
      await pumpForgotPassword(tester);

      await tester.tap(find.byType(BackIconButton));
      await tester.pumpAndSettle();

      expect(find.byType(LoginView), findsOneWidget);
    });
  });

  group('ForgotPasswordViewModel', () {
    late ForgotPasswordViewModel viewModel;

    setUp(() => viewModel = ForgotPasswordViewModel());
    tearDown(() => viewModel.dispose());

    test('rejects an empty address', () async {
      expect(await viewModel.sendResetLink(), isFalse);
      expect(viewModel.emailError, isA<EmailRequired>());
    });

    test('rejects a malformed address', () async {
      viewModel.emailController.text = 'not-an-email';
      expect(await viewModel.sendResetLink(), isFalse);
      expect(viewModel.emailError, isA<EmailInvalid>());
    });

    test('accepts a plausible one, ignoring surrounding whitespace', () async {
      viewModel.emailController.text = '  user@example.com  ';
      expect(await viewModel.sendResetLink(), isTrue);
      expect(viewModel.emailError, isNull);
    });

    test('notifies only when the answer changes', () {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.emailController.text = 'u';
      viewModel.emailController.text = 'us';
      expect(notifications, 0, reason: 'still not fillable');

      viewModel.emailController.text = 'user@example.com';
      expect(notifications, 1);
      expect(viewModel.canSubmit, isTrue);
    });
  });
}
