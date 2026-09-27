import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/validation_error.dart';
import '../../../core/models/account.dart';
import '../../../core/session/session_controller.dart';
import '../../auth/data/auth_repository.dart';

/// Why the invite link cannot be used.
enum InviteProblem {
  /// `10g` — `RESET_TOKEN_EXPIRED`: older than 7 days, or already used.
  expired,

  /// `RESET_TOKEN_INVALID`, or the link arrived without a token at all.
  invalid,
}

/// Drives `10f Set password` — an account an admin created, opened from its
/// invite email — and `10g`, the link that no longer works.
///
/// The design shows the invitee's name, email and role above the fields. The
/// API only reveals those *after* the password is set (there is no call to
/// read an invite), so that card is left out rather than faked.
class SetPasswordViewModel extends BaseViewModel {
  SetPasswordViewModel({
    required this._auth,
    required this._session,
    required this._config,
    required String? token,
  })  : _token = token {
    if (token == null || token.isEmpty) _problem = InviteProblem.invalid;
    passwordController.addListener(_onChanged);
    confirmController.addListener(_onChanged);
  }

  final AuthRepository _auth;
  final SessionController _session;
  final AppConfig _config;
  final String? _token;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final FocusNode confirmFocusNode = FocusNode();

  InviteProblem? _problem;
  PasswordError? _passwordError;
  PasswordError? _confirmError;

  InviteProblem? get problem => _problem;
  PasswordError? get passwordError => _passwordError;
  PasswordError? get confirmError => _confirmError;

  int get minPasswordLength => _config.passwordMinLength;

  /// Where "Contact support" writes to, or `null` to hide it — the live config
  /// has none today.
  String? get supportEmail => _config.supportEmail;

  bool get canSubmit =>
      _problem == null &&
      passwordController.text.isNotEmpty &&
      confirmController.text.isNotEmpty &&
      !isBusy;

  void moveFocusToConfirm() => confirmFocusNode.requestFocus();

  /// Sets the password and signs in; the router then takes the user home.
  Future<void> submit() async {
    final String? token = _token;
    if (token == null || _problem != null) return;

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
    if (_passwordError != null || _confirmError != null) return;

    final AppUser? user = await runGuarded(
      () => _auth.setPassword(token: token, password: passwordController.text),
    );
    if (user != null) {
      _session.signedIn(user);
      return;
    }

    final Failure? error = failure;
    if (error is! ApiFailure) return;
    switch (error.code) {
      case ApiErrorCode.resetTokenExpired:
        _problem = InviteProblem.expired;
        clearFailure();
      case ApiErrorCode.resetTokenInvalid:
        _problem = InviteProblem.invalid;
        clearFailure();
      case ApiErrorCode.passwordWeak:
        _passwordError = const PasswordWeak();
        clearFailure();
    }
  }

  void _onChanged() {
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
