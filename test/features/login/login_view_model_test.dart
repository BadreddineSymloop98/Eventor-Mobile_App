import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/features/login/view_model/login_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late SessionController session;

  setUp(() {
    auth = FakeAuthRepository();
    session = SessionController(auth);
  });

  LoginViewModel build({String? initialEmail, bool sessionExpired = false}) {
    final LoginViewModel viewModel = LoginViewModel(
      auth: auth,
      session: session,
      initialEmail: initialEmail,
      sessionExpired: sessionExpired,
    );
    // Also cancels a lock timer a test left running.
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  LoginViewModel filled({String password = 'secret12345'}) {
    final LoginViewModel viewModel = build();
    viewModel.emailController.text = ' amina@example.com ';
    viewModel.passwordController.text = password;
    return viewModel;
  }

  group('LoginViewModel start', () {
    test('starts empty, with no banner and nothing to submit', () {
      final LoginViewModel viewModel = build();

      expect(viewModel.emailController.text, isEmpty);
      expect(viewModel.problem, isNull);
      expect(viewModel.canSubmit, isFalse);
    });

    test('prefills the address it was handed', () {
      final LoginViewModel viewModel = build(initialEmail: 'amina@example.com');

      expect(viewModel.emailController.text, 'amina@example.com');
    });

    test('says the session ended when the router sent the user here', () {
      final LoginViewModel viewModel = build(sessionExpired: true);

      expect(viewModel.problem, LoginProblem.sessionExpired);
    });

    test('is submittable once there is an address and any password', () {
      final LoginViewModel viewModel = build();

      viewModel.emailController.text = 'amina@example.com';
      expect(viewModel.canSubmit, isFalse);

      viewModel.passwordController.text = 'x';
      expect(viewModel.canSubmit, isTrue);
    });
  });

  group('LoginViewModel signIn', () {
    test(
      'sends the trimmed address and hands the user to the session',
      () async {
        final LoginViewModel viewModel = filled();

        await viewModel.signIn();

        expect(auth.logins.single, (
          email: 'amina@example.com',
          password: 'secret12345',
        ));
        expect(session.isSignedIn, isTrue);
        expect(viewModel.problem, isNull);
      },
    );

    test(
      'has no password minimum — an old short password still goes',
      () async {
        final LoginViewModel viewModel = filled(password: 'ab1');

        await viewModel.signIn();

        expect(auth.logins.single.password, 'ab1');
        expect(viewModel.passwordError, isNull);
      },
    );

    test('an invalid address is caught before anything is sent', () async {
      final LoginViewModel viewModel = build();
      viewModel.emailController.text = 'amina';
      viewModel.passwordController.text = 'secret';

      await viewModel.signIn();

      expect(viewModel.emailError, isA<EmailInvalid>());
      expect(auth.logins, isEmpty);
    });

    test('an empty form reports both fields', () async {
      final LoginViewModel viewModel = build();

      await viewModel.signIn();

      expect(viewModel.emailError, isA<EmailRequired>());
      expect(viewModel.passwordError, isA<PasswordRequired>());
    });

    test(
      'is busy while the request is out, and ignores a second tap',
      () async {
        final Completer<void> gate = Completer<void>();
        auth.gate = gate;
        final LoginViewModel viewModel = filled();

        final Future<void> pending = viewModel.signIn();
        expect(viewModel.isBusy, isTrue);

        await viewModel.signIn();

        gate.complete();
        await pending;
        expect(viewModel.isBusy, isFalse);
        expect(auth.logins, hasLength(1));
      },
    );

    test('a new attempt retires the session-ended banner', () async {
      final LoginViewModel viewModel = build(sessionExpired: true);
      viewModel.emailController.text = 'amina@example.com';
      viewModel.passwordController.text = 'secret12345';

      await viewModel.signIn();

      expect(viewModel.problem, isNull);
    });
  });

  group('LoginViewModel server refusals', () {
    test(
      'INVALID_CREDENTIALS shows 07b and clears only the password',
      () async {
        auth.loginError = apiFailure(
          ApiErrorCode.invalidCredentials,
          statusCode: 401,
        );
        final LoginViewModel viewModel = filled();

        await viewModel.signIn();

        expect(viewModel.problem, LoginProblem.wrongCredentials);
        expect(viewModel.passwordController.text, isEmpty);
        expect(viewModel.emailController.text, ' amina@example.com ');
        expect(viewModel.failure, isNull);
        expect(session.isSignedIn, isFalse);
      },
    );

    test('typing a new password retires 07b', () async {
      auth.loginError = apiFailure(
        ApiErrorCode.invalidCredentials,
        statusCode: 401,
      );
      final LoginViewModel viewModel = filled();
      await viewModel.signIn();

      viewModel.passwordController.text = 'n';

      expect(viewModel.problem, isNull);
    });

    test(
      'EMAIL_NOT_VERIFIED shows 07c for the address the server echoes',
      () async {
        auth.loginError = apiFailure(
          ApiErrorCode.emailNotVerified,
          statusCode: 403,
          details: <String, Object?>{'email': 'amina@example.com'},
        );
        final LoginViewModel viewModel = filled();

        await viewModel.signIn();

        expect(viewModel.problem, LoginProblem.unverified);
        expect(viewModel.unverifiedEmail, 'amina@example.com');
        expect(viewModel.failure, isNull);
      },
    );

    test(
      'ACCOUNT_LOCKED shows 07d until the server\'s retryAfterSeconds',
      () async {
        auth.loginError = apiFailure(
          ApiErrorCode.accountLocked,
          statusCode: 423,
          details: <String, Object?>{'retryAfterSeconds': 600},
        );
        final LoginViewModel viewModel = filled();
        final DateTime before = DateTime.now();

        await viewModel.signIn();

        expect(viewModel.problem, LoginProblem.locked);
        expect(viewModel.isLocked, isTrue);
        expect(viewModel.canSubmit, isFalse);
        final Duration lockedFor = viewModel.lockedUntil!.difference(before);
        expect(lockedFor.inSeconds, inInclusiveRange(599, 601));
      },
    );

    test('nothing is sent while locked', () async {
      auth.loginError = apiFailure(
        ApiErrorCode.accountLocked,
        statusCode: 423,
        details: <String, Object?>{'retryAfterSeconds': 600},
      );
      final LoginViewModel viewModel = filled();
      await viewModel.signIn();
      viewModel.passwordController.text = 'another12345';

      await viewModel.signIn();

      expect(auth.logins, hasLength(1));
    });

    testWidgets('the lock lifts itself when the wait is over', (
      WidgetTester tester,
    ) async {
      auth.loginError = apiFailure(
        ApiErrorCode.accountLocked,
        statusCode: 423,
        details: <String, Object?>{'retryAfterSeconds': 30},
      );
      final LoginViewModel viewModel = LoginViewModel(
        auth: auth,
        session: session,
      );
      viewModel.emailController.text = 'amina@example.com';
      viewModel.passwordController.text = 'secret12345';
      await viewModel.signIn();

      await tester.pump(const Duration(seconds: 29));
      expect(viewModel.isLocked, isTrue);
      expect(viewModel.canSubmit, isFalse);

      await tester.pump(const Duration(seconds: 1));
      expect(viewModel.isLocked, isFalse);
      expect(viewModel.problem, isNull);
      expect(viewModel.canSubmit, isTrue);

      viewModel.dispose();
    });

    test('ACCOUNT_BLOCKED shows the admin\'s message', () async {
      auth.loginError = apiFailure(
        ApiErrorCode.accountBlocked,
        statusCode: 403,
        details: <String, Object?>{'message': 'Suspended pending review.'},
      );
      final LoginViewModel viewModel = filled();

      await viewModel.signIn();

      expect(viewModel.problem, LoginProblem.blocked);
      expect(viewModel.serverMessage, 'Suspended pending review.');
      expect(viewModel.failure, isNull);
    });

    test(
      'ACCOUNT_BLOCKED without details falls back to the server message',
      () async {
        auth.loginError = apiFailure(
          ApiErrorCode.accountBlocked,
          statusCode: 403,
          message: 'Account blocked.',
        );
        final LoginViewModel viewModel = filled();

        await viewModel.signIn();

        expect(viewModel.serverMessage, 'Account blocked.');
      },
    );

    test(
      'ROLE_NOT_ALLOWED_IN_APP says the account belongs elsewhere',
      () async {
        auth.loginError = apiFailure(
          ApiErrorCode.roleNotAllowedInApp,
          statusCode: 403,
          message: 'Admins use the dashboard.',
        );
        final LoginViewModel viewModel = filled();

        await viewModel.signIn();

        expect(viewModel.problem, LoginProblem.notAllowed);
        expect(viewModel.serverMessage, 'Admins use the dashboard.');
        expect(session.isSignedIn, isFalse);
      },
    );

    test('an unknown code is left for the view to report', () async {
      auth.loginError = apiFailure('SOMETHING_NEW', statusCode: 500);
      final LoginViewModel viewModel = filled();

      await viewModel.signIn();

      expect(viewModel.problem, isNull);
      expect(viewModel.failure, isA<ApiFailure>());
    });

    test('a network failure is left for the view to report', () async {
      auth.loginError = const NetworkFailure();
      final LoginViewModel viewModel = filled();

      await viewModel.signIn();

      expect(viewModel.problem, isNull);
      expect(viewModel.failure, isA<NetworkFailure>());
    });
  });

  group('LoginViewModel sendNewCode', () {
    Future<LoginViewModel> unverified() async {
      auth.loginError = apiFailure(
        ApiErrorCode.emailNotVerified,
        statusCode: 403,
        details: <String, Object?>{'email': 'amina@example.com'},
      );
      final LoginViewModel viewModel = filled();
      await viewModel.signIn();
      return viewModel;
    }

    test('typing a different address retires the banner', () async {
      // The banner names one account; its "Send a new code" must not go to
      // an address the user has since replaced.
      final LoginViewModel viewModel = await unverified();

      viewModel.emailController.text = 'other@example.com';

      expect(viewModel.problem, isNull);
      expect(viewModel.unverifiedEmail, isNull);
    });

    test(
      'sends a code to the unverified address and returns 10b\'s args',
      () async {
        auth.resendAfterSeconds = 75;
        final LoginViewModel viewModel = await unverified();

        final VerifyEmailArgs? args = await viewModel.sendNewCode();

        expect(auth.resends, <String>['amina@example.com']);
        expect(args, isNotNull);
        expect(args!.email, 'amina@example.com');
        expect(args.resendAfterSeconds, 75);
        expect(viewModel.isSendingCode, isFalse);
      },
    );

    test('is marked as sending while the request is out', () async {
      final LoginViewModel viewModel = await unverified();
      final Completer<void> gate = Completer<void>();
      auth.gate = gate;

      final Future<VerifyEmailArgs?> pending = viewModel.sendNewCode();
      expect(viewModel.isSendingCode, isTrue);

      gate.complete();
      await pending;
      expect(viewModel.isSendingCode, isFalse);
    });

    test(
      'CODE_RESEND_TOO_SOON still moves on — the last code is live',
      () async {
        final LoginViewModel viewModel = await unverified();
        auth.resendError = apiFailure(
          ApiErrorCode.codeResendTooSoon,
          statusCode: 429,
          details: <String, Object?>{'retryAfterSeconds': 20},
        );

        final VerifyEmailArgs? args = await viewModel.sendNewCode();

        expect(args, isNotNull);
        expect(args!.email, 'amina@example.com');
        expect(args.resendAfterSeconds, 20);
        expect(viewModel.failure, isNull);
      },
    );

    test('any other failure returns nothing and is left to the view', () async {
      final LoginViewModel viewModel = await unverified();
      auth.resendError = const NetworkFailure();

      expect(await viewModel.sendNewCode(), isNull);
      expect(viewModel.failure, isA<NetworkFailure>());
    });
  });
}
