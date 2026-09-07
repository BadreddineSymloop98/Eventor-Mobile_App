import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/validation_error.dart';

/// Drives the forgot-password form.
///
/// One field, one request. Validation follows the same two-pass shape as the
/// other forms: as the user types it answers "is this fillable yet", which
/// enables the button; on submit it runs again to produce the message.
class ForgotPasswordViewModel extends BaseViewModel {
  ForgotPasswordViewModel() {
    emailController.addListener(_onFieldChanged);
  }

  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();

  EmailError? _emailError;
  bool _isEmailFillable = false;

  EmailError? get emailError => _emailError;

  /// Whether the form is complete enough to send.
  bool get canSubmit => _isEmailFillable && !isBusy;

  /// Validates the address and asks for a reset link.
  ///
  /// Returns whether the caller may continue to the code-entry screen.
  Future<bool> sendResetLink() async {
    if (!_validate()) return false;

    final bool? succeeded = await runGuarded(_requestReset);
    return succeeded ?? false;
  }

  /// Placeholder for the real request.
  ///
  /// There is no backend, so any address that parses is accepted. Note that
  /// the real one should behave the same way whether or not the address is on
  /// file — telling an anonymous caller which emails have accounts is a way of
  /// enumerating users.
  Future<bool> _requestReset() async => true;

  void _onFieldChanged() {
    final bool isFillable = _validateEmail(emailController.text.trim()) == null;
    if (isFillable == _isEmailFillable) return;

    _isEmailFillable = isFillable;
    notifyListeners();
  }

  bool _validate() {
    _emailError = _validateEmail(emailController.text.trim());
    notifyListeners();
    return _emailError == null;
  }

  EmailError? _validateEmail(String email) {
    if (email.isEmpty) return const EmailRequired();
    if (!InputRules.emailPattern.hasMatch(email)) return const EmailInvalid();
    return null;
  }

  @override
  void dispose() {
    emailController
      ..removeListener(_onFieldChanged)
      ..dispose();
    emailFocusNode.dispose();
    super.dispose();
  }
}
