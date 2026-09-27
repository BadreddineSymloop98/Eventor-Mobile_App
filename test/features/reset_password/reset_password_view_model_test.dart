import 'dart:async';

import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/features/reset_password/view_model/reset_password_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const ResetPasswordArgs args = ResetPasswordArgs(
    email: 'amina@example.com',
    code: '123456',
  );

  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  ResetPasswordViewModel build({AppConfig config = const AppConfig()}) {
    final ResetPasswordViewModel viewModel = ResetPasswordViewModel(
      auth: auth,
      config: config,
      args: args,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  ResetPasswordViewModel filled({
    String password = 'newsecret123',
    String? confirm,
  }) {
    final ResetPasswordViewModel viewModel = build();
    viewModel.passwordController.text = password;
    viewModel.confirmController.text = confirm ?? password;
    return viewModel;
  }

  group('ResetPasswordViewModel validation', () {
    test('needs both fields before it can be submitted', () {
      final ResetPasswordViewModel viewModel = build();
      expect(viewModel.canSubmit, isFalse);

      viewModel.passwordController.text = 'newsecret123';
      expect(viewModel.canSubmit, isFalse);

      viewModel.confirmController.text = 'newsecret123';
      expect(viewModel.canSubmit, isTrue);
    });

    test('a password under the policy is refused before sending', () async {
      final ResetPasswordViewModel viewModel = filled(password: 'short1');

      expect(await viewModel.submit(), isNull);
      expect(viewModel.passwordError, isA<PasswordTooShort>());
      expect(auth.resets, isEmpty);
    });

    test('a password without a digit is refused before sending', () async {
      final ResetPasswordViewModel viewModel = filled(password: 'onlyletters');

      expect(await viewModel.submit(), isNull);
      expect(viewModel.passwordError, isA<PasswordNeedsLetterAndDigit>());
    });

    test('the policy comes from the config', () async {
      final ResetPasswordViewModel viewModel = build(
        config: const AppConfig(passwordMinLength: 16),
      );
      viewModel.passwordController.text = 'newsecret123';
      viewModel.confirmController.text = 'newsecret123';

      expect(viewModel.minPasswordLength, 16);
      expect(await viewModel.submit(), isNull);
      expect(viewModel.passwordError, isA<PasswordTooShort>());
    });

    test('a confirmation that differs is a mismatch', () async {
      final ResetPasswordViewModel viewModel = filled(confirm: 'newsecret124');

      expect(await viewModel.submit(), isNull);
      expect(viewModel.passwordError, isNull);
      expect(viewModel.confirmError, isA<PasswordMismatch>());
      expect(auth.resets, isEmpty);
    });

    test('editing either field retires the errors', () async {
      final ResetPasswordViewModel viewModel = filled(confirm: 'newsecret124');
      await viewModel.submit();

      viewModel.confirmController.text = 'newsecret123';

      expect(viewModel.confirmError, isNull);
    });
  });

  group('ResetPasswordViewModel submit', () {
    test('sends the address, the code and the new password', () async {
      final ResetPasswordViewModel viewModel = filled();

      final ResetOutcome? outcome = await viewModel.submit();

      expect(outcome, isA<ResetSucceeded>());
      expect(auth.resets.single, (
        email: 'amina@example.com',
        code: '123456',
        password: 'newsecret123',
      ));
    });

    test('is busy while the request is out', () async {
      final Completer<void> gate = Completer<void>();
      auth.gate = gate;
      final ResetPasswordViewModel viewModel = filled();

      final Future<ResetOutcome?> pending = viewModel.submit();
      expect(viewModel.isBusy, isTrue);
      expect(viewModel.canSubmit, isFalse);

      gate.complete();
      expect(await pending, isA<ResetSucceeded>());
    });

    test('CODE_INVALID sends the user back to 10 with that problem', () async {
      auth.resetError = apiFailure(ApiErrorCode.codeInvalid);
      final ResetPasswordViewModel viewModel = filled();

      final ResetOutcome? outcome = await viewModel.submit();

      expect(
        outcome,
        isA<ResetCodeRefused>().having(
          (ResetCodeRefused r) => r.problem,
          'problem',
          ResetCodeProblem.invalid,
        ),
      );
      expect(viewModel.failure, isNull);
    });

    test('CODE_EXPIRED sends the user back to 10 with that problem', () async {
      auth.resetError = apiFailure(ApiErrorCode.codeExpired, statusCode: 410);
      final ResetPasswordViewModel viewModel = filled();

      final ResetOutcome? outcome = await viewModel.submit();

      expect(
        outcome,
        isA<ResetCodeRefused>().having(
          (ResetCodeRefused r) => r.problem,
          'problem',
          ResetCodeProblem.expired,
        ),
      );
    });

    test('PASSWORD_WEAK stays here as an error on the password', () async {
      auth.resetError = apiFailure(ApiErrorCode.passwordWeak);
      final ResetPasswordViewModel viewModel = filled();

      expect(await viewModel.submit(), isNull);
      expect(viewModel.passwordError, isA<PasswordWeak>());
      expect(viewModel.failure, isNull);
    });

    test('anything else returns nothing and is left to the view', () async {
      auth.resetError = const NetworkFailure();
      final ResetPasswordViewModel viewModel = filled();

      expect(await viewModel.submit(), isNull);
      expect(viewModel.failure, isA<NetworkFailure>());
    });
  });
}
