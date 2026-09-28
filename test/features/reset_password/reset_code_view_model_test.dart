import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/features/auth/view/code_entry_sheet.dart';
import 'package:eventor/features/reset_password/view_model/reset_code_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const String email = 'amina@example.com';

  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  ResetCodeViewModel build() {
    final ResetCodeViewModel viewModel = ResetCodeViewModel(
      auth: auth,
      email: email,
    );
    // Also stops the countdown's periodic timer.
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  /// A view model whose code 10a reported expired, so Resend is open.
  ResetCodeViewModel resendable() {
    final ResetCodeViewModel viewModel = build();
    viewModel.reportProblem(ResetCodeProblem.expired);
    return viewModel;
  }

  group('ResetCodeViewModel verify', () {
    test('does nothing until six digits are entered', () async {
      final ResetCodeViewModel viewModel = build();

      viewModel.codeController.text = '12345';
      expect(viewModel.canSubmit, isFalse);
      expect(await viewModel.verify(), isNull);
      expect(auth.resetChecks, isEmpty);

      viewModel.codeController.text = '123456';
      expect(viewModel.canSubmit, isTrue);
    });

    test('checks the code, then carries it forward to 10a', () async {
      final ResetCodeViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      final ResetPasswordArgs? args = await viewModel.verify();

      expect(auth.resetChecks.single, (email: email, code: '123456'));
      expect(args, isNotNull);
      expect(args!.email, email);
      expect(args.code, '123456');
      // Checking does not reset anything.
      expect(auth.resets, isEmpty);
    });

    test('a wrong code stays here as 10c, the code kept to correct', () async {
      auth.verifyResetError = apiFailure(ApiErrorCode.codeInvalid);
      final ResetCodeViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      expect(await viewModel.verify(), isNull);

      expect(viewModel.problem, CodeProblem.invalid);
      expect(viewModel.codeController.text, '123456');
      expect(viewModel.failure, isNull);
    });

    test('an expired code clears it and opens Resend at once', () async {
      auth.verifyResetError = apiFailure(ApiErrorCode.codeExpired);
      final ResetCodeViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      expect(await viewModel.verify(), isNull);

      expect(viewModel.problem, CodeProblem.expired);
      expect(viewModel.codeController.text, isEmpty);
      expect(viewModel.canResend, isTrue);
      expect(viewModel.failure, isNull);
    });

    test('any other refusal is left for the view to report', () async {
      auth.verifyResetError = const NetworkFailure();
      final ResetCodeViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      expect(await viewModel.verify(), isNull);

      expect(viewModel.problem, isNull);
      expect(viewModel.failure, isA<NetworkFailure>());
      expect(viewModel.isBusy, isFalse);
    });
  });

  group('ResetCodeViewModel reportProblem', () {
    test('a wrong code shows 10c and keeps the code to correct', () {
      final ResetCodeViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      viewModel.reportProblem(ResetCodeProblem.invalid);

      expect(viewModel.problem, CodeProblem.invalid);
      expect(viewModel.codeController.text, '123456');
      expect(viewModel.canResend, isFalse);
    });

    test('editing the code retires 10c', () {
      final ResetCodeViewModel viewModel = build();
      viewModel.codeController.text = '123456';
      viewModel.reportProblem(ResetCodeProblem.invalid);

      viewModel.codeController.text = '12345';

      expect(viewModel.problem, isNull);
    });

    test('an expired code shows 10d, clears the code, and opens Resend', () {
      final ResetCodeViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      viewModel.reportProblem(ResetCodeProblem.expired);

      expect(viewModel.problem, CodeProblem.expired);
      expect(viewModel.codeController.text, isEmpty);
      expect(viewModel.canResend, isTrue);
    });
  });

  group('ResetCodeViewModel resend', () {
    test('starts on a 60-second cooldown — 09 has just sent a code', () {
      final ResetCodeViewModel viewModel = build();

      expect(viewModel.canResend, isFalse);
      expect(viewModel.resendSecondsLeft, 60);
      expect(viewModel.resendClock, '1:00');
    });

    test('is not sent while the cooldown runs', () async {
      final ResetCodeViewModel viewModel = build();

      await viewModel.resend();

      expect(auth.forgotten, isEmpty);
    });

    test(
      'asks for a new code through forgot-password and waits 60 s again',
      () async {
        final ResetCodeViewModel viewModel = resendable();

        await viewModel.resend();

        expect(auth.forgotten, <String>[email]);
        expect(viewModel.problem, isNull);
        expect(viewModel.resendSecondsLeft, 60);
        expect(viewModel.isResending, isFalse);
        expect(viewModel.takeCodeSent(), isTrue);
        expect(viewModel.takeCodeSent(), isFalse);
      },
    );

    test('is marked as resending while the request is out', () async {
      final ResetCodeViewModel viewModel = resendable();
      final Completer<void> gate = Completer<void>();
      auth.gate = gate;

      final Future<void> pending = viewModel.resend();
      expect(viewModel.isResending, isTrue);

      gate.complete();
      await pending;
      expect(viewModel.isResending, isFalse);
    });

    test('a failed request keeps Resend open and is reported', () async {
      auth.forgotError = const NetworkFailure();
      final ResetCodeViewModel viewModel = resendable();

      await viewModel.resend();

      expect(viewModel.failure, isA<NetworkFailure>());
      expect(viewModel.canResend, isTrue);
      expect(viewModel.takeCodeSent(), isFalse);
    });

    testWidgets('the cooldown runs out on its own', (
      WidgetTester tester,
    ) async {
      final ResetCodeViewModel viewModel = ResetCodeViewModel(
        auth: auth,
        email: email,
      );

      await tester.pump(const Duration(seconds: 59));
      expect(viewModel.resendClock, '0:01');

      await tester.pump(const Duration(seconds: 1));
      expect(viewModel.canResend, isTrue);

      viewModel.dispose();
    });
  });
}
