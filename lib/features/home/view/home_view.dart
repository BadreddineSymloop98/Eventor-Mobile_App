import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_x.dart';
import '../../../l10n/app_localizations.dart';

/// Where the user lands after signing in.
///
/// A placeholder. The published design covers the pre-auth flow only — splash,
/// onboarding, welcome, role selection, login, register, forgot password and
/// verify code — and stops there, so there is nothing to build against yet.
/// It exists so the flow does not dead-end at the login screen.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: Center(
        child: Text(
          l10n.homeTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
