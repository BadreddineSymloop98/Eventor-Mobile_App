import 'dart:async';

import 'package:flutter/widgets.dart';

/// Keeps screen 15 (a chat thread) fresh while it is open.
///
/// Decision 1: this is polling, not a socket. The socket's auth handshake and
/// message payloads are undocumented on the backend, so [TimerChatUpdates]
/// ticks the thread's own re-fetch on a timer instead. Both live behind this
/// interface — a future Socket.IO implementation of [ChatUpdates] drops in
/// without screen 15's view model changing at all.
abstract interface class ChatUpdates {
  /// Begins ticking [onTick] on the interval. Call once; a second [start]
  /// on an already-running poller is undefined.
  void start(Future<void> Function() onTick);

  /// Suspends ticking without releasing resources. A no-op if not running.
  void pause();

  /// Ticks once immediately, then resumes the interval. Ignored unless the
  /// poller is running and currently paused.
  void resume();

  /// Ends the poller for good. A later [resume] does nothing.
  void stop();
}

/// [ChatUpdates] on a plain [Timer.periodic], gated by the app's own
/// lifecycle so a backgrounded thread stops spending the polling budget.
///
/// The polling budget (100 requests/60s, images included) only affords a
/// tick every 5 s while the thread is genuinely on screen — see the plan's
/// global constraints — so ticks never overlap ([_inFlight]) and pause the
/// moment the app is hidden.
class TimerChatUpdates implements ChatUpdates {
  TimerChatUpdates({
    this.interval = const Duration(seconds: 5),
    this.followAppLifecycle = true,
  });

  final Duration interval;
  final bool followAppLifecycle;

  Future<void> Function()? _onTick;
  Timer? _timer;
  AppLifecycleListener? _lifecycleListener;
  bool _isPaused = false;
  bool _isStopped = false;
  bool _isRunning = false;

  // True while an [_onTick] call is awaited, so a slow tick is never
  // overlapped by the next scheduled one.
  bool _inFlight = false;

  @override
  void start(Future<void> Function() onTick) {
    _onTick = onTick;
    _isRunning = true;
    _isPaused = false;
    _isStopped = false;
    if (followAppLifecycle) {
      _lifecycleListener = AppLifecycleListener(
        onHide: pause,
        onShow: resume,
      );
    }
    _scheduleTimer();
  }

  @override
  void pause() {
    if (!_isRunning || _isStopped) return;
    _isPaused = true;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void resume() {
    if (!_isRunning || _isStopped || !_isPaused) return;
    _isPaused = false;
    unawaited(_tick());
    _scheduleTimer();
  }

  @override
  void stop() {
    _isStopped = true;
    _isRunning = false;
    _isPaused = false;
    _timer?.cancel();
    _timer = null;
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    _onTick = null;
  }

  void _scheduleTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(_tick()));
  }

  Future<void> _tick() async {
    if (_inFlight) return;
    final Future<void> Function()? onTick = _onTick;
    if (onTick == null) return;
    _inFlight = true;
    try {
      await onTick();
    } catch (_) {
      // A failed poll is retried by the next tick — the thread just shows
      // stale data for one interval rather than surfacing an error.
    } finally {
      _inFlight = false;
    }
  }
}
