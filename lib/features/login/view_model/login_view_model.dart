import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/validation_error.dart';
import '../../../core/models/account.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/session/session_controller.dart';
import '../../auth/data/auth_repository.dart';

/// What the banner above the login form is reporting.
enum LoginProblem {
  /// `07b` — `INVALID_CREDENTIALS`.
  wrongCredentials,

  /// `07c` — `EMAIL_NOT_VERIFIED`, with a link to send a new code.
  unverified,

  /// `07d` — `ACCOUNT_LOCKED`, until [LoginViewModel.lockedUntil].
  locked,

  /// `ACCOUNT_BLOCKED` — the admin's message is the body.
  blocked,

  /// `ROLE_NOT_ALLOWED_IN_APP` — an admin account.
  notAllowed,

  /// The session ended on its own and the router brought the user here.
  sessionExpired,
}

/// Drives the login screen — `07` and its error states `07b`–`07d`.
///
/// Validation here is only "is there something that looks like an address,
/// and is there a password": the API sets no password minimum on login, and
/// refusing to send a short password would lock out anyone whose old password
/// predates today's rule.
class LoginViewModel extends BaseViewModel {
  LoginViewModel({
    required this._auth,
    required this._session,
    String? initialEmail,
    bool sessionExpired = false,
  }) {
    emailController.text = initialEmail ?? '';
    if (sessionExpired) _problem = LoginProblem.sessionExpired;
    emailController.addListener(_onFieldChanged);
    passwordController.addListener(_onFieldChanged);
    _onFieldChanged();
  }

  final AuthRepository _auth;
  final SessionController _session;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool _canSubmit = false;
  EmailError? _emailError;
  PasswordError? _passwordError;

  LoginProblem? _problem;
  String? _serverMessage;
  String? _unverifiedEmail;
  DateTime? _lockedUntil;
  Timer? _lockTimer;
  bool _isSendingCode = false;

  bool get canSubmit => _canSubmit && !isLocked;
  EmailError? get emailError => _emailError;
  PasswordError? get passwordError => _passwordError;

  /// What the banner reports, or `null` for no banner.
  LoginProblem? get problem => _problem;

  /// The server's own sentence, for [LoginProblem.blocked].
  String? get serverMessage => _serverMessage;

  /// The address the unverified account belongs to — the server echoes it.
  String? get unverifiedEmail => _unverifiedEmail;

  /// When the lock ends, for [LoginProblem.locked].
  DateTime? get lockedUntil => _lockedUntil;
  bool get isLocked => _lockedUntil != null;

  bool get isSendingCode => _isSendingCode;

  void moveFocusToPassword() => passwordFocusNode.requestFocus();

  /// Validates and signs in. On success the session takes over and the router
  /// moves the user on; nothing to return.
  Future<void> signIn() async {
    if (isBusy || isLocked || !_validate()) return;

    _problem = null;
    final String email = emailController.text.trim();

    final bool signedIn = await runGuarded(() async {
          final AppUser user = await _auth.login(
            email: email,
            password: passwordController.text,
          );
          _session.signedIn(user);
          return true;
        }) ??
        false;

    if (!signedIn) _handleFailure(email);
  }

  /// `07c` — sends a fresh code and returns what `10b` needs, or `null` if it
  /// could not be sent.
  Future<VerifyEmailArgs?> sendNewCode() async {
    final String email = _unverifiedEmail ?? emailController.text.trim();
    _isSendingCode = true;
    notifyListeners();

    final CodeSent? sent = await runGuarded(
      () => _auth.resendVerification(email),
    );

    _isSendingCode = false;
    if (sent == null) {
      final Failure? error = failure;
      // A code sent moments ago is still valid — carry on to enter it.
      if (error is ApiFailure && error.code == ApiErrorCode.codeResendTooSoon) {
        clearFailure();
        return VerifyEmailArgs(
          email: email,
          resendAfterSeconds:
              error.retryAfterSeconds ?? CodeSent.defaultResendSeconds,
        );
      }
      notifyListeners();
      return null;
    }
    notifyListeners();
    return VerifyEmailArgs(
      email: sent.email.isEmpty ? email : sent.email,
      resendAfterSeconds: sent.resendAfterSeconds,
    );
  }

  void _handleFailure(String email) {
    final Failure? error = failure;
    if (error is! ApiFailure) return; // Network and the rest: the view toasts.

    switch (error.code) {
      case ApiErrorCode.invalidCredentials:
        _problem = LoginProblem.wrongCredentials;
        // The password is the likelier typo, and it is secret — clear it so
        // the next attempt starts clean. The address stays.
        passwordController.clear();
      case ApiErrorCode.emailNotVerified:
        _problem = LoginProblem.unverified;
        _unverifiedEmail = error.details?['email'] as String? ?? email;
      case ApiErrorCode.accountLocked:
        _problem = LoginProblem.locked;
        _startLock(error.retryAfterSeconds ?? 15 * 60);
      case ApiErrorCode.accountBlocked:
        _problem = LoginProblem.blocked;
        _serverMessage =
            error.details?['message'] as String? ?? error.message;
      case ApiErrorCode.roleNotAllowedInApp:
        _problem = LoginProblem.notAllowed;
        _serverMessage = error.message;
      default:
        return; // Unknown code: the view shows the server's message.
    }
    clearFailure();
  }

  void _startLock(int seconds) {
    _lockTimer?.cancel();
    _lockedUntil = DateTime.now().add(Duration(seconds: seconds));
    _lockTimer = Timer(Duration(seconds: seconds), () {
      _lockedUntil = null;
      if (_problem == LoginProblem.locked) _problem = null;
      notifyListeners();
    });
  }

  bool _validate() {
    _emailError = _validateEmail(emailController.text);
    _passwordError =
        passwordController.text.isEmpty ? const PasswordRequired() : null;
    notifyListeners();
    return _emailError == null && _passwordError == null;
  }

  void _onFieldChanged() {
    final bool canSubmit = InputRules.emailPattern.hasMatch(
          emailController.text.trim(),
        ) &&
        passwordController.text.isNotEmpty;

    bool changed = canSubmit != _canSubmit;
    _canSubmit = canSubmit;

    // An error is a verdict on the value it was given; once that value
    // changes the verdict no longer applies.
    if (_emailError != null && emailController.text.isNotEmpty) {
      _emailError = null;
      changed = true;
    }
    if (_passwordError != null && passwordController.text.isNotEmpty) {
      _passwordError = null;
      changed = true;
    }
    // "Wrong email or password" is about the pair that was sent; editing
    // either retires it. The lock and the blocked notice are not about the
    // typing and stay.
    if (_problem == LoginProblem.wrongCredentials &&
        passwordController.text.isNotEmpty) {
      _problem = null;
      changed = true;
    }
    // "Confirm your email first" names one address; typing another makes it
    // about the wrong account, and its "Send a new code" would go astray.
    if (_problem == LoginProblem.unverified &&
        emailController.text.trim() != _unverifiedEmail) {
      _problem = null;
      _unverifiedEmail = null;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  static EmailError? _validateEmail(String value) {
    final String email = value.trim();
    if (email.isEmpty) return const EmailRequired();
    if (!InputRules.emailPattern.hasMatch(email)) return const EmailInvalid();
    return null;
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}
