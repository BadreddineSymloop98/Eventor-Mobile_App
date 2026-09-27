import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/features/auth/view/code_entry_sheet.dart';
import 'package:eventor/features/verify_email/view_model/verify_email_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const String email = 'amina@example.com';

  late FakeAuthRepository auth;
  late SessionController session;

  setUp(() {
    auth = FakeAuthRepository();
    session = SessionController(auth);
  });

  VerifyEmailViewModel build({int resendAfterSeconds = 60}) {
    final VerifyEmailViewModel viewModel = VerifyEmailViewModel(
      auth: auth,
      session: session,
      args: VerifyEmailArgs(
        email: email,
        resendAfterSeconds: resendAfterSeconds,
      ),
    );
    // Also stops the countdown's periodic timer.
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('VerifyEmailViewModel code entry', () {
    test('holds Verify until all six digits are in', () {
      final VerifyEmailViewModel viewModel = build();

      viewModel.codeController.text = '12345';
      expect(viewModel.canSubmit, isFalse);

      viewModel.codeController.text = '123456';
      expect(viewModel.canSubmit, isTrue);
    });

    test('an incomplete code is not sent', () async {
      final VerifyEmailViewModel viewModel = build();
      viewModel.codeController.text = '123';

      await viewModel.verify();

      expect(auth.verifications, isEmpty);
    });
  });

  group('VerifyEmailViewModel verify', () {
    test('a correct code signs a client in, landing home', () async {
      final VerifyEmailViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      await viewModel.verify();

      expect(auth.verifications.single, (email: email, code: '123456'));
      expect(session.isSignedIn, isTrue);
      // No one-off landing: the router's default, home.
      expect(session.landing, isNull);
    });

    test('a correct code sends a new provider to their documents', () async {
      auth.user = testUser(role: UserRole.provider);
      final VerifyEmailViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      await viewModel.verify();

      expect(session.user?.role, UserRole.provider);
      expect(session.landing, AppRoutes.documents);
    });

    test('is busy while the code is checked', () async {
      final Completer<void> gate = Completer<void>();
      auth.gate = gate;
      final VerifyEmailViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      final Future<void> pending = viewModel.verify();

      expect(viewModel.isBusy, isTrue);
      expect(viewModel.canSubmit, isFalse);

      gate.complete();
      await pending;
      expect(viewModel.isBusy, isFalse);
    });

    test('CODE_INVALID shows 10c and keeps the code to correct', () async {
      auth.verifyError = apiFailure(ApiErrorCode.codeInvalid);
      final VerifyEmailViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      await viewModel.verify();

      expect(viewModel.problem, CodeProblem.invalid);
      expect(viewModel.codeController.text, '123456');
      expect(viewModel.failure, isNull);
      expect(session.isSignedIn, isFalse);
    });

    test('editing the code retires 10c', () async {
      auth.verifyError = apiFailure(ApiErrorCode.codeInvalid);
      final VerifyEmailViewModel viewModel = build();
      viewModel.codeController.text = '123456';
      await viewModel.verify();

      viewModel.codeController.text = '12345';

      expect(viewModel.problem, isNull);
    });

    test(
      'CODE_EXPIRED shows 10d, clears the code and allows a resend now',
      () async {
        auth.verifyError = apiFailure(
          ApiErrorCode.codeExpired,
          statusCode: 410,
        );
        final VerifyEmailViewModel viewModel = build();
        expect(viewModel.canResend, isFalse);
        viewModel.codeController.text = '123456';

        await viewModel.verify();

        expect(viewModel.problem, CodeProblem.expired);
        expect(viewModel.codeController.text, isEmpty);
        expect(viewModel.canResend, isTrue);
        expect(viewModel.failure, isNull);
      },
    );

    test('an expiry survives editing — only a new code retires it', () async {
      auth.verifyError = apiFailure(ApiErrorCode.codeExpired, statusCode: 410);
      final VerifyEmailViewModel viewModel = build();
      viewModel.codeController.text = '123456';
      await viewModel.verify();

      viewModel.codeController.text = '1';

      expect(viewModel.problem, CodeProblem.expired);
    });

    test('anything else is left for the view to report', () async {
      auth.verifyError = const NetworkFailure();
      final VerifyEmailViewModel viewModel = build();
      viewModel.codeController.text = '123456';

      await viewModel.verify();

      expect(viewModel.problem, isNull);
      expect(viewModel.failure, isA<NetworkFailure>());
    });
  });

  group('VerifyEmailViewModel resend', () {
    test('starts on the cooldown the server gave with the first code', () {
      final VerifyEmailViewModel viewModel = build(resendAfterSeconds: 45);

      expect(viewModel.canResend, isFalse);
      expect(viewModel.resendSecondsLeft, 45);
      expect(viewModel.resendClock, '0:45');
    });

    test('is not sent while the cooldown runs', () async {
      final VerifyEmailViewModel viewModel = build();

      await viewModel.resend();

      expect(auth.resends, isEmpty);
    });

    test('sends a new code and restarts on the server\'s cooldown', () async {
      auth.resendAfterSeconds = 90;
      final VerifyEmailViewModel viewModel = build(resendAfterSeconds: 0);

      await viewModel.resend();

      expect(auth.resends, <String>[email]);
      expect(viewModel.resendSecondsLeft, 90);
      expect(viewModel.resendClock, '1:30');
      expect(viewModel.isResending, isFalse);
      // Read once, for the "new code on its way" toast.
      expect(viewModel.takeCodeSent(), isTrue);
      expect(viewModel.takeCodeSent(), isFalse);
    });

    test('a new code retires 10d', () async {
      auth.verifyError = apiFailure(ApiErrorCode.codeExpired, statusCode: 410);
      final VerifyEmailViewModel viewModel = build();
      viewModel.codeController.text = '123456';
      await viewModel.verify();

      await viewModel.resend();

      expect(viewModel.problem, isNull);
    });

    test(
      'CODE_RESEND_TOO_SOON waits out the server\'s retryAfterSeconds',
      () async {
        auth.resendError = apiFailure(
          ApiErrorCode.codeResendTooSoon,
          statusCode: 429,
          details: <String, Object?>{'retryAfterSeconds': 42},
        );
        final VerifyEmailViewModel viewModel = build(resendAfterSeconds: 0);

        await viewModel.resend();

        expect(viewModel.resendSecondsLeft, 42);
        expect(viewModel.failure, isNull);
        expect(viewModel.takeCodeSent(), isFalse);
      },
    );

    test('is marked as resending while the request is out', () async {
      final Completer<void> gate = Completer<void>();
      auth.gate = gate;
      final VerifyEmailViewModel viewModel = build(resendAfterSeconds: 0);

      final Future<void> pending = viewModel.resend();

      expect(viewModel.isResending, isTrue);
      gate.complete();
      await pending;
      expect(viewModel.isResending, isFalse);
    });

    testWidgets('the countdown ticks down once a second', (
      WidgetTester tester,
    ) async {
      final VerifyEmailViewModel viewModel = VerifyEmailViewModel(
        auth: auth,
        session: session,
        args: const VerifyEmailArgs(email: email, resendAfterSeconds: 3),
      );

      await tester.pump(const Duration(seconds: 1));
      expect(viewModel.resendSecondsLeft, 2);

      await tester.pump(const Duration(seconds: 2));
      expect(viewModel.canResend, isTrue);

      // Disposed here rather than in a tear-down, so no timer outlives the
      // test body.
      viewModel.dispose();
    });
  });
}
