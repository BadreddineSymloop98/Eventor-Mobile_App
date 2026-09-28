import 'package:eventor/app/app_services.dart';
import 'package:eventor/app/eventor_app.dart';
import 'package:eventor/core/catalog/favourites_controller.dart';
import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/localization/app_localizations_x.dart';
import 'package:eventor/core/localization/locale_controller.dart';
import 'package:eventor/core/network/api_client.dart';
import 'package:eventor/core/routing/app_router.dart';
import 'package:eventor/core/services/preferences_service.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/core/session/token_store.dart';
import 'package:eventor/core/startup/app_startup.dart';
import 'package:eventor/core/theme/app_theme.dart';
import 'package:eventor/features/shell/shell_badges.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_fakes.dart';
import 'fakes.dart';
import 'availability_fakes.dart';
import 'provider_catalog_fakes.dart';
import 'provider_fakes.dart';

/// The locales the suite exercises.
const Locale englishLocale = Locale('en');
const Locale arabicLocale = Locale('ar');

/// The whole app on fakes: the real router, session and startup, with every
/// repository scripted and nothing touching the network or the keychain.
class TestApp {
  TestApp._(
    this.services,
    this.auth,
    this.reference,
    this.documents,
    this.catalog,
    this.favouritesRepository,
    this.messaging,
    this.notifications,
    this.budget,
    this.bookings,
    this.provider,
    this.providerCatalog,
    this.availability,
  );

  final AppServices services;
  final FakeAuthRepository auth;
  final FakeReferenceRepository reference;
  final FakeDocumentsRepository documents;
  final FakeCatalogRepository catalog;
  final FakeFavouritesRepository favouritesRepository;
  final FakeMessagingRepository messaging;
  final FakeNotificationsRepository notifications;
  final FakeBudgetRepository budget;
  final FakeBookingsRepository bookings;
  final FakeProviderRepository provider;
  final FakeProviderCatalogRepository providerCatalog;
  final FakeAvailabilityRepository availability;

  SessionController get session => services.session;

  EventorApp get widget => EventorApp(services: services);
}

/// Builds [TestApp] on an in-memory preference store.
///
/// Pass `hasSeenOnboarding: true` to simulate a launch after the first one —
/// plus `hasSeenWelcome: true` for one that opens on Login rather than Welcome —
/// [locale] to start in a particular language, and a [FakeAuthRepository]
/// whose `restoredUser` is set to start signed in.
Future<TestApp> buildTestApp({
  bool hasSeenOnboarding = false,
  bool hasSeenWelcome = false,
  Locale? locale,
  FakeAuthRepository? auth,
  FakeCatalogRepository? catalog,
  FakeFavouritesRepository? favourites,
  FakeMessagingRepository? messaging,
  FakeNotificationsRepository? notifications,
  FakeBudgetRepository? budget,
  FakeBookingsRepository? bookings,
  FakeProviderRepository? provider,
  FakeProviderCatalogRepository? providerCatalog,
  FakeAvailabilityRepository? availability,
  AppConfig config = const AppConfig(),
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'has_seen_onboarding': hasSeenOnboarding,
    'has_seen_welcome': hasSeenWelcome,
    if (locale != null) 'locale': locale.languageCode,
  });

  final PreferencesService preferences = await PreferencesService.load();
  final FakeAuthRepository fakeAuth = auth ?? FakeAuthRepository();
  final FakeReferenceRepository reference = FakeReferenceRepository();
  final FakeDocumentsRepository documents = FakeDocumentsRepository();
  final FakeConfigRepository fakeConfig = FakeConfigRepository(config);
  final FakeCatalogRepository fakeCatalog = catalog ?? FakeCatalogRepository();
  final FakeFavouritesRepository fakeFavourites =
      favourites ?? FakeFavouritesRepository();
  final FakeMessagingRepository fakeMessaging =
      messaging ?? FakeMessagingRepository();
  final FakeNotificationsRepository fakeNotifications =
      notifications ?? FakeNotificationsRepository();
  final FakeBudgetRepository fakeBudget = budget ?? FakeBudgetRepository();
  final FakeBookingsRepository fakeBookings = bookings ?? FakeBookingsRepository();
  final FakeProviderRepository fakeProvider = provider ?? FakeProviderRepository();
  final FakeProviderCatalogRepository fakeProviderCatalog =
      providerCatalog ?? FakeProviderCatalogRepository();
  final FakeAvailabilityRepository fakeAvailability =
      availability ?? FakeAvailabilityRepository();
  final SessionController session = SessionController(fakeAuth);
  final AppStartup startup = AppStartup(config: fakeConfig, session: session);
  final TokenStore tokens = TokenStore();

  final AppServices services = AppServices(
    preferences: preferences,
    locale: LocaleController(preferences),
    tokens: tokens,
    api: ApiClient(tokens: tokens, languageCode: () => 'en'),
    config: fakeConfig,
    auth: fakeAuth,
    reference: reference,
    documents: documents,
    catalog: fakeCatalog,
    favouritesRepository: fakeFavourites,
    favourites: FavouritesController(fakeFavourites),
    messaging: fakeMessaging,
    notifications: fakeNotifications,
    bookings: fakeBookings,
    budget: fakeBudget,
    provider: fakeProvider,
    providerCatalog: fakeProviderCatalog,
    availability: fakeAvailability,
    badges: ShellBadges(notifications: fakeNotifications),
    session: session,
    startup: startup,
    router: AppRouter.create(
      startup: startup,
      session: session,
      preferences: preferences,
    ),
  );

  return TestApp._(
    services,
    fakeAuth,
    reference,
    documents,
    fakeCatalog,
    fakeFavourites,
    fakeMessaging,
    fakeNotifications,
    fakeBudget,
    fakeBookings,
    fakeProvider,
    fakeProviderCatalog,
    fakeAvailability,
  );
}

/// Pumps [app] and lets the splash hand over.
///
/// Startup is run with no minimum wait. Its floor is still a timer, and a
/// timer only fires when the test clock moves — so the run is started, the
/// clock pumped, and only then awaited.
Future<void> launch(WidgetTester tester, TestApp app) async {
  await tester.pumpWidget(app.widget);
  final Future<void> startup = app.services.startup.run(floor: Duration.zero);
  await tester.pump(const Duration(milliseconds: 1));
  await startup;
  await tester.pumpAndSettle();
}

/// Pumps a single [widget] inside enough of the app to make it work: the
/// theme, the localisation delegates and a [Scaffold].
///
/// Use this instead of a bare [MaterialApp] so that anything reading
/// `context.l10n` has something to read from, and so that a test can be
/// re-run in Arabic by passing [locale].
Future<void> pumpAppWidget(
  WidgetTester tester,
  Widget widget, {
  Locale locale = englishLocale,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(locale),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: widget),
      builder: (BuildContext context, Widget? child) {
        // Mirrors what EventorApp does, so `.dh` and `.dw` resolve against the
        // test surface rather than against the design fallback.
        ScreenMetrics.update(MediaQuery.sizeOf(context));
        return child ?? const SizedBox.shrink();
      },
    ),
  );
}

/// The strings currently in effect, read from the screen on show.
///
/// Lets a test assert against localised copy without hard-coding it, so the
/// same test passes in either language.
AppLocalizations l10n(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).l10n;
