import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization/app_localizations_x.dart';
import 'app_toast.dart';

/// Back on the app's first screen asks before closing: the first press says
/// "Press back again to exit", and only a second one within [window] leaves.
/// One stray press no longer throws away where the user was.
///
/// Wrap the screen that is the bottom of the stack. Screens opened on top of
/// it get Back first, so it only ever sees the press that would close the app.
class BackToExit extends StatefulWidget {
  const BackToExit({required this.child, super.key});

  /// How long the second press has — also how long the toast stays, so the
  /// hint is on screen exactly while it is true.
  static const Duration window = Duration(seconds: 2);

  final Widget child;

  @override
  State<BackToExit> createState() => _BackToExitState();
}

class _BackToExitState extends State<BackToExit> {
  // A timer rather than a timestamp: it is what widget tests can move.
  Timer? _armed;

  @override
  void dispose() {
    _armed?.cancel();
    super.dispose();
  }

  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    if (_armed?.isActive ?? false) {
      _armed?.cancel();
      _armed = null;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
      return;
    }
    _armed = Timer(BackToExit.window, () {});
    showAppToast(
      context,
      context.l10n.pressBackAgainToExit,
      tone: AppToastTone.info,
      duration: BackToExit.window,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: _onBack,
        child: widget.child,
      );
}
