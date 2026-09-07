import 'package:flutter/material.dart';

import '../constants/ui_helpers.dart';

/// How a brief message is shown to the user.
enum AppToastTone { success, error }

/// Shows a short message at the bottom of the screen.
///
/// A thin wrapper over [ScaffoldMessenger] so that call sites never touch it
/// directly and every toast in the app looks the same. It replaces whatever is
/// already showing rather than queueing behind it — a stale message is worse
/// than no message.
void showAppToast(
  BuildContext context,
  String message, {
  AppToastTone tone = AppToastTone.success,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textOnBrand,
            ),
      ),
      backgroundColor: switch (tone) {
        AppToastTone.success => AppColors.statusAccepted,
        AppToastTone.error => AppColors.statusDeclined,
      },
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.md.dh,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      duration: const Duration(seconds: 3),
    ),
  );
}
