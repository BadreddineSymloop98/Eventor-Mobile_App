import 'package:flutter/material.dart';

import '../constants/ui_helpers.dart';
import '../localization/app_localizations_x.dart';
import '../../l10n/app_localizations.dart';

/// Shown when a route name has no matching page.
class UnknownRouteView extends StatelessWidget {
  const UnknownRouteView({required this.routeName, super.key});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.unknownRouteTitle)),
      body: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Center(
          child: Text(
            l10n.unknownRouteMessage(routeName ?? ''),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
