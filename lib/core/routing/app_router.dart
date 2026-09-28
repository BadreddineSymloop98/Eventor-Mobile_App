import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/booking_detail/view/booking_detail_view.dart';
import '../../features/booking_detail/view_model/booking_detail_view_model.dart';
import '../../features/booking_request/view/booking_request_view.dart';
import '../../features/booking_request/view/pack_booking_view.dart';
import '../../features/booking_request/view/pack_review_view.dart';
import '../../features/booking_request/view/request_sent_view.dart';
import '../../features/booking_request/view_model/booking_request_view_model.dart';
import '../../features/booking_request/view_model/request_sent_view_model.dart';
import '../../features/bookings/view/bookings_view.dart';
import '../../features/bookings/view_model/bookings_view_model.dart';
import '../../features/check_in/view/check_in_view.dart';
import '../../features/check_in/view_model/check_in_view_model.dart';
import '../../features/invoice/view/invoice_view.dart';
import '../../features/invoice/view_model/invoice_view_model.dart';
import '../../features/reschedule/view/reschedule_view.dart';
import '../../features/reschedule/view_model/reschedule_view_model.dart';
import '../../features/auth/data/documents_repository.dart';
import '../../features/budget/view/budget_form_view.dart';
import '../../features/budget/view/budget_view.dart';
import '../../features/budget/view/expense_form_view.dart';
import '../../features/budget/view/link_booking_view.dart';
import '../../features/budget/view_model/budget_form_view_model.dart';
import '../../features/budget/view_model/budget_view_model.dart';
import '../../features/budget/view_model/expense_form_view_model.dart';
import '../../features/budget/view_model/link_booking_view_model.dart';
import '../../features/documents/view/documents_view.dart';
import '../bookings/bookings_repository.dart';
import '../budget/budget_repository.dart';
import '../../features/documents/view_model/documents_view_model.dart';
import '../../features/forgot_password/view/forgot_password_view.dart';
import '../../features/forgot_password/view_model/forgot_password_view_model.dart';
import '../../features/gallery/view/gallery_view.dart';
import '../../features/home/view/home_view.dart';
import '../../features/messages/view/messages_view.dart';
import '../../features/messages/view_model/messages_view_model.dart';
import '../messaging/chat_poller.dart';
import '../notifications/notifications_repository.dart';
import '../../features/notifications/view/notifications_view.dart';
import '../../features/notifications/view_model/notifications_view_model.dart';
import '../messaging/messaging_repository.dart';
import '../../features/chat/view/chat_view.dart';
import '../../features/chat/view_model/chat_view_model.dart';
import '../../features/home/view_model/home_view_model.dart';
import '../../features/favourites/view/favourites_view.dart';
import '../../features/favourites/view_model/favourites_view_model.dart';
import '../../features/pack_detail/view/pack_detail_view.dart';
import '../../features/pack_detail/view_model/pack_detail_view_model.dart';
import '../../features/packs/view/packs_view.dart';
import '../../features/packs/view_model/packs_view_model.dart';
import '../../features/provider_profile/view/provider_profile_view.dart';
import '../../features/provider_profile/view_model/provider_profile_view_model.dart';
import '../../features/search/view/results_view.dart';
import '../../features/service_detail/view/service_detail_view.dart';
import '../../features/service_detail/view_model/service_detail_view_model.dart';
import '../../features/search/view/search_view.dart';
import '../../features/search/view_model/results_view_model.dart';
import '../../features/search/view_model/search_view_model.dart';
import '../../features/shell/shell_badges.dart';
import '../catalog/favourites_controller.dart';
import '../catalog/favourites_repository.dart';
import '../catalog/models/pack.dart';
import '../catalog/recent_searches.dart';
import '../catalog/service_query.dart';
import '../catalog/catalog_repository.dart';
import '../../features/provider_home/view/provider_home_view.dart';
import '../../features/provider_requests/provider_requests_routes.dart';
import '../../features/provider_services/provider_services_routes.dart';
import '../../features/availability/availability_routes.dart';
import '../provider_catalog/provider_catalog_repository.dart';
import '../../features/provider_home/view_model/provider_home_view_model.dart';
import '../../features/resubmit_documents/view/resubmit_documents_view.dart';
import '../../features/resubmit_documents/view_model/resubmit_documents_view_model.dart';
import '../../features/shell/view/provider_profile_tab_view.dart';
import '../../features/shell/view/provider_shell.dart';
import '../provider/provider_repository.dart';
import '../../features/shell/view/client_shell.dart';
import '../../features/shell/view/profile_tab_view.dart';
import '../../features/login/view/login_view.dart';
import '../../features/login/view_model/login_view_model.dart';
import '../../features/onboarding/view/onboarding_view.dart';
import '../../features/onboarding/view_model/onboarding_view_model.dart';
import '../../features/register/view/register_view.dart';
import '../../features/register/view_model/register_view_model.dart';
import '../../features/reset_password/view/reset_code_view.dart';
import '../../features/reset_password/view/reset_password_view.dart';
import '../../features/reset_password/view_model/reset_code_view_model.dart';
import '../../features/reset_password/view_model/reset_password_view_model.dart';
import '../../features/role_selection/view/role_selection_view.dart';
import '../../features/role_selection/view_model/role_selection_view_model.dart';
import '../../features/set_password/view/set_password_view.dart';
import '../../features/set_password/view_model/set_password_view_model.dart';
import '../../features/splash/view/splash_view.dart';
import '../../features/verify_email/view/verify_email_view.dart';
import '../../features/verify_email/view_model/verify_email_view_model.dart';
import '../../features/welcome/view/welcome_view.dart';
import '../../features/welcome/view_model/welcome_view_model.dart';
import '../config/app_config.dart';
import '../localization/locale_controller.dart';
import '../models/account.dart';
import '../reference/reference_repository.dart';
import '../services/preferences_service.dart';
import '../session/session_controller.dart';
import '../startup/app_startup.dart';
import 'app_routes.dart';
import 'unknown_route_view.dart';

/// Where a user may be, decided in one place.
///
/// Pulled out of the router so every rule can be tested without a widget:
///
/// * nothing is routed until [AppStartup] is ready — every path waits on the
///   splash, remembering where it was headed (an invite link opened cold);
/// * the splash then hands over to the user's landing: onboarding the first
///   time, then Welcome until one of its doors has been taken, then Login;
///   home (or a one-off landing like `08e`) with a session;
/// * with a session, the pre-auth screens are off limits;
/// * without one, the signed-in screens send the user to that same signed-out
///   landing — or to Login with the "session ended" banner when the session
///   died mid-use.
class AppRedirect {
  const AppRedirect({
    required this.startup,
    required this.session,
    required this.preferences,
  });

  final AppStartup startup;
  final SessionController session;
  final PreferencesService preferences;

  static const String _nextKey = 'next';
  static const String expiredKey = 'expired';

  String? call(Uri uri) {
    final String path = uri.path;

    // The gallery is a developer tool, reachable in any state.
    if (path == AppRoutes.gallery) return null;

    if (!startup.isReady) {
      if (path == AppRoutes.splash) return null;
      return Uri(
        path: AppRoutes.splash,
        queryParameters: <String, String>{_nextKey: uri.toString()},
      ).toString();
    }

    if (path == AppRoutes.splash) {
      final String? next = uri.queryParameters[_nextKey];
      // A deep link that arrived during startup gets its turn now. Only the
      // invite link is honoured this way; anything else lands normally.
      if (next != null && Uri.parse(next).path == AppRoutes.setPassword) {
        return next;
      }
      return _landing();
    }

    final bool isPublic = AppRoutes.public.contains(path);

    if (session.isSignedIn) {
      final AppUser user = session.user!;
      if (isPublic) return _landing();
      // Two shells, the client's and the provider's. A deep link or a stale
      // stack never crosses over; chat and the bell belong to both.
      if (user.isProvider && AppRoutes.isClientOnly(path)) {
        return AppRoutes.providerHome;
      }
      if (!user.isProvider && AppRoutes.isProviderOnly(path)) {
        return AppRoutes.home;
      }
      // Reached the one-off landing (a new provider's documents): retire it.
      session.arrivedAt(path);
      return null;
    }

    if (!isPublic) {
      return session.consumeExpired()
          ? Uri(
              path: AppRoutes.login,
              queryParameters: <String, String>{expiredKey: '1'},
            ).toString()
          : _signedOutLanding();
    }
    return null;
  }

  String _landing() {
    if (session.isSignedIn) {
      return session.landing ??
          (session.user!.isProvider ? AppRoutes.providerHome : AppRoutes.home);
    }
    return _signedOutLanding();
  }

  /// Onboarding and Welcome are each shown once; after both, the door a
  /// returning user wants is Login — and it links to sign-up for anyone who
  /// does not have an account yet.
  String _signedOutLanding() {
    if (!preferences.hasSeenOnboarding) return AppRoutes.onboarding;
    if (!preferences.hasSeenWelcome) return AppRoutes.welcome;
    return AppRoutes.login;
  }
}

/// Builds the app's [GoRouter].
///
/// Each screen is paired with its view model here, so a view never has to know
/// how its view model is constructed and the view model is disposed together
/// with the route.
abstract final class AppRouter {
  static GoRouter create({
    required AppStartup startup,
    required SessionController session,
    required PreferencesService preferences,
    String initialLocation = AppRoutes.splash,
  }) {
    final AppRedirect redirect = AppRedirect(
      startup: startup,
      session: session,
      preferences: preferences,
    );

    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: Listenable.merge(<Listenable>[startup, session]),
      redirect: (BuildContext context, GoRouterState state) =>
          redirect(state.uri),
      errorBuilder: (BuildContext context, GoRouterState state) =>
          UnknownRouteView(routeName: state.uri.toString()),
      routes: <RouteBase>[
        GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashView()),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => _withViewModel<OnboardingViewModel>(
            (BuildContext context) =>
                OnboardingViewModel(context.read<PreferencesService>()),
            const OnboardingView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          builder: (_, _) => _withViewModel<WelcomeViewModel>(
            (BuildContext context) =>
                WelcomeViewModel(context.read<PreferencesService>()),
            const WelcomeView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.roleSelection,
          builder: (_, _) => _withViewModel<RoleSelectionViewModel>(
            (_) => RoleSelectionViewModel(),
            const RoleSelectionView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (_, GoRouterState state) {
            // A register link without a role — typed, or from an old build —
            // is treated as a client's, the one that needs no documents.
            final UserRole role =
                UserRole.fromApi(state.uri.queryParameters['role']) ??
                UserRole.client;
            return _withViewModel<RegisterViewModel>(
              (BuildContext context) => RegisterViewModel(
                auth: context.read<AuthRepository>(),
                reference: context.read<ReferenceRepository>(),
                config: context.read<AppConfigRepository>().current,
                role: role,
                languageCode: () => _languageOf(context),
              ),
              const RegisterView(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          redirect: (_, GoRouterState state) =>
              state.extra is VerifyEmailArgs ? null : AppRoutes.login,
          builder: (_, GoRouterState state) =>
              _withViewModel<VerifyEmailViewModel>(
                (BuildContext context) => VerifyEmailViewModel(
                  auth: context.read<AuthRepository>(),
                  session: context.read<SessionController>(),
                  args: state.extra! as VerifyEmailArgs,
                ),
                const VerifyEmailView(),
              ),
        ),
        GoRoute(
          path: AppRoutes.documents,
          builder: (_, _) => _withViewModel<DocumentsViewModel>(
            (BuildContext context) => DocumentsViewModel(
              documents: context.read<DocumentsRepository>(),
              session: context.read<SessionController>(),
              acceptedExtensions: context
                  .read<AppConfigRepository>()
                  .current
                  .documentExtensions,
            ),
            const DocumentsView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, GoRouterState state) {
            final Map<String, String> query = state.uri.queryParameters;
            return _withViewModel<LoginViewModel>(
              (BuildContext context) => LoginViewModel(
                auth: context.read<AuthRepository>(),
                session: context.read<SessionController>(),
                initialEmail: query['email'],
                sessionExpired: query[AppRedirect.expiredKey] == '1',
              ),
              LoginView(announceReset: query['reset'] == '1'),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, _) => _withViewModel<ForgotPasswordViewModel>(
            (BuildContext context) =>
                ForgotPasswordViewModel(auth: context.read<AuthRepository>()),
            const ForgotPasswordView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.resetCode,
          redirect: (_, GoRouterState state) =>
              (state.uri.queryParameters['email'] ?? '').isEmpty
              ? AppRoutes.forgotPassword
              : null,
          builder: (_, GoRouterState state) =>
              _withViewModel<ResetCodeViewModel>(
                (BuildContext context) => ResetCodeViewModel(
                  auth: context.read<AuthRepository>(),
                  email: state.uri.queryParameters['email']!,
                ),
                const ResetCodeView(),
              ),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          redirect: (_, GoRouterState state) => state.extra is ResetPasswordArgs
              ? null
              : AppRoutes.forgotPassword,
          builder: (_, GoRouterState state) =>
              _withViewModel<ResetPasswordViewModel>(
                (BuildContext context) => ResetPasswordViewModel(
                  auth: context.read<AuthRepository>(),
                  config: context.read<AppConfigRepository>().current,
                  args: state.extra! as ResetPasswordArgs,
                ),
                const ResetPasswordView(),
              ),
        ),
        GoRoute(
          path: AppRoutes.setPassword,
          builder: (_, GoRouterState state) =>
              _withViewModel<SetPasswordViewModel>(
                (BuildContext context) => SetPasswordViewModel(
                  auth: context.read<AuthRepository>(),
                  session: context.read<SessionController>(),
                  config: context.read<AppConfigRepository>().current,
                  token: state.uri.queryParameters['token'],
                ),
                const SetPasswordView(),
              ),
        ),
        // The client's five tabs. Each branch keeps its own stack; the
        // catalog's detail screens below are top-level routes, so they open
        // over the tab bar, full screen, as drawn.
        StatefulShellRoute.indexedStack(
          builder: (_, _, StatefulNavigationShell shell) =>
              ClientShell(navigationShell: shell),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.home,
                  builder: (_, _) => _withViewModel<HomeViewModel>(
                    (BuildContext context) => HomeViewModel(
                      catalog: context.read<CatalogRepository>(),
                      auth: context.read<AuthRepository>(),
                      session: context.read<SessionController>(),
                      badges: context.read<ShellBadges>(),
                      reference: context.read<ReferenceRepository>(),
                    ),
                    const HomeView(),
                  ),
                  // Results opened from Home stay in the Home tab, so Back
                  // returns to Home.
                  routes: <RouteBase>[
                    GoRoute(path: 'results', builder: _resultsPage),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.search,
                  builder: (_, _) => _withViewModel<SearchViewModel>(
                    (BuildContext context) => SearchViewModel(
                      catalog: context.read<CatalogRepository>(),
                      recents: RecentSearches(
                        context.read<PreferencesService>(),
                      ),
                    ),
                    const SearchView(),
                  ),
                  routes: <RouteBase>[
                    GoRoute(path: 'results', builder: _resultsPage),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.bookings,
                  builder: (_, _) => _withViewModel<BookingsViewModel>(
                    (BuildContext context) => BookingsViewModel(
                      bookings: context.read<BookingsRepository>(),
                    ),
                    const BookingsView(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.messages,
                  builder: (_, _) => _withViewModel<MessagesViewModel>(
                    (BuildContext context) => MessagesViewModel(
                      messaging: context.read<MessagingRepository>(),
                      badges: context.read<ShellBadges>(),
                    ),
                    const MessagesView(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.profile,
                  builder: (_, _) => const ProfileTabView(),
                ),
              ],
            ),
          ],
        ),
        // The provider's five tabs (21). The profile tab is still a stub.
        StatefulShellRoute.indexedStack(
          builder: (_, _, StatefulNavigationShell shell) =>
              ProviderShell(navigationShell: shell),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.providerHome,
                  builder: (_, _) => _withViewModel<ProviderHomeViewModel>(
                    (BuildContext context) => ProviderHomeViewModel(
                      provider: context.read<ProviderRepository>(),
                      session: context.read<SessionController>(),
                      badges: context.read<ShellBadges>(),
                      replyDeadlineHours: context
                          .read<AppConfigRepository>()
                          .current
                          .bookingReplyDeadlineHours,
                    ),
                    const ProviderHomeView(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                // P1 / P1a / P1b.
                GoRoute(
                  path: AppRoutes.providerRequests,
                  builder: buildProviderRequestsTab,
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                // P6 / P10 and their empty and hidden states.
                GoRoute(
                  path: AppRoutes.providerServices,
                  builder: buildProviderServicesTab,
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.providerMessages,
                  builder: (_, _) => _withViewModel<MessagesViewModel>(
                    (BuildContext context) => MessagesViewModel(
                      messaging: context.read<MessagingRepository>(),
                      badges: context.read<ShellBadges>(),
                    ),
                    const MessagesView(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.providerProfile,
                  builder: (_, _) => const ProviderProfileTabView(),
                ),
              ],
            ),
          ],
        ),
        // Section 10: P2–P5, full screen over the provider's tabs.
        ...providerRequestsRoutes(),
        // P7–P13: services, packs and their photos.
        ...providerServicesRoutes(),
        // P15: the calendar; its "Which services" picker lists the
        // provider's own services.
        ...availabilityRoutes(
          loadServices: (BuildContext context) async => <ProviderServiceRow>[
            for (final ProviderServiceSummary service
                in await context.read<ProviderCatalogRepository>().services())
              service.toRow(),
          ],
        ),
        // 08d, full screen over the provider's tabs.
        GoRoute(
          path: AppRoutes.resubmitDocuments,
          builder: (_, _) => _withViewModel<ResubmitDocumentsViewModel>(
            (BuildContext context) => ResubmitDocumentsViewModel(
              documents: context.read<DocumentsRepository>(),
              session: context.read<SessionController>(),
              acceptedExtensions: context
                  .read<AppConfigRepository>()
                  .current
                  .documentExtensions,
            ),
            const ResubmitDocumentsView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (_, _) => _withViewModel<NotificationsViewModel>(
            (BuildContext context) => NotificationsViewModel(
              notifications: context.read<NotificationsRepository>(),
              badges: context.read<ShellBadges>(),
            ),
            const NotificationsView(),
          ),
        ),
        // 15. The draft route comes first: `new` would otherwise match `:id`.
        GoRoute(
          path: AppRoutes.chatDraft,
          redirect: (_, GoRouterState state) =>
              (state.uri.queryParameters['user'] ?? '').isEmpty
              ? AppRoutes.messages
              : null,
          builder: (_, GoRouterState state) => _chatPage(
            draft: ChatDraftPeer(
              userId: state.uri.queryParameters['user']!,
              name: state.uri.queryParameters['name'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.conversations}/:id',
          builder: (_, GoRouterState state) {
            final Object? extra = state.extra;
            return _chatPage(
              conversationId: state.pathParameters['id'],
              opening: extra is ChatOpening ? extra : null,
            );
          },
        ),
        // The catalog's detail screens: top-level, so they open over the tab
        // bar, full screen, as drawn.
        GoRoute(
          path: '${AppRoutes.services}/:id',
          builder: (_, GoRouterState state) =>
              _withViewModel<ServiceDetailViewModel>(
                (BuildContext context) => ServiceDetailViewModel(
                  id: state.pathParameters['id']!,
                  catalog: context.read<CatalogRepository>(),
                  messaging: context.read<MessagingRepository>(),
                ),
                const ServiceDetailView(),
              ),
        ),
        // Section 9. B1 and B9 open on the day picked on 12 or 20 (`?date=`).
        GoRoute(
          path: '${AppRoutes.services}/:id/book',
          builder: (_, GoRouterState state) =>
              _withViewModel<BookingRequestViewModel>(
                (BuildContext context) => _bookingRequest(
                  context,
                  state,
                  serviceId: state.pathParameters['id'],
                ),
                const BookingRequestView(),
              ),
        ),
        GoRoute(
          path: '${AppRoutes.packs}/:id/book',
          builder: (_, GoRouterState state) =>
              _withViewModel<BookingRequestViewModel>(
                (BuildContext context) => _bookingRequest(
                  context,
                  state,
                  packId: state.pathParameters['id'],
                ),
                const PackBookingView(),
              ),
        ),
        // B9a shares B9's view model; without it (a cold start) it is B9.
        GoRoute(
          path: '${AppRoutes.packs}/:id/book/review',
          redirect: (_, GoRouterState state) => state.extra is BookingRequestViewModel
              ? null
              : AppRoutes.bookPackFor(state.pathParameters['id']!),
          builder: (_, GoRouterState state) =>
              ChangeNotifierProvider<BookingRequestViewModel>.value(
                value: state.extra! as BookingRequestViewModel,
                child: const PackReviewView(),
              ),
        ),
        // `sent` first: it would otherwise match `:id`.
        GoRoute(
          path: AppRoutes.bookingSent,
          redirect: (_, GoRouterState state) =>
              state.extra is RequestSentArgs ? null : AppRoutes.bookings,
          builder: (_, GoRouterState state) => _withViewModel<RequestSentViewModel>(
            (BuildContext context) => RequestSentViewModel(
              args: state.extra! as RequestSentArgs,
              messaging: context.read<MessagingRepository>(),
              replyDeadlineHours: context
                  .read<AppConfigRepository>()
                  .current
                  .bookingReplyDeadlineHours,
            ),
            const RequestSentView(),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.booking}/:id',
          builder: (_, GoRouterState state) => _withViewModel<BookingDetailViewModel>(
            (BuildContext context) => BookingDetailViewModel(
              id: state.pathParameters['id']!,
              bookings: context.read<BookingsRepository>(),
              messaging: context.read<MessagingRepository>(),
              replyDeadlineHours: context
                  .read<AppConfigRepository>()
                  .current
                  .bookingReplyDeadlineHours,
            ),
            const BookingDetailView(),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.booking}/:id/reschedule',
          redirect: _needsBooking,
          builder: (_, GoRouterState state) => _withViewModel<RescheduleViewModel>(
            (BuildContext context) => RescheduleViewModel(
              booking: state.extra! as BookingDetail,
              bookings: context.read<BookingsRepository>(),
              catalog: context.read<CatalogRepository>(),
            ),
            const RescheduleView(),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.booking}/:id/check-in',
          redirect: _needsBooking,
          builder: (_, GoRouterState state) => _withViewModel<CheckInViewModel>(
            (BuildContext context) => CheckInViewModel(
              booking: state.extra! as BookingDetail,
              bookings: context.read<BookingsRepository>(),
            ),
            const CheckInView(),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.booking}/:id/invoice',
          builder: (_, GoRouterState state) => _withViewModel<InvoiceViewModel>(
            (BuildContext context) => InvoiceViewModel(
              bookingId: state.pathParameters['id']!,
              bookings: context.read<BookingsRepository>(),
            ),
            const InvoiceView(),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.providers}/:id',
          builder: (_, GoRouterState state) =>
              _withViewModel<ProviderProfileViewModel>(
                (BuildContext context) => ProviderProfileViewModel(
                  id: state.pathParameters['id']!,
                  catalog: context.read<CatalogRepository>(),
                  messaging: context.read<MessagingRepository>(),
                ),
                const ProviderProfileView(),
              ),
        ),
        GoRoute(
          path: AppRoutes.packs,
          builder: (_, GoRouterState state) {
            final String? type = state.uri.queryParameters['eventType'];
            return _withViewModel<PacksViewModel>(
              (BuildContext context) => PacksViewModel(
                catalog: context.read<CatalogRepository>(),
                eventType: type == null ? null : EventType.fromApi(type),
              ),
              const PacksView(),
            );
          },
        ),
        GoRoute(
          path: '${AppRoutes.packs}/:id',
          builder: (_, GoRouterState state) =>
              _withViewModel<PackDetailViewModel>(
                (BuildContext context) => PackDetailViewModel(
                  id: state.pathParameters['id']!,
                  catalog: context.read<CatalogRepository>(),
                ),
                const PackDetailView(),
              ),
        ),
        GoRoute(
          path: AppRoutes.favourites,
          builder: (_, _) => _withViewModel<FavouritesViewModel>(
            (BuildContext context) => FavouritesViewModel(
              favourites: context.read<FavouritesRepository>(),
              catalog: context.read<CatalogRepository>(),
              controller: context.read<FavouritesController>(),
            ),
            const FavouritesView(),
          ),
        ),
        // Section 7. Each screen after 18 opens with what it edits as
        // `extra`; without it (a cold start on the path) it falls back to 18.
        GoRoute(
          path: AppRoutes.budget,
          builder: (_, _) => _withViewModel<BudgetViewModel>(
            (BuildContext context) =>
                BudgetViewModel(budgets: context.read<BudgetRepository>()),
            const BudgetView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.budgetEdit,
          redirect: (_, GoRouterState state) =>
              state.extra is Budget ? null : AppRoutes.budget,
          builder: (_, GoRouterState state) =>
              _withViewModel<BudgetFormViewModel>(
                (BuildContext context) => BudgetFormViewModel(
                  budgets: context.read<BudgetRepository>(),
                  initial: state.extra! as Budget,
                ),
                const BudgetFormView(),
              ),
        ),
        // `new` first: it would otherwise match `:id`.
        GoRoute(
          path: AppRoutes.budgetNewLine,
          redirect: _needsLineArgs,
          builder: _expensePage,
        ),
        GoRoute(
          path: '${AppRoutes.budgetLines}/:id',
          redirect: _needsLineArgs,
          builder: _expensePage,
        ),
        GoRoute(
          path: AppRoutes.budgetLinkBooking,
          redirect: (_, GoRouterState state) =>
              state.extra is LinkBookingArgs ? null : AppRoutes.budget,
          builder: (_, GoRouterState state) =>
              _withViewModel<LinkBookingViewModel>(
                (BuildContext context) => LinkBookingViewModel(
                  bookings: context.read<BookingsRepository>(),
                  args: state.extra! as LinkBookingArgs,
                ),
                const LinkBookingView(),
              ),
        ),
        if (kDebugMode)
          GoRoute(
            path: AppRoutes.gallery,
            builder: (_, _) => const GalleryView(),
          ),
      ],
    );
  }

  /// B6 and B7 open with the booking they act on; without it (a cold start
  /// on the path) they fall back to B4.
  static String? _needsBooking(BuildContext _, GoRouterState state) =>
      state.extra is BookingDetail
          ? null
          : AppRoutes.bookingFor(state.pathParameters['id']!);

  /// B1 (a service) or B9 (a pack), on the day carried in `?date=`.
  static BookingRequestViewModel _bookingRequest(
    BuildContext context,
    GoRouterState state, {
    String? serviceId,
    String? packId,
  }) =>
      BookingRequestViewModel(
        serviceId: serviceId,
        packId: packId,
        initialDate: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
        catalog: context.read<CatalogRepository>(),
        bookings: context.read<BookingsRepository>(),
        reference: context.read<ReferenceRepository>(),
        session: context.read<SessionController>(),
      );

  static String? _needsLineArgs(BuildContext _, GoRouterState state) =>
      state.extra is ExpenseLineArgs ? null : AppRoutes.budget;

  /// 18d / 18b — the same form, adding or editing.
  static Widget _expensePage(BuildContext _, GoRouterState state) =>
      _withViewModel<ExpenseFormViewModel>(
        (BuildContext context) => ExpenseFormViewModel(
          budgets: context.read<BudgetRepository>(),
          catalog: context.read<CatalogRepository>(),
          args: state.extra! as ExpenseLineArgs,
        ),
        const ExpenseFormView(),
      );

  /// S2 / S2a / S2b, under Search or under Home. Keyed by the whole URL: a
  /// new sort or filter is a new results page with its own view model, not a
  /// reload of the old one.
  static Widget _resultsPage(BuildContext _, GoRouterState state) =>
      _withViewModel<ResultsViewModel>(
        (BuildContext context) => ResultsViewModel(
          query: ServiceQuery.fromRouteParams(state.uri.queryParametersAll),
          catalog: context.read<CatalogRepository>(),
        ),
        const ResultsView(),
        key: ValueKey<String>(state.uri.toString()),
      );

  /// 15, for a conversation or a draft. Each chat polls on its own timer,
  /// released with its view model when the route goes.
  static Widget _chatPage({
    String? conversationId,
    ChatDraftPeer? draft,
    ChatOpening? opening,
  }) => _withViewModel<ChatViewModel>(
    (BuildContext context) => ChatViewModel(
      messaging: context.read<MessagingRepository>(),
      catalog: context.read<CatalogRepository>(),
      badges: context.read<ShellBadges>(),
      config: context.read<AppConfigRepository>().current,
      updates: TimerChatUpdates(),
      conversationId: draft == null ? conversationId : null,
      draft: draft,
      opening: opening,
    ),
    const ChatView(),
  );

  /// Wraps [child] in a [ChangeNotifierProvider] holding its view model,
  /// created from the route's own context so it can read the app's services.
  static Widget _withViewModel<V extends ChangeNotifier>(
    V Function(BuildContext context) create,
    Widget child, {
    Key? key,
  }) {
    return ChangeNotifierProvider<V>(key: key, create: create, child: child);
  }

  /// The language the app is showing, for requests that must name it.
  static String _languageOf(BuildContext context) {
    final Locale? chosen = context.read<LocaleController>().locale;
    return (chosen ?? Localizations.localeOf(context)).languageCode == 'ar'
        ? 'ar'
        : 'en';
  }
}
