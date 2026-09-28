import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/messaging/messaging_repository.dart';
import '../../core/provider/provider_repository.dart';
import '../../core/routing/app_routes.dart';
import '../provider_booking/view/provider_booking_view.dart';
import '../provider_booking/view/provider_check_in_view.dart';
import '../provider_booking/view/provider_reschedule_view.dart';
import '../provider_booking/view_model/provider_booking_view_model.dart';
import '../provider_booking/view_model/provider_check_in_view_model.dart';
import '../provider_booking/view_model/provider_reschedule_view_model.dart';
import 'view/provider_requests_view.dart';
import 'view_model/provider_requests_view_model.dart';

// Section 10's booking half (P1–P5), for the router to mount. Depends on
// `ProviderRepository`, `MessagingRepository` and `AppConfigRepository`, all
// read from the widget tree.

/// P1 — the provider shell's second branch (`AppRoutes.providerRequests`).
/// `?tab=upcoming|past` opens it on that list — 21's "See all" under
/// Upcoming.
Widget buildProviderRequestsTab(BuildContext context, GoRouterState state) {
  final ProviderBookingTab initial =
      ProviderBookingTab.values.asNameMap()[state.uri.queryParameters['tab']] ??
          ProviderBookingTab.requests;
  return ChangeNotifierProvider<ProviderRequestsViewModel>(
    // A link to another list is a fresh start on it, not the old list.
    key: ValueKey<String>('provider-requests-${initial.name}'),
    create: (BuildContext context) => ProviderRequestsViewModel(
      provider: context.read<ProviderRepository>(),
      replyDeadlineHours: context.read<AppConfigRepository>().current.bookingReplyDeadlineHours,
      initialTab: initial,
    ),
    child: const ProviderRequestsView(),
  );
}

/// P2 (and its variants), P4 and P5 — full screen, over the tabs. Mount them
/// at the top level, after the shells; they all sit under `/provider/` so
/// the role gate already keeps clients out.
List<RouteBase> providerRequestsRoutes() => <RouteBase>[
      GoRoute(
        path: '${AppRoutes.providerBooking}/:id',
        builder: (_, GoRouterState state) => ChangeNotifierProvider<ProviderBookingViewModel>(
          create: (BuildContext context) => ProviderBookingViewModel(
            id: state.pathParameters['id']!,
            provider: context.read<ProviderRepository>(),
            messaging: context.read<MessagingRepository>(),
            replyDeadlineHours: context.read<AppConfigRepository>().current.bookingReplyDeadlineHours,
          ),
          child: const ProviderBookingView(),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.providerBooking}/:id/reschedule',
        redirect: _needsBooking,
        builder: (_, GoRouterState state) => ChangeNotifierProvider<ProviderRescheduleViewModel>(
          create: (BuildContext context) => ProviderRescheduleViewModel(
            booking: state.extra! as ProviderBooking,
            provider: context.read<ProviderRepository>(),
          ),
          child: const ProviderRescheduleView(),
        ),
      ),
      // With the booking as `extra` from P2, or loaded by id from the
      // post-event notification.
      GoRoute(
        path: '${AppRoutes.providerBooking}/:id/check-in',
        builder: (_, GoRouterState state) => ChangeNotifierProvider<ProviderCheckInViewModel>(
          create: (BuildContext context) => ProviderCheckInViewModel(
            id: state.pathParameters['id']!,
            provider: context.read<ProviderRepository>(),
            booking: state.extra is ProviderBooking ? state.extra! as ProviderBooking : null,
          ),
          child: const ProviderCheckInView(),
        ),
      ),
    ];

/// P4 opens with the booking it moves; without it (a cold start on the
/// path) it falls back to P2.
String? _needsBooking(BuildContext _, GoRouterState state) => state.extra is ProviderBooking
    ? null
    : AppRoutes.providerBookingFor(state.pathParameters['id']!);
