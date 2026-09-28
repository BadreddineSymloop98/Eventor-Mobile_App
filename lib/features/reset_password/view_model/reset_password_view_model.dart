import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/validation_error.dart';
import '../../../core/routing/app_routes.dart';
import '../../auth/data/auth_repository.dart';

/// How `10a` ended.
sealed class ResetOutcome {
  const ResetOutcome();
}

/// The password was changed. Every session was revoked with it, so the user
/// signs in again.
class ResetSucceeded extends ResetOutcome {
  const ResetSucceeded();
}

/// The code from `10` was refused — go back and fix it.
class ResetCodeRefused extends ResetOutcome {
  const ResetCodeRefused(this.problem);

  final ResetCodeProblem problem;
}

/// Drives `10a Reset password` — the new password, typed twice.
///
/// "Confirm password" has no field on the server: it is a client-side typo
/// guard, owned here (a decision recorded in the handoff).
class ResetPasswordViewModel extends BaseViewModel {
  ResetPasswordViewModel({
    required this._auth,
    required this._config,
    required this.args,
  }) {
    passwordController.addListener(_onChanged);
    confirmController.addListener(_onChanged);
  }

  final AuthRepository _auth;
  final AppConfig _config;
  final ResetPasswordArgs args;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final FocusNode confirmFocusNode = FocusNode();

  PasswordError? _passwordError;
  PasswordError? _confirmError;

  PasswordError? get passwordError => _passwordError;
  PasswordError? get confirmError => _confirmError;

  int get minPasswordLength => _config.passwordMinLength;

  bool get canSubmit =>
      passwordController.text.isNotEmpty &&
      confirmController.text.isNotEmpty &&
      !isBusy;

  void moveFocusToConfirm() => confirmFocusNode.requestFocus();

  /// Sends the reset, or `null` when validation or the network stopped it.
  Future<ResetOutcome?> submit() async {
    _passwordError = InputRules.validateNewPassword(
      passwordController.text,
      minLength: _config.passwordMinLength,
      needsLetterAndDigit: _config.passwordNeedsLetterAndDigit,
    );
    _confirmError = _passwordError == null &&
            confirmController.text != passwordController.text
        ? const PasswordMismatch()
        : null;
    notifyListeners();
    if (_passwordError != null || _confirmError != null) return null;

    final bool? done = await runGuarded(() async {
      await _auth.resetPassword(
        email: args.email,
        code: args.code,
        password: passwordController.text,
      );
      return true;
    });
    if (done == true) return const ResetSucceeded();

    final Failure? error = failure;
    if (error is! ApiFailure) return null;
    switch (error.code) {
      case ApiErrorCode.codeInvalid:
        clearFailure();
        return const ResetCodeRefused(ResetCodeProblem.invalid);
      case ApiErrorCode.codeExpired:
        clearFailure();
        return const ResetCodeRefused(ResetCodeProblem.expired);
      case ApiErrorCode.passwordWeak:
        _passwordError = const PasswordWeak();
        clearFailure();
    }
    return null;
  }

  void _onChanged() {
    // An error is a verdict on the value it was given; editing retires it.
    // Notified on every keystroke either way, because the button's state
    // follows the fields.
    _passwordError = null;
    _confirmError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    confirmFocusNode.dispose();
    super.dispose();
  }
}
