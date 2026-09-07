import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/validation_error.dart';

/// Drives the login screen.
///
/// It owns the form: the text controllers, the focus nodes, the validation
/// results and the sign-in call. Keeping all of it here means the form can be
/// tested without building a widget.
///
/// Validation runs twice over. As the user types it answers "is this field
/// valid yet?", which drives the instruction under each field and whether the
/// button can be tapped. On submit it runs again to produce the errors —
/// values set programmatically bypass both the formatters and the listeners.
///
/// Errors come out as types rather than sentences: this class has no
/// [BuildContext] and so cannot look up a localised string. The view turns
/// them into text.
class LoginViewModel extends BaseViewModel {
  LoginViewModel() {
    emailController.addListener(_onFieldChanged);
    passwordController.addListener(_onFieldChanged);
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  EmailError? _emailError;
  PasswordError? _passwordError;

  /// Whether each field currently satisfies its format.
  ///
  /// The fields hide their instruction once this turns true.
  bool get isEmailValid => _isEmailValid;
  bool get isPasswordValid => _isPasswordValid;

  /// Whether the form is complete enough to submit.
  bool get canSubmit => _isEmailValid && _isPasswordValid;

  EmailError? get emailError => _emailError;
  PasswordError? get passwordError => _passwordError;

  /// Moves the keyboard on from the email field to the password field.
  void moveFocusToPassword() => passwordFocusNode.requestFocus();

  /// Validates the form and signs the user in.
  ///
  /// Returns whether the caller may continue to the next screen.
  Future<bool> signIn() async {
    if (!_validate()) return false;

    final bool? succeeded = await runGuarded(_authenticate);
    return succeeded ?? false;
  }

  /// Placeholder for the real authentication call.
  ///
  /// There is no backend yet, so any input that passes validation is accepted.
  Future<bool> _authenticate() async => true;

  /// Re-checks both fields on every keystroke, but notifies only when an
  /// answer actually changes — otherwise typing would rebuild the screen for
  /// nothing.
  void _onFieldChanged() {
    final bool isEmailValid = _validateEmail(emailController.text.trim()) == null;
    final bool isPasswordValid =
        _validatePassword(passwordController.text) == null;

    if (isEmailValid == _isEmailValid && isPasswordValid == _isPasswordValid) {
      return;
    }

    _isEmailValid = isEmailValid;
    _isPasswordValid = isPasswordValid;
    notifyListeners();
  }

  /// Fills [emailError] and [passwordError], and reports whether the form is
  /// valid.
  bool _validate() {
    _emailError = _validateEmail(emailController.text.trim());
    _passwordError = _validatePassword(passwordController.text);
    notifyListeners();

    return _emailError == null && _passwordError == null;
  }

  EmailError? _validateEmail(String email) {
    if (email.isEmpty) return const EmailRequired();
    if (!InputRules.emailPattern.hasMatch(email)) return const EmailInvalid();
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
    emailController.removeListener(_onFieldChanged);
    passwordController.removeListener(_onFieldChanged);
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}
