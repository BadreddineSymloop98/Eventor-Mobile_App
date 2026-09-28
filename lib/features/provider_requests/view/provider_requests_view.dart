import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/models/booking_card.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/provider/provider_repository.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_chip.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/atoms/status_badge.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../provider_booking/view/widgets/provider_booking_sheets.dart';
import '../../shell/view/client_shell.dart' show ScrollToTopOnReselect, TabReselect;
import '../view_model/provider_requests_view_model.dart';
import 'widgets/provider_booking_list_card.dart';

/// P1 Requests — the provider's second tab — with its Upcoming and Past
/// lists, P1a when a list is empty and P1b while the profile is reviewed.
///
/// Requests are answered from the card (Accept at once, Decline through
/// P3); a card opens P2. The list reloads when the app comes back, when the
/// tab is tapped again, and on the way back from P2.
class ProviderRequestsView extends StatefulWidget {
  const ProviderRequestsView({super.key});

  /// Its index in the provider shell.
  static const int branch = 1;

  @override
  State<ProviderRequestsView> createState() => _ProviderRequestsViewState();
}

class _ProviderRequestsViewState extends State<ProviderRequestsView> {
  final ScrollController _scroll = ScrollController();
  late final AppLifecycleListener _lifecycle;
  TabReselect? _reselect;

  static const double _loadMoreDistance = 300;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<ProviderRequestsViewModel>().refresh(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tapping the tab again scrolls to the top (ScrollToTopOnReselect) and
    // fetches what came in meanwhile.
    final TabReselect? reselect = Provider.of<TabReselect?>(context, listen: false);
    if (reselect == _reselect) return;
    _reselect?.removeListener(_onReselect);
    _reselect = reselect?..addListener(_onReselect);
  }

  void _onReselect() {
    if (_reselect?.branch != ProviderRequestsView.branch) return;
    context.read<ProviderRequestsViewModel>().refresh();
  }

  @override
  void dispose() {
    _reselect?.removeListener(_onReselect);
    _lifecycle.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toastFailure(Failure failure) {
    if (!mounted) return;
    showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
  }

  Future<void> _refresh(ProviderRequestsViewModel viewModel) async {
    final Failure? failure = await viewModel.refresh();
    if (failure != null) _toastFailure(failure);
  }

  Future<void> _open(ProviderRequestsViewModel viewModel, BookingCard booking) async {
    await context.push(AppRoutes.providerBookingFor(booking.id));
    // It may have moved: accepted, declined, rescheduled, cancelled.
    if (mounted) await viewModel.refresh();
  }

  Future<void> _accept(ProviderRequestsViewModel viewModel, BookingCard request) async {
    final AppLocalizations l10n = context.l10n;
    final Failure? failure = await viewModel.accept(request);
    if (!mounted) return;
    if (failure == null) {
      showAppToast(context, l10n.providerRequestsAccepted(request.counterpartyName));
    } else {
      _toastFailure(failure);
    }
  }

  Future<void> _decline(ProviderRequestsViewModel viewModel, BookingCard request) async {
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

  /// 08e while documents are pending, 08d once one was refused — then back
  /// to a tab that reflects what was sent.
  Future<void> _documents(ProviderRequestsViewModel viewModel) async {
    await context.push(
      viewModel.isRejected ? AppRoutes.resubmitDocuments : AppRoutes.documents,
    );
    if (mounted) await viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final ProviderRequestsViewModel viewModel = context.watch<ProviderRequestsViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    String label(ProviderBookingTab tab) => switch (tab) {
          ProviderBookingTab.requests => l10n.providerRequestsChipRequests,
          ProviderBookingTab.upcoming => l10n.providerRequestsChipUpcoming,
          ProviderBookingTab.past => l10n.providerRequestsChipPast,
        };

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
            ),
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md.dw,
              MediaQuery.paddingOf(context).top + AppSpacing.xl.dh,
              0,
              AppSpacing.sm.dh,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    l10n.providerRequestsTabTitle,
                    style: textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                SizedBox(height: AppSpacing.md.dh),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsetsDirectional.only(end: AppSpacing.md.dw),
                  child: Row(
                    children: <Widget>[
                      for (final ProviderBookingTab tab in ProviderBookingTab.values) ...<Widget>[
                        if (tab != ProviderBookingTab.values.first) SizedBox(width: AppSpacing.xs.dw),
                        AppChip(
                          label: label(tab),
                          isSelected: tab == viewModel.tab,
                          onTap: () => viewModel.setTab(tab),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ScrollToTopOnReselect(
              branch: ProviderRequestsView.branch,
              controller: _scroll,
              child: RefreshIndicator(
                color: AppColors.brand,
                onRefresh: () => _refresh(viewModel),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification.metrics.extentAfter < _loadMoreDistance.dh) {
                      viewModel.loadMore();
                    }
                    return false;
                  },
                  child: ListView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.screenPaddingAll,
                    children: _content(viewModel),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(ProviderRequestsViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (viewModel.isFirstLoad) {
      return <Widget>[
        for (int i = 0; i < 3; i++) ...<Widget>[
          Skeleton(height: 196.dh, radius: AppRadii.mdAll),
          SizedBox(height: AppSpacing.md.dh),
        ],
      ];
    }
    if (viewModel.loadFailed) {
      return <Widget>[StateCard.error(onRetry: viewModel.load)];
    }
    if (viewModel.isUnderReview) {
      // P1b: nothing can come in yet — say why, and where the documents
      // stand.
      return <Widget>[
        _ReviewCard(
          rejected: viewModel.isRejected,
          onDocuments: () => _documents(viewModel),
        ),
        SizedBox(height: 40.dh),
        Text(
          _emptyTitle(l10n, viewModel.tab),
          textAlign: TextAlign.center,
          style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
        ),
      ];
    }

    final String? accepting = viewModel.accepting;
    return <Widget>[
      if (viewModel.isBlocked) ...<Widget>[
        StateCard.empty(
          icon: AppIcons.alertTriangle,
          title: l10n.providerBlockedTitle,
          body: l10n.providerBlockedBody,
        ),
        SizedBox(height: AppSpacing.md.dh),
      ],
      if (viewModel.isEmpty)
        _EmptyTab(tab: viewModel.tab, replyDeadlineHours: viewModel.replyDeadlineHours)
      else ...<Widget>[
        for (final BookingCard booking in viewModel.items) ...<Widget>[
          ProviderBookingListCard(
            key: ValueKey<String>(booking.id),
            booking: booking,
            replyHours: booking.status == 'pending' ? viewModel.replyHoursLeft(booking) : null,
            isBusy: accepting != null,
            isAccepting: accepting == booking.id,
            onAccept: booking.can(BookingAction.accept) ? () => _accept(viewModel, booking) : null,
            onDecline: booking.can(BookingAction.decline) ? () => _decline(viewModel, booking) : null,
            onTap: () => _open(viewModel, booking),
          ),
          SizedBox(height: AppSpacing.md.dh),
        ],
        if (viewModel.isLoadingMore)
          const Center(child: AppSpinner())
        else if (viewModel.loadMoreFailed)
          Center(
            child: MainButton(
              label: l10n.stateRetry,
              style: MainButtonStyle.ghost,
              onPressed: viewModel.loadMore,
            ),
          ),
      ],
    ];
  }
}

String _emptyTitle(AppLocalizations l10n, ProviderBookingTab tab) => switch (tab) {
      ProviderBookingTab.requests => l10n.providerRequestsEmptyTitle,
      ProviderBookingTab.upcoming => l10n.providerRequestsEmptyUpcomingTitle,
      ProviderBookingTab.past => l10n.providerRequestsEmptyPastTitle,
    };

/// P1a, and its Upcoming / Past counterparts in the same voice.
class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.tab, required this.replyDeadlineHours});

  final ProviderBookingTab tab;
  final int replyDeadlineHours;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return StateCard.empty(
      icon: AppIcons.calendar,
      title: _emptyTitle(l10n, tab),
      body: switch (tab) {
        ProviderBookingTab.requests => l10n.providerRequestsEmptyBody(replyDeadlineHours),
        ProviderBookingTab.upcoming => l10n.providerRequestsEmptyUpcomingBody,
        ProviderBookingTab.past => l10n.providerRequestsEmptyPastBody,
      },
    );
  }
}

/// P1b's "Profile under review" card: why no request can come in, and the
/// way to the documents.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.rejected, required this.onDocuments});

  final bool rejected;
  final VoidCallback onDocuments;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  rejected ? l10n.providerRejectedTitle : l10n.providerReviewTitle,
                  style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                ),
              ),
              SizedBox(width: AppSpacing.xs.dw),
              StatusBadge(rejected ? BookingStatusKind.declined : BookingStatusKind.pending),
            ],
          ),
          SizedBox(height: AppSpacing.sm.dh),
          Text(
            rejected ? l10n.providerRequestsRejectedBody : l10n.providerRequestsReviewBody,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.dh),
            child: const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
          ),
          MainButton(
            label: l10n.providerRequestsSeeDocuments,
            style: MainButtonStyle.secondary,
            onPressed: onDocuments,
          ),
        ],
      ),
    );
  }
}
