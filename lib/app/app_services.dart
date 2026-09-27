import 'dart:ui' show PlatformDispatcher;

import 'package:go_router/go_router.dart';

import '../core/bookings/bookings_repository.dart';
import '../core/budget/budget_repository.dart';
import '../core/catalog/catalog_repository.dart';
import '../core/catalog/favourites_controller.dart';
import '../core/catalog/favourites_repository.dart';
import '../core/config/app_config.dart';
import '../core/config/data_source.dart';
import '../core/localization/locale_controller.dart';
import '../core/messaging/messaging_repository.dart';
import '../core/network/api_client.dart';
import '../core/notifications/notifications_repository.dart';
import '../core/provider/provider_repository.dart';
import '../core/reference/reference_repository.dart';
import '../core/routing/app_router.dart';
import '../core/services/preferences_service.dart';
import '../core/session/session_controller.dart';
import '../core/session/token_store.dart';
import '../core/startup/app_startup.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/documents_repository.dart';
import '../mock/mock_backend.dart';
import '../mock/mock_budget.dart';
import '../features/shell/shell_badges.dart';
import '../mock/mock_catalog.dart';
import '../mock/mock_messaging.dart';
import '../mock/mock_provider.dart';
import '../mock/mock_repositories.dart';

/// Everything that lives for the whole run of the app, built once.
///
/// Kept out of the widget tree so the order they depend on each other in is
/// written down in one place — the API client needs the language, the session
/// needs the API, the router needs the session — and so a test can build the
/// same graph with fakes swapped in.
class AppServices {
  AppServices({
    required this.preferences,
    required this.locale,
    required this.tokens,
    required this.api,
    required this.config,
    required this.auth,
    required this.reference,
    required this.documents,
    required this.catalog,
    required this.favouritesRepository,
    required this.favourites,
    required this.messaging,
    required this.notifications,
    required this.bookings,
    required this.budget,
    required this.provider,
    required this.badges,
    required this.session,
    required this.startup,
    required this.router,
    this.mockBackend,
  });

  static Future<AppServices> create() async {
    final PreferencesService preferences = await PreferencesService.load();
    final LocaleController locale = LocaleController(preferences);

    final TokenStore tokens = TokenStore();
    await tokens.load();

    // The language on screen — the chosen one, or the device's. The server
    // translates its messages by it; the mock catalog does the same.
    String languageCode() {
      final String code =
          (locale.locale ?? PlatformDispatcher.instance.locale).languageCode;
      return code == 'ar' ? 'ar' : 'en';
    }

    final ApiClient api = ApiClient(tokens: tokens, languageCode: languageCode);

    // The one place the data source is decided (see DataSource). Everything
    // downstream sees only the interfaces.
    final MockBackend? mock =
        DataSource.current.isMock ? await MockBackend.load() : null;

    final AppConfigRepository config =
        mock != null ? MockConfigRepository(api) : AppConfigRepository(api);
    final AuthRepository auth =
        mock != null ? MockAuthRepository(mock) : ApiAuthRepository(api, tokens);
    final ReferenceRepository reference = mock != null
        ? MockReferenceRepository(mock)
        : ApiReferenceRepository(api);
    final DocumentsRepository documents = mock != null
        ? MockDocumentsRepository(mock)
        : ApiDocumentsRepository(api);
    // One store behind both mock repositories and the mock home feed, so a
    // chat read on 15 clears the badge Home reports.
    final MockMessagingStore? messagingStore = mock != null
        ? MockMessagingStore(
            mock,
            languageCode: languageCode,
            config: config.current,
          )
        : null;
    final CatalogRepository catalog = mock != null
        ? MockCatalogRepository(
            mock,
            languageCode: languageCode,
            messaging: messagingStore,
          )
        : ApiCatalogRepository(api);
    final FavouritesRepository favouritesRepository = mock != null
        ? MockFavouritesRepository(mock, languageCode: languageCode)
        : ApiFavouritesRepository(api);
    final MessagingRepository messaging =
        mock != null && messagingStore != null
            ? MockMessagingRepository(messagingStore, mock)
            : ApiMessagingRepository(api);
    final NotificationsRepository notifications =
        mock != null && messagingStore != null
            ? MockNotificationsRepository(messagingStore, mock)
            : ApiNotificationsRepository(api);
    final BookingsRepository bookings = mock != null
        ? MockBookingsRepository(mock, languageCode: languageCode)
        : ApiBookingsRepository(api);
    final BudgetRepository budget = mock != null
        ? MockBudgetRepository(
            mock,
            MockCatalogLookups(mock, languageCode: languageCode),
          )
        : ApiBudgetRepository(api);
    final ProviderRepository provider = mock != null
        ? MockProviderRepository(
            mock,
            MockCatalogLookups(mock, languageCode: languageCode),
            messaging: messagingStore,
          )
        : ApiProviderRepository(api);
    final SessionController session = SessionController(auth);
    final FavouritesController favourites =
        FavouritesController(favouritesRepository);
    final ShellBadges badges = ShellBadges(notifications: notifications);
    // Hearts and unread counts belong to the account that set them.
    session.addListener(() {
      if (session.isSignedIn) return;
      favourites.clear();
      badges.clear();
    });
    // A refresh refused mid-use ends the session; the router's redirect then
    // takes the user to Login with the "session ended" banner.
    api.onSessionExpired = session.expire;

    final AppStartup startup = AppStartup(config: config, session: session);

    return AppServices(
      preferences: preferences,
      locale: locale,
      tokens: tokens,
      api: api,
      config: config,
      auth: auth,
      reference: reference,
      documents: documents,
      catalog: catalog,
      favouritesRepository: favouritesRepository,
      favourites: favourites,
      messaging: messaging,
      notifications: notifications,
      bookings: bookings,
      budget: budget,
      provider: provider,
      badges: badges,
      mockBackend: mock,
      session: session,
      startup: startup,
      router: AppRouter.create(
        startup: startup,
        session: session,
        preferences: preferences,
      ),
    );
  }

  final PreferencesService preferences;
  final LocaleController locale;
  final TokenStore tokens;
  final ApiClient api;
  final AppConfigRepository config;
  final AuthRepository auth;
  final ReferenceRepository reference;
  final DocumentsRepository documents;
  final CatalogRepository catalog;
  final FavouritesRepository favouritesRepository;

  /// Which hearts are filled, across every screen.
  final FavouritesController favourites;

  /// Screens 14 and 15, and the Message buttons that open them.
  final MessagingRepository messaging;

  /// Screen 16 and the badge counts.
  final NotificationsRepository notifications;

  /// The client's bookings — for now, 18h's list to link a line to.
  final BookingsRepository bookings;

  /// Section 7.
  final BudgetRepository budget;

  /// The provider's home (21) and their answers to requests.
  final ProviderRepository provider;

  /// The bottom nav's counts.
  final ShellBadges badges;
  final SessionController session;
  final AppStartup startup;
  final GoRouter router;

  /// The in-app backend behind the repositories in a mock build; `null` in a
  /// live one. Exposed for the gallery's "Reset mock data".
  final MockBackend? mockBackend;
}
