import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/bookings_repository.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_chip.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/atoms/category_icon.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/atoms/status_badge.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/meta_line.dart';
import '../../../core/widgets/molecules/price_text.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/view/client_shell.dart' show ScrollToTopOnReselect;
import '../view_model/bookings_view_model.dart';

/// B3 My bookings — the client's third tab.
class BookingsView extends StatefulWidget {
  const BookingsView({super.key});

  /// Its index in the client shell.
  static const int branch = 2;

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {
  final ScrollController _scroll = ScrollController();
  late final AppLifecycleListener _lifecycle;

  static const double _loadMoreDistance = 300;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<BookingsViewModel>().refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh(BookingsViewModel viewModel) async {
    final Failure? failure = await viewModel.refresh();
    if (failure != null && mounted) {
      showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
    }
  }

  Future<void> _open(BookingsViewModel viewModel, BookingCard booking) async {
    await context.push(AppRoutes.bookingFor(booking.id));
    // It may have moved: cancelled, rescheduled, reviewed.
    if (mounted) await viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final BookingsViewModel viewModel = context.watch<BookingsViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    String label(BookingTab tab) => switch (tab) {
          BookingTab.upcoming => l10n.bookingsTabUpcoming,
          BookingTab.pending => l10n.bookingsTabPending,
          BookingTab.past => l10n.bookingsTabPast,
          BookingTab.cancelled => l10n.bookingsTabCancelled,
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
                    l10n.bookingsTitle,
                    style: textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                SizedBox(height: AppSpacing.md.dh),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsetsDirectional.only(end: AppSpacing.md.dw),
                  child: Row(
                    children: <Widget>[
                      for (final BookingTab tab in BookingTab.values) ...<Widget>[
                        if (tab != BookingTab.values.first) SizedBox(width: AppSpacing.xs.dw),
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
              branch: BookingsView.branch,
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
                    children: <Widget>[
                      if (viewModel.isFirstLoad)
                        for (int i = 0; i < 3; i++) ...<Widget>[
                          Skeleton(height: 132.dh, radius: AppRadii.mdAll),
                          SizedBox(height: AppSpacing.md.dh),
                        ]
                      else if (viewModel.loadFailed)
                        StateCard.error(onRetry: viewModel.load)
                      else if (viewModel.isEmpty)
                        _EmptyTab(tab: viewModel.tab)
                      else ...<Widget>[
                        for (final BookingCard booking in viewModel.items) ...<Widget>[
                          BookingListCard(
                            key: ValueKey<String>(booking.id),
                            booking: booking,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.tab});

  final BookingTab tab;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final (String title, String body) = switch (tab) {
      BookingTab.upcoming => (l10n.bookingsEmptyUpcoming, l10n.bookingsEmptyUpcomingBody),
      BookingTab.pending => (l10n.bookingsEmptyPending, l10n.bookingsEmptyPendingBody),
      BookingTab.past => (l10n.bookingsEmptyPast, l10n.bookingsEmptyPastBody),
      BookingTab.cancelled => (l10n.bookingsEmptyCancelled, l10n.bookingsEmptyCancelledBody),
    };
    final bool invites = tab == BookingTab.upcoming || tab == BookingTab.pending;
    return StateCard.empty(
      icon: AppIcons.calendar,
      title: title,
      body: body,
      actionLabel: invites ? l10n.bookingsFindService : null,
      onAction: invites ? () => context.go(AppRoutes.search) : null,
    );
  }
}

/// One booking on B3: what, from whom, its reference and status; then when,
/// where, and the total.
class BookingListCard extends StatelessWidget {
  const BookingListCard({required this.booking, required this.onTap, super.key});

  final BookingCard booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final String times = timeRange(booking.startTime, booking.endTime, nextDay: context.l10n.bookingNextDayMark);
    final int? guests = booking.guests;
    final String? where = booking.wilaya?.nameFor(language);

    return Semantics(
      button: true,
      child: Material(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.mdAll,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.dh),
            decoration: BoxDecoration(
              borderRadius: AppRadii.mdAll,
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: AppElevation.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 44.dw,
                        height: 44.dw,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.bgBrandSubtle,
                          borderRadius: AppRadii.smAll,
                        ),
                        child: AppIcon(
                          booking.category == null
                              ? AppIcons.layers
                              : categoryIcon(booking.category!.icon),
                          color: AppColors.iconBrand,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm.dw),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              booking.title.of(language),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
                            ),
                            SizedBox(height: AppSpacing.xs2.dh / 2),
                            Text(
                              booking.providerName,
                              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              booking.reference,
                              textDirection: TextDirection.ltr,
                              style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs.dw),
                      StatusBadge(BookingStatusKind.fromApi(booking.status)),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm.dh),
                const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
                SizedBox(height: AppSpacing.sm.dh),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            MetaLine(
                              style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                              parts: <MetaPart>[
                                MetaPart(shortDate(booking.eventDate, language)),
                                MetaPart(times, isLtr: true),
                              ],
                            ),
                            if (where != null || guests != null)
                              MetaLine(
                                parts: <MetaPart>[
                                  if (where != null) MetaPart(where),
                                  if (guests != null) MetaPart(l10n.bookingGuestsCount(guests)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      PriceText(
                        amount: booking.total,
                        amountStyle: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
