import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../session/session_controller.dart';

/// The work the splash covers, and the moment it is done.
///
/// The router holds every route on the splash until [isReady]; then its
/// redirect sends the user wherever the session says. Keeping this separate
/// from the session means the splash is seen for [minimumVisible] even when
/// restoring the session is instant, and a slow restore simply holds it longer.
class AppStartup extends ChangeNotifier {
  AppStartup({
    required this._config,
    required this._session,
  });

  /// Long enough for the brand to be seen rather than flashed.
  static const Duration minimumVisible = Duration(milliseconds: 1600);

  final AppConfigRepository _config;
  final SessionController _session;

  bool _isReady = false;
  bool _started = false;

  bool get isReady => _isReady;

  /// Runs once; later calls are no-ops.
  Future<void> run({Duration floor = minimumVisible}) async {
    if (_started) return;
    _started = true;

    await Future.wait(<Future<void>>[
      Future<void>.delayed(floor),
      _config.load(),
      _session.restore(),
    ]);

    _isReady = true;
    notifyListeners();
  }
}
