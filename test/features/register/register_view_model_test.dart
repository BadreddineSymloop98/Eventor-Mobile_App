import 'package:eventor/core/constants/input_rules.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/features/register/view_model/register_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RegisterViewModel viewModel;

  setUp(() => viewModel = RegisterViewModel());
  tearDown(() => viewModel.dispose());

  /// Fills every field with a value that passes, so a test can spoil one of
  /// them and watch only that one's answer change.
  void fillValidForm() {
    viewModel.nameController.text = 'Zaki';
    viewModel.emailController.text = 'zaki@example.com';
    viewModel.phoneController.text = '0501234567';
    viewModel.passwordController.text = 'secret123';
  }

  group('RegisterViewModel per-field state', () {
    test('starts with nothing satisfied', () {
      expect(viewModel.isNameSatisfied, isFalse);
      expect(viewModel.isEmailSatisfied, isFalse);
      expect(viewModel.isPhoneSatisfied, isFalse);
      expect(viewModel.isPasswordSatisfied, isFalse);
      expect(viewModel.canSubmit, isFalse);
    });

    test('answers for each field independently as it is typed into', () {
      viewModel.nameController.text = 'Zaki';

      expect(viewModel.isNameSatisfied, isTrue);
      expect(viewModel.isEmailSatisfied, isFalse);
      expect(viewModel.canSubmit, isFalse);
    });

    test('holds off until a value actually meets its rule', () {
      // One letter is below the minimum, so the name is not satisfied yet.
      viewModel.nameController.text = 'Z';
      expect(viewModel.isNameSatisfied, isFalse);

      viewModel.nameController.text = 'Za';
      expect(viewModel.isNameSatisfied, isTrue);
    });

    test('wants a phone number of exactly the local length', () {
      viewModel.phoneController.text = '050123456';
      expect(viewModel.isPhoneSatisfied, isFalse);

      viewModel.phoneController.text = '0501234567';
      expect(viewModel.isPhoneSatisfied, isTrue);
    });

    test('turns away a phone number that does not open with a zero', () {
      // Ten digits, but not a local number — an international form pasted in
      // without its "+" would look like this.
      viewModel.phoneController.text = '9661234567';
      expect(viewModel.isPhoneSatisfied, isFalse);
    });

    test('reads through spacing a pasted number brought with it', () {
      viewModel.phoneController.text = '050 123 4567';
      expect(viewModel.isPhoneSatisfied, isTrue);
    });

    test('treats a half-typed address as unsatisfied', () {
      viewModel.emailController.text = 'zaki@ex';
      expect(viewModel.isEmailSatisfied, isFalse);

      viewModel.emailController.text = 'zaki@example.com';
      expect(viewModel.isEmailSatisfied, isTrue);
    });

    test('allows submission only once every field is satisfied', () {
      fillValidForm();

      expect(viewModel.isNameSatisfied, isTrue);
      expect(viewModel.isEmailSatisfied, isTrue);
      expect(viewModel.isPhoneSatisfied, isTrue);
      expect(viewModel.isPasswordSatisfied, isTrue);
      expect(viewModel.canSubmit, isTrue);
    });

    test('withdraws submission when a field is emptied again', () {
      fillValidForm();
      viewModel.phoneController.text = '';

      expect(viewModel.isPhoneSatisfied, isFalse);
      expect(viewModel.canSubmit, isFalse);
    });

    test('reports a bad phone number with the rule it broke', () async {
      fillValidForm();
      viewModel.phoneController.text = '1234567890';

      expect(await viewModel.submit(), isFalse);
      expect(
        viewModel.phoneError,
        isA<PhoneInvalid>()
            .having(
              (PhoneInvalid error) => error.requiredDigits,
              'requiredDigits',
              InputRules.phoneLength,
            )
            .having(
              (PhoneInvalid error) => error.leadingDigit,
              'leadingDigit',
              InputRules.phoneLeadingDigit,
            ),
      );
    });

    test('notifies when a single field flips, not only the whole form', () {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      // The form is nowhere near submittable, so the only thing that changed
      // is this one field — and the screen still has to hear about it to drop
      // the field's instruction.
      viewModel.nameController.text = 'Zaki';

      expect(notifications, greaterThan(0));
    });
  });
}
