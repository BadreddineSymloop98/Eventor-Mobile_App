import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/constants/ui_helpers.dart';
import '../core/localization/app_localizations_x.dart';
import '../core/localization/locale_controller.dart';
import '../core/routing/app_router.dart';
import '../core/routing/app_routes.dart';
import '../core/services/preferences_service.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Root widget of the app.
///
/// Screen-scoped view models are created per route by [AppRouter]; anything
/// that outlives a single screen — [PreferencesService] and the chosen
/// language — is provided here, above the [MaterialApp].
class EventorApp extends StatelessWidget {
  const EventorApp({required this.preferences, super.key});

  final PreferencesService preferences;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<PreferencesService>.value(value: preferences),
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(preferences),
        ),
      ],
      child: const _EventorMaterialApp(),
    );
  }
}

class _EventorMaterialApp extends StatelessWidget {
  const _EventorMaterialApp();

  @override
  Widget build(BuildContext context) {
    final Locale? locale = context.watch<LocaleController>().locale;

    return MaterialApp(
      onGenerateTitle: (BuildContext context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Always the splash. Which screen follows it is the splash's own
      // decision, not something the app root has to know at startup.
      initialRoute: AppRoutes.initial,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
      builder: (BuildContext context, Widget? child) {
        // Keeps ScreenMetrics — and therefore the `.h` / `.w` helpers — in
        // step with the real window, instead of it being read once at
        // startup and going stale.
        ScreenMetrics.update(MediaQuery.sizeOf(context));
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
