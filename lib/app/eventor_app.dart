import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/bookings/bookings_repository.dart';
import '../core/budget/budget_repository.dart';
import '../core/catalog/catalog_repository.dart';
import '../core/catalog/favourites_controller.dart';
import '../core/catalog/favourites_repository.dart';
import '../core/config/app_config.dart';
import '../core/constants/ui_helpers.dart';
import '../core/localization/app_localizations_x.dart';
import '../core/localization/locale_controller.dart';
import '../core/messaging/messaging_repository.dart';
import '../core/notifications/notifications_repository.dart';
import '../core/provider/provider_repository.dart';
import '../core/reference/reference_repository.dart';
import '../core/services/preferences_service.dart';
import '../core/session/session_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/shell/shell_badges.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/documents_repository.dart';
import '../l10n/app_localizations.dart';
import '../mock/mock_backend.dart';
import 'app_services.dart';

/// Root widget of the app.
///
/// Screen-scoped view models are created per route by `AppRouter`; anything
/// that outlives a single screen — the services, the session, the chosen
/// language — is provided here, above the [MaterialApp], so every route can
/// read it.
class EventorApp extends StatelessWidget {
  const EventorApp({required this.services, super.key});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<PreferencesService>.value(value: services.preferences),
        ChangeNotifierProvider<LocaleController>.value(value: services.locale),
        ChangeNotifierProvider<SessionController>.value(
          value: services.session,
        ),
        Provider<AppConfigRepository>.value(value: services.config),
        Provider<AuthRepository>.value(value: services.auth),
        Provider<ReferenceRepository>.value(value: services.reference),
        Provider<DocumentsRepository>.value(value: services.documents),
        Provider<CatalogRepository>.value(value: services.catalog),
        Provider<FavouritesRepository>.value(
          value: services.favouritesRepository,
        ),
        ChangeNotifierProvider<FavouritesController>.value(
          value: services.favourites,
        ),
        Provider<MessagingRepository>.value(value: services.messaging),
        Provider<BookingsRepository>.value(value: services.bookings),
        Provider<BudgetRepository>.value(value: services.budget),
        Provider<ProviderRepository>.value(value: services.provider),
        Provider<NotificationsRepository>.value(
          value: services.notifications,
        ),
        ChangeNotifierProvider<ShellBadges>.value(value: services.badges),
        // Null in a live build; only the debug gallery reads it.
        Provider<MockBackend?>.value(value: services.mockBackend),
      ],
      child: _EventorMaterialApp(services: services),
    );
  }
}

class _EventorMaterialApp extends StatelessWidget {
  const _EventorMaterialApp({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final Locale? locale = context.watch<LocaleController>().locale;

    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      // Light until there is a dark design to follow.
      //
      // The Figma file publishes a single "Light" mode, and every colour the
      // widgets reach for is a light value from `AppColors`. Only the pieces
      // that read the `ColorScheme` would follow the system into dark, so a
      // phone with dark mode on got a lilac primary button on an otherwise
      // white screen. Better to be honestly light than half dark.
      themeMode: ThemeMode.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: services.router,
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
