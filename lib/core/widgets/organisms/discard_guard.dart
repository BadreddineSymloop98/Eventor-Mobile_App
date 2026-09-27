import 'package:flutter/material.dart';

import '../../localization/app_localizations_x.dart';
import '../../../l10n/app_localizations.dart';
import 'confirm_sheet.dart';

/// Asks "Discard your changes?" when a form with unsaved edits is left by
/// Back — the top bar's or the system's — and lets it go once confirmed.
/// Untouched, it gets out of the way.
///
/// A screen that closes itself after saving uses [Navigator.pop], which does
/// not consult this guard.
class DiscardGuard extends StatelessWidget {
  const DiscardGuard({required this.isDirty, required this.child, super.key});

  final bool isDirty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !isDirty,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        if (didPop) return;
        final AppLocalizations l10n = context.l10n;
        final bool discard = await showConfirmSheet(
          context,
          title: l10n.discardTitle,
          message: l10n.discardBody,
          confirmLabel: l10n.discardConfirm,
          cancelLabel: l10n.discardKeep,
          destructive: true,
        );
        if (discard && context.mounted) Navigator.of(context).pop();
      },
      child: child,
    );
  }
}
