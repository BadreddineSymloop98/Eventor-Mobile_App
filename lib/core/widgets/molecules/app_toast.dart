import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// How a brief message is shown to the user.
enum AppToastTone {
  success,
  error,

  /// Neither good nor bad news — "Coming soon", "Removed from favourites".
  info,
}

/// Shows a short message at the bottom of the screen.
///
/// A thin wrapper over [ScaffoldMessenger] so that call sites never touch it
/// directly and every toast in the app looks the same. It replaces whatever is
/// already showing rather than queueing behind it — a stale message is worse
/// than no message.
///
/// [actionLabel] and [onAction] add one action, such as Undo. The returned
/// controller's `closed` future tells the caller how the toast went away —
/// what an undoable removal waits on before it commits.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppToast(
  BuildContext context,
  String message, {
  AppToastTone tone = AppToastTone.success,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar();
  final String? label = actionLabel;
  final VoidCallback? action = onAction;

  return messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textOnBrand,
            ),
      ),
      backgroundColor: switch (tone) {
        AppToastTone.success => AppColors.statusAccepted,
        AppToastTone.error => AppColors.bgDanger,
        AppToastTone.info => AppColors.bgBrand,
      },
      action: label == null || action == null
          ? null
          : SnackBarAction(
              label: label,
              // Gold on purple: the palette's accent for use on the brand.
              textColor: AppColors.textOnBrandAccent,
              onPressed: action,
            ),
      // A SnackBar with an action otherwise stays until dismissed — an
      // undoable change would never commit.
      persist: false,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.md.dh,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      duration: duration ?? Duration(seconds: label == null ? 3 : 4),
    ),
  );
}

/// The one toast for a link to a screen that is not built yet.
void showComingSoon(BuildContext context, String message) =>
    showAppToast(context, message, tone: AppToastTone.info);
