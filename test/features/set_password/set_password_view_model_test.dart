import 'dart:async';

import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/features/set_password/view_model/set_password_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late SessionController session;

  setUp(() {
    auth = FakeAuthRepository();
    session = SessionController(auth);
  });

  SetPasswordViewModel build({
    String? token = 'invite-token',
    AppConfig config = const AppConfig(),
  }) {
    final SetPasswordViewModel viewModel = SetPasswordViewModel(
      auth: auth,
      session: session,
      config: config,
      token: token,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  SetPasswordViewModel filled({String? token = 'invite-token'}) {
    final SetPasswordViewModel viewModel = build(token: token);
    viewModel.passwordController.text = 'newsecret123';
    viewModel.confirmController.text = 'newsecret123';
    return viewModel;
  }

  group('SetPasswordViewModel link', () {
    test('a link with a token has no problem', () {
      expect(build().problem, isNull);
    });

    test('a link without a token is invalid from the start', () {
      expect(build(token: null).problem, InviteProblem.invalid);
      expect(build(token: '').problem, InviteProblem.invalid);
    });

    test('a dead link can never be submitted, even filled in', () async {
      final SetPasswordViewModel viewModel = filled(token: null);

      expect(viewModel.canSubmit, isFalse);
      await viewModel.submit();
      expect(auth.setPasswords, isEmpty);
    });

    test('offers support only when the config names an address', () {
      expect(build().supportEmail, isNull);
      expect(
        build(config: const AppConfig(supportEmail: 'help@eventor.dz'))
            .supportEmail,
        'help@eventor.dz',
      );
    });
  });

  group('SetPasswordViewModel validation', () {
    test('a password under the policy is refused before sending', () async {
      final SetPasswordViewModel viewModel = build();
      viewModel.passwordController.text = 'short1';
      viewModel.confirmController.text = 'short1';

      await viewModel.submit();

      expect(viewModel.passwordError, isA<PasswordTooShort>());
      expect(auth.setPasswords, isEmpty);
    });

    test('a confirmation that differs is a mismatch', () async {
      final SetPasswordViewModel viewModel = build();
      viewModel.passwordController.text = 'newsecret123';
      viewModel.confirmController.text = 'newsecret321';

      await viewModel.submit();

      expect(viewModel.confirmError, isA<PasswordMismatch>());
      expect(auth.setPasswords, isEmpty);
    });
  });

  group('SetPasswordViewModel submit', () {
    test('sets the password with the token and signs in', () async {
      final SetPasswordViewModel viewModel = filled();

      await viewModel.submit();

      expect(auth.setPasswords.single, (
        token: 'invite-token',
        password: 'newsecret123',
      ));
      expect(session.isSignedIn, isTrue);
      expect(session.user?.id, auth.user.id);
    });

    test('is busy while the request is out', () async {
      final Completer<void> gate = Completer<void>();
      auth.gate = gate;
      final SetPasswordViewModel viewModel = filled();

      final Future<void> pending = viewModel.submit();
      expect(viewModel.isBusy, isTrue);
      expect(viewModel.canSubmit, isFalse);

      gate.complete();
      await pending;
      expect(viewModel.isBusy, isFalse);
    });

    test('RESET_TOKEN_EXPIRED shows 10g', () async {
      auth.setPasswordError = apiFailure(
        ApiErrorCode.resetTokenExpired,
        statusCode: 410,
      );
      final SetPasswordViewModel viewModel = filled();

      await viewModel.submit();

      expect(viewModel.problem, InviteProblem.expired);
      expect(viewModel.canSubmit, isFalse);
      expect(viewModel.failure, isNull);
      expect(session.isSignedIn, isFalse);
    });

    test('RESET_TOKEN_INVALID says the link does not work', () async {
      auth.setPasswordError = apiFailure(
        ApiErrorCode.resetTokenInvalid,
        statusCode: 400,
      );
      final SetPasswordViewModel viewModel = filled();

      await viewModel.submit();

      expect(viewModel.problem, InviteProblem.invalid);
      expect(viewModel.failure, isNull);
    });

    test('PASSWORD_WEAK is an error on the password', () async {
      auth.setPasswordError = apiFailure(ApiErrorCode.passwordWeak);
      final SetPasswordViewModel viewModel = filled();

      await viewModel.submit();

      expect(viewModel.problem, isNull);
      expect(viewModel.passwordError, isA<PasswordWeak>());
      expect(viewModel.failure, isNull);
    });

    test('anything else is left for the view to report', () async {
      auth.setPasswordError = const NetworkFailure();
      final SetPasswordViewModel viewModel = filled();

      await viewModel.submit();

      expect(viewModel.problem, isNull);
      expect(viewModel.failure, isA<NetworkFailure>());
    });
  });
}
