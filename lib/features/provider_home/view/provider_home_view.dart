import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/models/booking_card.dart';
import '../../../core/catalog/models/pack.dart' show EventType;
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/localization/catalog_labels.dart';
import '../../../core/provider/provider_repository.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/status_badge.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/back_to_exit.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/section_header.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/cards.dart' as ui;
import '../../../l10n/app_localizations.dart';
import '../../shell/shell_badges.dart';
import '../../shell/view/client_shell.dart' show ScrollToTopOnReselect;
import '../view_model/provider_home_view_model.dart';
import 'widgets/provider_home_widgets.dart';

/// Screen 21 — the provider's Home, the first tab — and, until the profile
/// is approved, 21a (pending) and 21b (rejected) in its place.
///
/// Requests are answered here: Accept at once, Decline through P3's sheet.
/// Everything the request, service and calendar modules will own says
/// "Coming soon" until they are built.
class ProviderHomeView extends StatefulWidget {
  const ProviderHomeView({super.key});

  @override
  State<ProviderHomeView> createState() => _ProviderHomeViewState();
}

class _ProviderHomeViewState extends State<ProviderHomeView> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _comingSoon() => showComingSoon(context, context.l10n.comingSoon);

  Future<void> _refresh(ProviderHomeViewModel viewModel) async {
    final Failure? failure = await viewModel.refresh();
    if (failure != null && mounted) {
      showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
    }
  }

  /// 08e or 08d, then back to a home that reflects what was sent.
  Future<void> _openDocuments(ProviderHomeViewModel viewModel, String location) async {
    await context.push(location);
    if (mounted) await viewModel.refresh();
  }

  Future<void> _accept(ProviderHomeViewModel viewModel, BookingCard request) async {
    final AppLocalizations l10n = context.l10n;
    final Failure? failure = await viewModel.accept(request);
    if (!mounted) return;
    if (failure == null) {
      showAppToast(context, l10n.providerAccepted(request.counterpartyName));
    } else {
      showAppToast(context, l10n.forFailure(failure), tone: AppToastTone.error);
    }
  }

  Future<void> _decline(ProviderHomeViewModel viewModel, BookingCard request) async {
    final AppLocalizations l10n = context.l10n;
    final bool declined = await showDeclineSheet(
      context,
      request: request,
      onDecline: (String reason) => viewModel.decline(request, reason),
    );
    if (declined && mounted) {
      showAppToast(context, l10n.providerDeclined, tone: AppToastTone.info);
    }
  }

  Future<void> _availability(ProviderHomeViewModel viewModel, bool accepting) async {
    final bool? choice = await showAvailabilitySheet(context, accepting: accepting);
    if (choice == null || choice == accepting || !mounted) return;
    final Failure? failure = await viewModel.setAcceptingBookings(choice);
    if (!mounted) return;
    final AppLocalizations l10n = context.l10n;
    if (failure != null) {
      showAppToast(context, l10n.forFailure(failure), tone: AppToastTone.error);
    } else {
      showAppToast(
        context,
        choice ? l10n.providerNowAccepting : l10n.providerNowPaused,
        tone: AppToastTone.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProviderHomeViewModel viewModel = context.watch<ProviderHomeViewModel>();
    final ProviderHome? home = viewModel.home;
    final bool hasUnread = context.watch<ShellBadges>().unreadNotifications > 0;

    final Widget body;
    if (home == null) {
      body = viewModel.hasError
          ? Padding(
              padding: AppSpacing.screenPaddingAll,
              child: StateCard.error(onRetry: viewModel.load),
            )
          : const ProviderHomeSkeleton();
    } else if (home.isVerified) {
      body = _VerifiedContent(
        home: home,
        viewModel: viewModel,
        onAccept: (BookingCard r) => _accept(viewModel, r),
        onDecline: (BookingCard r) => _decline(viewModel, r),
        onComingSoon: _comingSoon,
      );
    } else if (home.state == ProviderHomeState.blocked) {
      // Signing out; the redirect takes over.
      body = const ProviderHomeSkeleton();
    } else {
      body = _UnverifiedContent(
        home: home,
        onUpload: () => _openDocuments(viewModel, AppRoutes.documents),
        onResubmit: () => _openDocuments(viewModel, AppRoutes.resubmitDocuments),
      );
    }

    // Home is the bottom of the provider's stack: Back here would close the app.
    return BackToExit(
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: ScrollToTopOnReselect(
          branch: 0,
          controller: _scroll,
          child: RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () => _refresh(viewModel),
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: AppSpacing.xl.dh),
              children: <Widget>[
                ProviderHomeHeader(
                  greeting: viewModel.greeting,
                  fullName: viewModel.fullName,
                  hasUnread: hasUnread,
                  onBell: () => context.push(AppRoutes.notifications),
                  accepting: home != null && home.isVerified ? home.acceptingBookings : null,
                  onAvailability: home == null || viewModel.isSavingAvailability
                      ? null
                      : () => _availability(viewModel, home.acceptingBookings),
                ),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled block of the home, in the screen gutter.
Widget _section({
  required String title,
  required Widget child,
  String? action,
  VoidCallback? onAction,
}) =>
    Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        AppSpacing.xl.dh,
        AppSpacing.md.dw,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(title: title, actionLabel: action, onAction: onAction),
          SizedBox(height: AppSpacing.xs.dh),
          child,
        ],
      ),
    );

class _VerifiedContent extends StatelessWidget {
  const _VerifiedContent({
    required this.home,
    required this.viewModel,
    required this.onAccept,
    required this.onDecline,
    required this.onComingSoon,
  });

  final ProviderHome home;
  final ProviderHomeViewModel viewModel;
  final ValueChanged<BookingCard> onAccept;
  final ValueChanged<BookingCard> onDecline;
  final VoidCallback onComingSoon;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    final String? accepting = viewModel.accepting;

    String when(BookingCard booking) => <String>[
          if (booking.eventType case final EventType type) l10n.eventTypeLabel(type),
          shortDate(booking.eventDate, language),
        ].join(' · ');

    String requestMeta(BookingCard request) {
      final int? hours = viewModel.replyHoursLeft(request);
      return <String>[
        when(request),
        if (hours != null) l10n.providerReplyWithin(hours),
      ].join(' · ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(AppSpacing.md.dw, AppSpacing.md.dh, AppSpacing.md.dw, 0),
          child: ProviderStats(counts: home.counts),
        ),
        _section(
          title: l10n.providerRequestsTitle,
          action: home.requests.isEmpty ? null : l10n.seeAll,
          onAction: () => context.go(AppRoutes.providerRequests),
          child: home.requests.isEmpty
              ? StateCard.empty(
                  icon: AppIcons.calendar,
                  title: l10n.providerNoRequestsTitle,
                  body: home.acceptingBookings
                      ? l10n.providerNoRequestsBody(viewModel.replyDeadlineHours)
                      : l10n.providerNoRequestsPausedBody,
                )
              : Column(
                  children: <Widget>[
                    for (final BookingCard request in home.requests) ...<Widget>[
                      if (request != home.requests.first) SizedBox(height: AppSpacing.sm.dh),
                      ui.RequestCard(
                        key: ValueKey<String>(request.id),
                        clientName: request.counterpartyName,
                        meta: requestMeta(request),
                        isBusy: accepting != null,
                        isAccepting: accepting == request.id,
                        onAccept: request.can(BookingAction.accept)
                            ? () => onAccept(request)
                            : null,
                        onDecline: request.can(BookingAction.decline)
                            ? () => onDecline(request)
                            : null,
                        onTap: onComingSoon,
                      ),
                    ],
                  ],
                ),
        ),
        _section(
          title: l10n.providerUpcomingTitle,
          action: home.upcoming.isEmpty ? null : l10n.seeAll,
          onAction: () => context.go(AppRoutes.providerRequests),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final BookingCard booking in home.upcoming) ...<Widget>[
                ui.BookingCard(
                  key: ValueKey<String>(booking.id),
                  counterpartName: booking.counterpartyName,
                  meta: when(booking),
                  status: BookingStatusKind.fromApi(booking.status),
                  onTap: onComingSoon,
                ),
                SizedBox(height: AppSpacing.sm.dh),
              ],
              if (home.upcoming.isEmpty) ...<Widget>[
                Text(
                  l10n.providerNoUpcoming,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: AppSpacing.sm.dh),
              ],
              MainButton(
                label: l10n.providerAvailabilityCalendar,
                style: MainButtonStyle.secondary,
                icon: AppIcons.calendar,
                onPressed: onComingSoon,
              ),
            ],
          ),
        ),
        _section(
          title: l10n.providerServicesTitle,
          action: l10n.providerManage,
          onAction: () => context.go(AppRoutes.providerServices),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final ProviderServiceRow service in home.services) ...<Widget>[
                ui.ServiceItem(
                  key: ValueKey<String>(service.id),
                  title: service.title.of(language),
                  price: formatAmount(service.basePrice),
                  photoUrl: service.coverUrl,
                  badge: ServiceStatusBadge(switch (service.status) {
                    ProviderServiceStatus.published => ServiceStatusKind.published,
                    ProviderServiceStatus.draft => ServiceStatusKind.draft,
                    ProviderServiceStatus.hidden => ServiceStatusKind.hidden,
                  }),
                  onTap: onComingSoon,
                ),
                SizedBox(height: AppSpacing.sm.dh),
              ],
              MainButton(
                label: l10n.providerAddService,
                style: MainButtonStyle.secondary,
                onPressed: onComingSoon,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnverifiedContent extends StatelessWidget {
  const _UnverifiedContent({
    required this.home,
    required this.onUpload,
    required this.onResubmit,
  });

  final ProviderHome home;
  final VoidCallback onUpload;
  final VoidCallback onResubmit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(AppSpacing.md.dw, AppSpacing.md.dh, AppSpacing.md.dw, 0),
          child: VerificationCard(home: home, onUpload: onUpload, onResubmit: onResubmit),
        ),
        _section(
          title: l10n.providerServicesTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MainButton(
                label: l10n.providerAddService,
                style: MainButtonStyle.secondary,
                canBeTapped: false,
                onPressed: () {},
              ),
              SizedBox(height: AppSpacing.xs.dh),
              Text(
                l10n.providerServicesAfterApproval,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
