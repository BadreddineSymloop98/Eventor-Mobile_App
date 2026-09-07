import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';

/// Drives the code-entry screen.
///
/// The code is held whole rather than as six values — see `CodeInput` for why
/// — so there is one controller and one length check.
class VerifyCodeViewModel extends BaseViewModel {
  VerifyCodeViewModel({this.destination}) {
    codeController.addListener(_onCodeChanged);
    // A code has just been sent to get here, so the wait starts with the
    // screen rather than with the first tap on Resend.
    _startResendCooldown();
  }

  /// How long the fake round trips take. Long enough that the button's busy
  /// state is visible, which is the point of simulating them.
  static const Duration _fakeRequestDuration = Duration(seconds: 2);

  /// How long the user waits before another code may be asked for.
  ///
  /// A code takes a moment to arrive, and a second request does not make the
  /// first one land any sooner — the wait is there to be seen, so the user
  /// knows to keep waiting rather than to keep tapping.
  static const Duration resendCooldown = Duration(seconds: 30);

  /// Where the code was sent — the phone number from sign-up, or the address
  /// from a password reset. Shown back to the user so they can tell whether it
  /// went somewhere they can actually read.
  final String? destination;

  final TextEditingController codeController = TextEditingController();
  final FocusNode codeFocusNode = FocusNode();

  bool _isComplete = false;

  Timer? _resendTimer;
  int _resendSecondsRemaining = 0;
  bool _isResending = false;

  /// Seconds still to wait, counting down to zero once per second.
  int get resendSecondsRemaining => _resendSecondsRemaining;

  /// Whether another code may be asked for yet.
  bool get canResend => _resendSecondsRemaining == 0 && !isBusy;

  /// Whether a new code is being asked for right now.
  bool get isResending => _isResending;

  /// Whether the *code* is being checked right now.
  ///
  /// [isBusy] covers the screen, not a control: verifying and resending both
  /// run through it. Each control needs to know whether the work in flight is
  /// its own, or a resend would spin the Verify button.
  bool get isVerifying => isBusy && !_isResending;

  /// Whether the code is long enough to be worth sending.
  bool get canSubmit => _isComplete && !isBusy;

  /// Checks the code.
  ///
  /// Returns whether the caller may continue.
  Future<bool> verify() async {
    if (!_isComplete) return false;

    final bool? succeeded = await runGuarded(_checkCode);
    return succeeded ?? false;
  }

  /// Asks for a new code.
  ///
  /// Returns whether one is actually on its way, so the caller only says so
  /// when it is. The wait restarts on success only — a request that failed
  /// should not cost the user another thirty seconds.
  Future<bool> resend() async {
    if (!canResend) return false;

    // Claimed before the request starts, so the screen-wide busy flag that
    // `runGuarded` raises is attributed to this control rather than to Verify.
    _isResending = true;

    final bool? sent = await runGuarded(_requestNewCode);

    _isResending = false;

    if (sent ?? false) {
      // Restarting the wait notifies on its own.
      _startResendCooldown();
    } else {
      notifyListeners();
    }

    return sent ?? false;
  }

  /// Restarts the wait and ticks it down to zero.
  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSecondsRemaining = resendCooldown.inSeconds;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _resendSecondsRemaining--;

      if (_resendSecondsRemaining <= 0) {
        _resendSecondsRemaining = 0;
        timer.cancel();

        // Only clear the field if it still points at *this* timer. Blanking
        // it unconditionally would orphan a newer one — left ticking, with
        // nothing holding a reference to cancel it, so the next countdown
        // would run at double speed.
        if (identical(_resendTimer, timer)) _resendTimer = null;
      }

      notifyListeners();
    });

    notifyListeners();
  }

  /// Placeholder for the real check. There is no backend, so any six digits
  /// are accepted.
  Future<bool> _checkCode() async {
    await Future<void>.delayed(_fakeRequestDuration);
    return true;
  }

  Future<bool> _requestNewCode() async {
    await Future<void>.delayed(_fakeRequestDuration);
    return true;
  }

  void _onCodeChanged() {
    final bool isComplete =
        codeController.text.length == InputRules.verificationCodeLength;
    if (isComplete == _isComplete) return;

    _isComplete = isComplete;
    notifyListeners();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    codeController
      ..removeListener(_onCodeChanged)
      ..dispose();
    codeFocusNode.dispose();
    super.dispose();
  }
}
