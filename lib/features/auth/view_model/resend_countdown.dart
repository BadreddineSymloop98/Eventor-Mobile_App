import 'dart:async';

import 'package:flutter/foundation.dart';

/// The "Resend in 0:45" cooldown shared by the code screens (`10b`, `10`).
///
/// The length comes from the server — `resendAfterSeconds` on a sent code,
/// `retryAfterSeconds` on a refused one — so the app never offers a resend the
/// server would turn away.
mixin ResendCountdown on ChangeNotifier {
  Timer? _resendTimer;
  int _secondsLeft = 0;

  /// Seconds until Resend is allowed again. `0` means now.
  int get resendSecondsLeft => _secondsLeft;
  bool get canResend => _secondsLeft == 0;

  /// `m:ss`, for the button label.
  String get resendClock {
    final int minutes = _secondsLeft ~/ 60;
    final int seconds = _secondsLeft % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @protected
  void startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    _secondsLeft = seconds < 0 ? 0 : seconds;
    notifyListeners();
    if (_secondsLeft == 0) return;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _secondsLeft -= 1;
      if (_secondsLeft <= 0) {
        _secondsLeft = 0;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  @protected
  void stopResendCountdown() => _resendTimer?.cancel();
}
