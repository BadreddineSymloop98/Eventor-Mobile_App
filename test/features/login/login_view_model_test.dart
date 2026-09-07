import 'package:eventor/core/constants/input_rules.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/features/login/view_model/login_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LoginViewModel viewModel;

  setUp(() => viewModel = LoginViewModel());
  tearDown(() => viewModel.dispose());

  Future<bool> signInWith({required String email, required String password}) {
    viewModel.emailController.text = email;
    viewModel.passwordController.text = password;
    return viewModel.signIn();
  }

  group('LoginViewModel validation', () {
    test('rejects an empty form', () async {
      expect(await signInWith(email: '', password: ''), isFalse);
      expect(viewModel.emailError, isA<EmailRequired>());
      expect(viewModel.passwordError, isA<PasswordRequired>());
    });

    test('rejects a malformed email', () async {
      expect(
        await signInWith(email: 'not-an-email', password: 'password'),
        isFalse,
      );
      expect(viewModel.emailError, isA<EmailInvalid>());
      expect(viewModel.passwordError, isNull);
    });

    test('rejects a password below the minimum length', () async {
      expect(
        await signInWith(email: 'user@example.com', password: 'abc'),
        isFalse,
      );
      expect(viewModel.emailError, isNull);
      expect(
        viewModel.passwordError,
        isA<PasswordTooShort>().having(
          (PasswordTooShort error) => error.minimumLength,
          'minimumLength',
          InputRules.minPasswordLength,
        ),
      );
    });

    test('ignores surrounding whitespace in the email', () async {
      expect(
        await signInWith(
          email: '  user@example.com  ',
          password: 'password',
        ),
        isTrue,
      );
      expect(viewModel.emailError, isNull);
    });

    test('clears earlier errors once the form is corrected', () async {
      await signInWith(email: '', password: '');
      expect(viewModel.emailError, isNotNull);

      expect(
        await signInWith(email: 'user@example.com', password: 'password'),
        isTrue,
      );
      expect(viewModel.emailError, isNull);
      expect(viewModel.passwordError, isNull);
    });
  });

  group('LoginViewModel sign-in', () {
    test('tracks the validity of each field as it is typed', () {
      expect(viewModel.isEmailValid, isFalse);
      expect(viewModel.isPasswordValid, isFalse);

      viewModel.emailController.text = 'user@example.com';
      expect(viewModel.isEmailValid, isTrue);
      expect(viewModel.isPasswordValid, isFalse);

      viewModel.passwordController.text = 'password';
      expect(viewModel.isPasswordValid, isTrue);
    });

    test('cannot be submitted until both fields match their format', () {
      expect(viewModel.canSubmit, isFalse);

      // A filled but malformed email is still not submittable.
      viewModel.emailController.text = 'not-an-email';
      viewModel.passwordController.text = 'password';
      expect(viewModel.canSubmit, isFalse);

      viewModel.emailController.text = 'user@example.com';
      expect(viewModel.canSubmit, isTrue);

      // A password that is too short takes it away again.
      viewModel.passwordController.text = 'abc';
      expect(viewModel.canSubmit, isFalse);
    });

    test('notifies only when a field flips between valid and invalid', () {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.emailController.text = 'u';
      viewModel.emailController.text = 'us';
      viewModel.emailController.text = 'use';
      expect(notifications, 0, reason: 'still invalid throughout');

      viewModel.emailController.text = 'user@example.com';
      expect(notifications, 1, reason: 'the email became valid');

      viewModel.emailController.text = 'user@example.co';
      expect(notifications, 1, reason: 'still valid, nothing changed');
    });

    test('accepts a valid form and reports no failure', () async {
      expect(
        await signInWith(email: 'user@example.com', password: 'password'),
        isTrue,
      );
      expect(viewModel.hasError, isFalse);
      expect(viewModel.failure, isNull);
      expect(viewModel.isBusy, isFalse);
    });

    test('notifies listeners when validation fails', () async {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      await signInWith(email: '', password: '');

      expect(notifications, greaterThan(0));
    });
  });
}
