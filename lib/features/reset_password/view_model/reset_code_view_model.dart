import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/failure.dart';
import '../../../core/routing/app_routes.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/view/code_entry_sheet.dart';
import '../../auth/view_model/resend_countdown.dart';

/// Drives `10 Verify code` in the password reset.
///
/// The code is checked here, without being spent, before `10a` asks for a
/// password — a wrong code is never found out after typing it twice. `10a`
/// sends it again with the password; should it have expired meanwhile, `10a`
/// comes back here with that [problem].
class ResetCodeViewModel extends BaseViewModel with ResendCountdown {
  ResetCodeViewModel({required this._auth, required this.email}) {
    codeController.addListener(_onCodeChanged);
    // `09` has just sent one; hold the resend for the server's usual wait.
    startResendCountdown(CodeSent.defaultResendSeconds);
  }

  final AuthRepository _auth;

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
      codeController.text.length == InputRules.verificationCodeLength;

  bool takeCodeSent() {
    final bool sent = _codeSent;
    _codeSent = false;
    return sent;
  }

  /// Checks the code; what `10a` needs when it is good, `null` when it is
  /// incomplete or refused — [problem] or [failure] then says why.
  Future<ResetPasswordArgs?> verify() async {
    if (!canSubmit || isBusy) return null;
    final String code = codeController.text;
    final bool? valid = await runGuarded(() async {
      await _auth.verifyResetCode(email: email, code: code);
      return true;
    });
    if (valid == true) return ResetPasswordArgs(email: email, code: code);

    final Failure? error = failure;
    if (error is ApiFailure) {
      if (error.code == ApiErrorCode.codeInvalid) {
        reportProblem(ResetCodeProblem.invalid);
        clearFailure();
      } else if (error.code == ApiErrorCode.codeExpired) {
        reportProblem(ResetCodeProblem.expired);
        clearFailure();
      }
    }
    return null;
  }

  /// `10a` found the code wrong or expired.
  void reportProblem(ResetCodeProblem problem) {
    _problem = switch (problem) {
      ResetCodeProblem.invalid => CodeProblem.invalid,
      ResetCodeProblem.expired => CodeProblem.expired,
    };
    if (problem == ResetCodeProblem.expired) {
      codeController.clear();
      startResendCountdown(0);
    }
    notifyListeners();
  }

  Future<void> resend() async {
    if (!canResend || _isResending) return;
    _isResending = true;
    notifyListeners();

    final bool? sent = await runGuarded(() async {
      await _auth.forgotPassword(email);
      return true;
    });

    _isResending = false;
    if (sent == true) {
      _codeSent = true;
      _problem = null;
      codeController.clear();
      // The reset request returns no cooldown of its own; the verification
      // one is 60 s, and the same wait keeps the two flows alike.
      startResendCountdown(CodeSent.defaultResendSeconds);
      codeFocusNode.requestFocus();
    }
    notifyListeners();
  }

  void _onCodeChanged() {
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
