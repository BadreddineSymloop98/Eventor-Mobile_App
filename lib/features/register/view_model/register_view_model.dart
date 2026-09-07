import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/validation_error.dart';
import '../../role_selection/model/user_role.dart';

/// Drives the register form.
///
/// It owns the four fields, their focus nodes, the validation results and the
/// sign-up call, so the form can be tested without building a widget.
///
/// Validation runs twice over, the same way the login form does. As the user
/// types it answers "is this field valid yet?", which is what enables the
/// button. On submit it runs again to produce the messages — a value set
/// programmatically bypasses both the formatters and the listeners.
class RegisterViewModel extends BaseViewModel {
  RegisterViewModel({this.role}) {
    for (final TextEditingController controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  /// How long the fake sign-up takes.
  ///
  /// There is no backend yet, so this stands in for the round trip. It is long
  /// enough that the button's busy state is actually visible, which is the
  /// point of simulating it at all.
  static const Duration _fakeRequestDuration = Duration(seconds: 3);

  /// Chosen on the previous screen and carried here, because it is saved with
  /// the account rather than on its own.
  final UserRole? role;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  late final List<TextEditingController> _controllers = <TextEditingController>[
    nameController,
    emailController,
    phoneController,
    passwordController,
  ];

  NameError? _nameError;
  EmailError? _emailError;
  PhoneError? _phoneError;
  PasswordError? _passwordError;

  bool _isNameSatisfied = false;
  bool _isEmailSatisfied = false;
  bool _isPhoneSatisfied = false;
  bool _isPasswordSatisfied = false;

  NameError? get nameError => _nameError;
  EmailError? get emailError => _emailError;
  PhoneError? get phoneError => _phoneError;
  PasswordError? get passwordError => _passwordError;

  /// Whether each field's value already meets its format, answered on every
  /// keystroke rather than only on submit.
  ///
  /// The form shows a field's rule while the field is being typed into, and
  /// these are what tell it the rule has been met and the instruction can go.
  bool get isNameSatisfied => _isNameSatisfied;
  bool get isEmailSatisfied => _isEmailSatisfied;
  bool get isPhoneSatisfied => _isPhoneSatisfied;
  bool get isPasswordSatisfied => _isPasswordSatisfied;

  /// Whether every field currently satisfies its format, and the button may
  /// therefore be tapped.
  bool get canSubmit =>
      _isNameSatisfied &&
      _isEmailSatisfied &&
      _isPhoneSatisfied &&
      _isPasswordSatisfied &&
      !isBusy;

  /// Moves the keyboard from one field to the next.
  void moveFocusToEmail() => emailFocusNode.requestFocus();
  void moveFocusToPhone() => phoneFocusNode.requestFocus();
  void moveFocusToPassword() => passwordFocusNode.requestFocus();

  /// Validates the form and creates the account.
  ///
  /// Returns whether the caller should report success.
  Future<bool> submit() async {
    if (!_validate()) return false;

    final bool? succeeded = await runGuarded(_createAccount);
    return succeeded ?? false;
  }

  /// Placeholder for the real sign-up call.
  ///
  /// There is no backend, so this waits and then accepts. Replace the body
  /// when `AuthService` lands; the shape of this method does not change.
  Future<bool> _createAccount() async {
    await Future<void>.delayed(_fakeRequestDuration);
    return true;
  }

  /// Re-checks every field on each keystroke, but notifies only when one of
  /// the answers changes — otherwise typing would rebuild the screen for
  /// nothing.
  void _onFieldChanged() {
    final bool isNameSatisfied = _validateName(nameController.text.trim()) == null;
    final bool isEmailSatisfied =
        _validateEmail(emailController.text.trim()) == null;
    final bool isPhoneSatisfied = _validatePhone(phoneController.text) == null;
    final bool isPasswordSatisfied =
        _validatePassword(passwordController.text) == null;

    if (isNameSatisfied == _isNameSatisfied &&
        isEmailSatisfied == _isEmailSatisfied &&
        isPhoneSatisfied == _isPhoneSatisfied &&
        isPasswordSatisfied == _isPasswordSatisfied) {
      return;
    }

    _isNameSatisfied = isNameSatisfied;
    _isEmailSatisfied = isEmailSatisfied;
    _isPhoneSatisfied = isPhoneSatisfied;
    _isPasswordSatisfied = isPasswordSatisfied;
    notifyListeners();
  }

  /// Fills every error and reports whether the form is valid.
  bool _validate() {
    _nameError = _validateName(nameController.text.trim());
    _emailError = _validateEmail(emailController.text.trim());
    _phoneError = _validatePhone(phoneController.text);
    _passwordError = _validatePassword(passwordController.text);
    notifyListeners();

    return _nameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null;
  }

  NameError? _validateName(String name) {
    if (name.isEmpty) return const NameRequired();
    if (name.length < InputRules.minNameLength) {
      return const NameTooShort(InputRules.minNameLength);
    }
    return null;
  }

  EmailError? _validateEmail(String email) {
    if (email.isEmpty) return const EmailRequired();
    if (!InputRules.emailPattern.hasMatch(email)) return const EmailInvalid();
    return null;
  }

  PhoneError? _validatePhone(String phone) {
    if (phone.trim().isEmpty) return const PhoneRequired();
    if (!InputRules.isPhoneComplete(phone)) {
      return const PhoneInvalid(
        requiredDigits: InputRules.phoneLength,
        leadingDigit: InputRules.phoneLeadingDigit,
      );
    }
    return null;
  }

  PasswordError? _validatePassword(String password) {
    if (password.isEmpty) return const PasswordRequired();
    if (password.length < InputRules.minPasswordLength) {
      return const PasswordTooShort(InputRules.minPasswordLength);
    }
    return null;
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    phoneFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}
