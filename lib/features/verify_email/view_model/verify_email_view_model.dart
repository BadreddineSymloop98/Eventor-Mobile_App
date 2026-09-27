import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/failure.dart';
import '../../../core/models/account.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/session/session_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/view/code_entry_sheet.dart';
import '../../auth/view_model/resend_countdown.dart';

/// Drives `10b Confirm email` and its states `10c` (wrong code) and `10d`
/// (expired code).
///
/// A correct code ends the sign-up: the server returns a session, the session
/// controller takes it, and the router moves the user on — a provider to
/// their documents (`08e`), a client home.
class VerifyEmailViewModel extends BaseViewModel with ResendCountdown {
  VerifyEmailViewModel({
    required this._auth,
    required this._session,
    required VerifyEmailArgs args,
  })  : email = args.email {
    codeController.addListener(_onCodeChanged);
    startResendCountdown(args.resendAfterSeconds);
  }

  final AuthRepository _auth;
  final SessionController _session;

  /// Where the code was sent.
  final String email;

  final TextEditingController codeController = TextEditingController();
  final FocusNode codeFocusNode = FocusNode();

  CodeProblem? _problem;
  bool _isResending = false;
  bool _codeSent = false;

  CodeProblem? get problem => _problem;
  bool get isResending => _isResending;

  bool get canSubmit =>
      codeController.text.length == InputRules.verificationCodeLength &&
      !isBusy;

  /// Consumed once by the view to toast "A new code is on its way".
  bool takeCodeSent() {
    final bool sent = _codeSent;
    _codeSent = false;
    return sent;
  }

  Future<void> verify() async {
    if (!canSubmit || _isResending) return;

    final AppUser? user = await runGuarded(
      () => _auth.verifyEmail(email: email, code: codeController.text),
    );

    if (user != null) {
      stopResendCountdown();
      _session.signedIn(
        user,
        landing: user.isProvider ? AppRoutes.documents : null,
      );
      return;
    }

    final Failure? error = failure;
    if (error is ApiFailure) {
      if (error.code == ApiErrorCode.codeInvalid) {
        _problem = CodeProblem.invalid;
        clearFailure();
      } else if (error.code == ApiErrorCode.codeExpired) {
        // The code is dead; a new one is the only way on, so Resend is
        // offered straight away.
        _problem = CodeProblem.expired;
        codeController.clear();
        startResendCountdown(0);
        clearFailure();
      }
    }
  }

  Future<void> resend() async {
    if (!canResend || _isResending) return;
    _isResending = true;
    notifyListeners();

    final CodeSent? sent = await runGuarded(
      () => _auth.resendVerification(email),
    );

    _isResending = false;
    if (sent != null) {
      _codeSent = true;
      _problem = null;
      codeController.clear();
      startResendCountdown(sent.resendAfterSeconds);
      codeFocusNode.requestFocus();
      return;
    }

    final Failure? error = failure;
    if (error is ApiFailure && error.code == ApiErrorCode.codeResendTooSoon) {
      startResendCountdown(
        error.retryAfterSeconds ?? CodeSent.defaultResendSeconds,
      );
      clearFailure();
    } else {
      notifyListeners();
    }
  }

  void _onCodeChanged() {
    // A wrong-code verdict belongs to the code it was given. Editing it
    // retires the red boxes; an expiry stays until a new code is sent.
    if (_problem == CodeProblem.invalid) _problem = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopResendCountdown();
    codeController.dispose();
    codeFocusNode.dispose();
    super.dispose();
  }
}
