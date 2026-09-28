import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/features/forgot_password/view_model/forgot_password_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  ForgotPasswordViewModel build({String? initialEmail}) {
    final ForgotPasswordViewModel viewModel = ForgotPasswordViewModel(
      auth: auth,
      initialEmail: initialEmail,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('ForgotPasswordViewModel', () {
    test('starts empty and unsubmittable', () {
      final ForgotPasswordViewModel viewModel = build();

      expect(viewModel.emailController.text, isEmpty);
      expect(viewModel.canSubmit, isFalse);
    });

    test('a prefilled address is submittable straight away', () {
      final ForgotPasswordViewModel viewModel = build(
        initialEmail: 'amina@example.com',
      );

      expect(viewModel.emailController.text, 'amina@example.com');
      expect(viewModel.canSubmit, isTrue);
    });

    test('sends the trimmed address and returns it for 10', () async {
      final ForgotPasswordViewModel viewModel = build();
      viewModel.emailController.text = ' amina@example.com ';

      final String? sentTo = await viewModel.sendCode();

      expect(auth.forgotten, <String>['amina@example.com']);
      // The server answers 202 whether or not there is an account, so the
      // user always moves on.
      expect(sentTo, 'amina@example.com');
    });

    test('an empty address is reported and nothing is sent', () async {
      final ForgotPasswordViewModel viewModel = build();

      expect(await viewModel.sendCode(), isNull);
      expect(viewModel.emailError, isA<EmailRequired>());
      expect(auth.forgotten, isEmpty);
    });

    test('an invalid address is reported and nothing is sent', () async {
      final ForgotPasswordViewModel viewModel = build();
      viewModel.emailController.text = 'amina@';

      expect(await viewModel.sendCode(), isNull);
      expect(viewModel.emailError, isA<EmailInvalid>());
      expect(auth.forgotten, isEmpty);
    });

    test('editing the address retires its error', () async {
      final ForgotPasswordViewModel viewModel = build();
      viewModel.emailController.text = 'amina@';
      await viewModel.sendCode();

      viewModel.emailController.text = 'amina@e';

      expect(viewModel.emailError, isNull);
    });

    test('is busy while the request is out', () async {
      final Completer<void> gate = Completer<void>();
      auth.gate = gate;
      final ForgotPasswordViewModel viewModel = build();
      viewModel.emailController.text = 'amina@example.com';

      final Future<String?> pending = viewModel.sendCode();
      expect(viewModel.isBusy, isTrue);

      gate.complete();
      expect(await pending, 'amina@example.com');
      expect(viewModel.isBusy, isFalse);
    });

    test(
      'a request that never arrived returns nothing and is reported',
      () async {
        auth.forgotError = const NetworkFailure();
        final ForgotPasswordViewModel viewModel = build();
        viewModel.emailController.text = 'amina@example.com';

        expect(await viewModel.sendCode(), isNull);
        expect(viewModel.failure, isA<NetworkFailure>());
      },
    );
  });
}
