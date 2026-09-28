import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/bookings/models/booking_card.dart';
import '../../../core/bookings/models/booking_detail.dart';
import '../../../core/catalog/models/pack.dart' show EventType;
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/formatting/chat_time_format.dart' show ltrIsolate;
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/localization/catalog_labels.dart';
import '../../../core/provider/provider_repository.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_avatar.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/category_icon.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/atoms/status_badge.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/organisms/booking_cards.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/detail_states.dart';
import '../../../core/widgets/organisms/divided_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../booking_detail/view/widgets/booking_timeline.dart';
import '../view_model/provider_booking_view_model.dart';
import 'widgets/provider_booking_sheets.dart';

/// P2 Booking detail — a request to answer (P2), an accepted booking (P2a),
/// one whose event has passed (P2b), declined (P2c), cancelled by either
/// side (P2d) or completed (P2e). P4a (a date the client proposes) is a
/// banner on it; P3, the cancel and the problem report are sheets over it.
/// Every button comes from `allowedActions`, so the screen and the server
/// can never disagree.
class ProviderBookingView extends StatefulWidget {
  const ProviderBookingView({super.key});

  @override
  State<ProviderBookingView> createState() => _ProviderBookingViewState();
}

class _ProviderBookingViewState extends State<ProviderBookingView> {
  ProviderBookingViewModel get _viewModel => context.read<ProviderBookingViewModel>();

  void _toastFailure(Failure failure) {
    if (!mounted) return;
    showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
  }

  Future<void> _refresh() async {
    final Failure? failure = await _viewModel.refresh();
    if (failure != null) _toastFailure(failure);
  }

  Future<void> _message() async {
    final String? route = await _viewModel.chatRoute();
    if (route != null && mounted) context.push(route);
  }

  Future<void> _accept(ProviderBooking booking) async {
    final AppLocalizations l10n = context.l10n;
    final Failure? failure = await _viewModel.accept();
    if (!mounted) return;
    if (failure == null) {
      showAppToast(context, l10n.providerAccepted(booking.clientName));
    } else {
      _toastFailure(failure);
    }
  }

  Future<void> _decline(ProviderBooking booking) async {
    final AppLocalizations l10n = context.l10n;
    final bool declined = await showDeclineSheet(
      context,
      request: booking.card,
      onDecline: _viewModel.decline,
    );
    if (declined && mounted) {
      showAppToast(context, l10n.providerDeclined, tone: AppToastTone.info);
    }
  }

  Future<void> _cancel(ProviderBooking booking) async {
    final AppLocalizations l10n = context.l10n;
    final bool cancelled = await showProviderCancelSheet(
      context,
      booking: booking.card,
      onCancel: _viewModel.cancel,
    );
    if (cancelled && mounted) {
      showAppToast(context, l10n.cancelBookingDone, tone: AppToastTone.info);
    }
  }

  Future<void> _reschedule(ProviderBooking booking) async {
    final AppLocalizations l10n = context.l10n;
    final Object? updated = await context.push<Object?>(
      AppRoutes.providerRescheduleFor(booking.id),
      extra: booking,
    );
    if (!mounted) return;
    if (updated is! ProviderBooking) {
      // Left without sending — or the booking moved meanwhile.
      await _viewModel.refresh();
      return;
    }
    _viewModel.replace(updated);
    showAppToast(
      context,
      booking.status == 'pending'
          ? l10n.rescheduleMoved
          : l10n.providerBookingProposalSentToast(booking.clientName),
      tone: AppToastTone.info,
    );
  }

  Future<void> _checkIn(ProviderBooking booking) async {
    final Object? updated = await context.push<Object?>(
      AppRoutes.providerCheckInFor(booking.id),
      extra: booking,
    );
    if (!mounted) return;
    if (updated is ProviderBooking) {
      _viewModel.replace(updated);
    } else {
      // A problem may have been reported from P5.
      await _viewModel.refresh();
    }
  }

  Future<void> _problem(ProviderBooking booking) async {
    final bool sent = await showProviderProblemSheet(
      context,
      clientName: booking.clientName,
      onSubmit: _viewModel.reportProblem,
    );
    if (sent && mounted) {
      showAppToast(context, context.l10n.problemDone, tone: AppToastTone.info);
    }
  }

  Future<void> _answer(Future<Failure?> Function() call, String done) async {
    final Failure? failure = await call();
    if (!mounted) return;
    if (failure != null) {
      _toastFailure(failure);
    } else {
      showAppToast(context, done, tone: AppToastTone.info);
    }
  }

  /// The provider's own service (P7a) or pack (P12).
  void _openSubject(BookingCard card) {
    final String? service = card.serviceId;
    final String? pack = card.packId;
    if (service != null) {
      context.push(AppRoutes.providerEditServiceFor(service));
    } else if (pack != null) {
      context.push(AppRoutes.providerEditPackFor(pack));
    }
  }

  void _invoice() {
    // TODO(integrator): the invoice screen (B8) reads the client's route
    // and words the footnote for a client; P2e's "View invoice" waits for a
    // provider variant over ProviderRepository.invoice / invoicePdf.
    showComingSoon(context, context.l10n.comingSoon);
  }

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final ProviderBookingViewModel viewModel = context.watch<ProviderBookingViewModel>();
    final AppLocalizations l10n = context.l10n;
    final ProviderBooking? booking = viewModel.booking;

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(title: l10n.bookingDetailTitle),
            Expanded(
              child: viewModel.isGone
                  ? DetailGoneView(onBack: () => context.pop())
                  : viewModel.hasError
                      ? DetailErrorView(onRetry: viewModel.load, onBack: () => context.pop())
                      : const _Skeleton(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(
            title: viewModel.isRequest ? l10n.providerBookingTitleRequest : l10n.bookingDetailTitle,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brand,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
                children: _body(viewModel, booking),
              ),
            ),
          ),
          _ActionBar(
            booking: booking,
            viewModel: viewModel,
            onMessage: _message,
            onAccept: () => _accept(booking),
            onDecline: () => _decline(booking),
            onCancel: () => _cancel(booking),
            onReschedule: () => _reschedule(booking),
            onCheckIn: () => _checkIn(booking),
            onProblem: () => _problem(booking),
            onInvoice: _invoice,
          ),
        ],
      ),
    );
  }

  List<Widget> _body(ProviderBookingViewModel viewModel, ProviderBooking booking) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final BookingCard card = booking.card;
    final String client = booking.clientName;
    final String status = card.status;
    final Reschedule? proposal = clientProposal(booking);
    final Reschedule? mine = booking.myPendingProposal;
    final BookingDisputeSummary? dispute = booking.dispute;
    final DateTime? completedAt = booking.lastAt(TimelineEntryType.completed);
    final String times = timeRange(card.startTime, card.endTime, nextDay: l10n.bookingNextDayMark);
    final int? span = card.startTime != null && card.endTime != null
        ? spanMinutes(card.startTime!, card.endTime!)
        : null;
    final SizedBox gap = SizedBox(height: AppSpacing.md.dh);
    final EdgeInsetsDirectional rowPadding = EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.md.dw,
      vertical: AppSpacing.sm.dh,
    );

    return <Widget>[
      // Reference, when it was asked (or closed), and the status.
      Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  card.reference,
                  textDirection: TextDirection.ltr,
                  style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                ),
                Text(
                  status == 'completed' && completedAt != null
                      ? l10n.bookingCompletedOn(shortDate(completedAt.toLocal(), language))
                      : l10n.bookingRequestedOn(
                          shortDate(
                            (booking.lastAt(TimelineEntryType.created) ?? card.createdAt ?? card.eventDate)
                                .toLocal(),
                            language,
                          ),
                        ),
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(BookingStatusKind.fromApi(status)),
        ],
      ),
      gap,
      if (proposal != null) ...<Widget>[
        _ProposalBanner(
          proposal: proposal,
          client: client,
          busy: viewModel.busy,
          onAccept: () => _answer(
            () => viewModel.acceptProposal(proposal),
            l10n.proposalAccepted(shortDate(proposal.newDate, language)),
          ),
          onDecline: () => _answer(() => viewModel.rejectProposal(proposal), l10n.proposalDeclined),
        ),
        gap,
      ],
      if (mine != null) ...<Widget>[
        InlineBanner(
          tone: InlineBannerTone.info,
          title: l10n.providerBookingProposalSentTitle(shortDate(mine.newDate, language)),
          message: l10n.providerBookingProposalSentBody(shortDate(mine.oldDate, language), client),
          actionLabel: viewModel.busy == null ? l10n.providerBookingWithdraw : null,
          onAction: () => _answer(() => viewModel.withdrawProposal(mine), l10n.proposalWithdrawn),
        ),
        gap,
      ],
      if (dispute != null && dispute.isOpen) ...<Widget>[
        InlineBanner(
          tone: InlineBannerTone.info,
          title: l10n.disputeOpenTitle(dispute.reference),
          message: l10n.disputeOpenBody,
        ),
        gap,
      ],
      BookingTimeline(steps: _steps(viewModel, booking)),
      gap,
      ..._callout(booking),
      // What was booked — the provider's own service or pack.
      BookingSection(
        title: booking.isPack ? l10n.bookingPackSection : l10n.bookingServiceSection,
        child: DividedCard(
          children: <Widget>[
            InkWell(
              onTap: () => _openSubject(card),
              child: Padding(
                padding: rowPadding,
                child: Row(
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
                        card.category == null ? AppIcons.layers : categoryIcon(card.category!.icon),
                        color: AppColors.iconBrand,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm.dw),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            card.title.of(language),
                            style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
                          ),
                          Text(
                            card.category == null
                                ? l10n.providerBookingYourPack
                                : l10n.providerBookingYourService(card.category!.name.of(language)),
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const AppIcon(AppIcons.chevronRight, color: AppColors.iconDefault),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      gap,
      BookingSection(
        title: l10n.providerBookingTheEvent,
        // A request moves at once — offered here, not in the bar, which is
        // for answering it.
        trailing: status == 'pending' && booking.can(BookingAction.reschedule)
            ? MainButton(
                label: l10n.rescheduleMove,
                style: MainButtonStyle.ghost,
                onPressed: () => _reschedule(booking),
              )
            : null,
        child: DividedCard(
          children: <Widget>[
            KeyValueRow(label: l10n.bookingDate, value: fullDate(card.eventDate, language)),
            if (times.isNotEmpty)
              KeyValueRow(
                label: l10n.bookingTime,
                // The clock times keep their order inside an Arabic line;
                // the duration reads in the line's own direction.
                value: span == null ? times : '${ltrIsolate(times)} · ${_duration(l10n, span)}',
                isLtr: span == null,
              ),
            if (card.eventType case final EventType type)
              KeyValueRow(label: l10n.bookingEventType, value: l10n.eventTypeLabel(type)),
            if (booking.guests case final int guests)
              KeyValueRow(label: l10n.bookingGuests, value: '$guests', isLtr: true),
          ],
        ),
      ),
      gap,
      if (booking.wilaya != null || booking.locationText != null) ...<Widget>[
        BookingSection(
          title: l10n.bookingWhere,
          child: DividedCard(
            children: <Widget>[
              if (booking.wilaya != null)
                KeyValueRow(label: l10n.bookingWilaya, value: booking.wilaya!.nameFor(language)),
              if (booking.communeName case final String commune)
                KeyValueRow(label: l10n.bookingCommune, value: commune),
              if (booking.locationText case final String address when address.isNotEmpty)
                KeyValueRow(label: l10n.bookingAddressLabel, value: address, stacked: true),
            ],
          ),
        ),
        gap,
      ],
      if (booking.clientNote case final String note when note.isNotEmpty) ...<Widget>[
        BookingSection(
          title: l10n.providerBookingClientNote,
          child: DividedCard(
            children: <Widget>[
              Padding(
                padding: rowPadding,
                child: Text(note, style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
        gap,
      ],
      BookingSection(
        title: l10n.bookingPrice,
        child: PriceLinesCard(
          lines: booking.lines,
          totalLabel: l10n.providerBookingTotalOnSite,
          total: card.total,
          highlightTotal: false,
        ),
      ),
      SizedBox(height: AppSpacing.xs.dh),
      Text(
        l10n.providerBookingCashNote,
        style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
      ),
      gap,
      _ClientCard(
        booking: booking,
        eventPassed: viewModel.eventPassed,
        onCall: (String phone) => _launch(Uri(scheme: 'tel', path: phone.replaceAll(' ', ''))),
        onMail: (String email) => _launch(Uri(scheme: 'mailto', path: email)),
      ),
      if (booking.cancellationPolicy case final String policy when policy.isNotEmpty) ...<Widget>[
        gap,
        BookingSection(
          title: l10n.bookingCancellationPolicy,
          child: DividedCard(
            children: <Widget>[
              Padding(
                padding: rowPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.providerBookingPolicySetByYou,
                      style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: AppSpacing.xs2.dh),
                    Text(policy, style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      // After the event the bar carries it; on a closed booking it waits
      // here, out of the way.
      if (status == 'completed' && booking.can(BookingAction.dispute)) ...<Widget>[
        gap,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MainButton(
            label: l10n.bookingReportProblem,
            style: MainButtonStyle.ghost,
            tone: MainButtonTone.danger,
            onPressed: () => _problem(booking),
          ),
        ),
      ],
    ];
  }

  /// P2c's and P2d's red callout, P2e's purple one.
  List<Widget> _callout(ProviderBooking booking) {
    final AppLocalizations l10n = context.l10n;
    final String client = booking.clientName;
    String withReason(String? reason, String body) => <String>[
          if (reason != null && reason.isNotEmpty) l10n.reasonGiven(reason),
          body,
        ].join(' ');

    final InlineBanner? banner = switch (booking.status) {
      'declined' => InlineBanner(
          title: l10n.providerBookingDeclinedTitle,
          message: withReason(booking.declineReason, l10n.providerBookingDeclinedBody(client)),
        ),
      'cancelled' when !booking.wasAccepted => InlineBanner(
          title: l10n.providerBookingRequestWithdrawnTitle(client),
          message: withReason(booking.cancelReason, l10n.providerBookingRequestWithdrawnBody),
        ),
      'cancelled' => InlineBanner(
          title: switch (booking.cancelledBy) {
            CancelledBy.provider => l10n.cancelledByYouTitle,
            CancelledBy.admin => l10n.providerBookingCancelledByEventorTitle,
            _ => l10n.providerBookingCancelledByClientTitle(client),
          },
          message: withReason(
            booking.cancelReason,
            booking.cancelledBy == CancelledBy.provider
                ? l10n.providerBookingCancelledByYouBody(client)
                : l10n.providerBookingCancelledByClientBody,
          ),
        ),
      'completed' => InlineBanner(
          tone: InlineBannerTone.info,
          title: l10n.providerBookingReviewTitle(client),
          message: l10n.providerBookingReviewBody,
        ),
      _ => null,
    };
    if (banner == null) return const <Widget>[];
    return <Widget>[banner, SizedBox(height: AppSpacing.md.dh)];
  }

  /// The timeline for the state, the dates filled in from what happened.
  /// Steps already behind are done — P2a/P2b as drawn had them grey.
  List<TimelineStep> _steps(ProviderBookingViewModel viewModel, ProviderBooking booking) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    final BookingCard card = booking.card;
    final String client = booking.clientName;
    String when(DateTime? at) =>
        at == null ? '' : '${shortDate(at.toLocal(), language)} · ${clockTime(at)}';
    String joined(List<String> parts) => parts.where((String s) => s.isNotEmpty).join(' · ');
    final DateTime? requested = booking.lastAt(TimelineEntryType.created) ?? card.createdAt;
    final DateTime? accepted = booking.lastAt(TimelineEntryType.accepted);
    final String eventDay = joined(<String>[
      shortDate(card.eventDate, language),
      ?card.startTime,
    ]);
    final String eventRange = joined(<String>[
      shortDate(card.eventDate, language),
      timeRange(card.startTime, card.endTime, nextDay: l10n.bookingNextDayMark),
    ]);

    TimelineStep requestedStep() => TimelineStep(
          title: l10n.providerBookingStepRequestedBy(client),
          subtitle: when(requested),
          state: TimelineStepState.done,
        );
    TimelineStep acceptedStep() => TimelineStep(
          title: l10n.providerBookingStepYouAccepted,
          subtitle: when(accepted),
          state: TimelineStepState.done,
        );
    TimelineStep eventStep(TimelineStepState state, {bool range = false}) => TimelineStep(
          title: l10n.stepEventDay,
          subtitle: range ? eventRange : eventDay,
          state: state,
        );
    TimelineStep completedStep(String subtitle) => TimelineStep(
          title: l10n.stepCompleted,
          subtitle: subtitle,
          state: TimelineStepState.todo,
        );

    switch (card.status) {
      case 'pending':
        final int? hours = viewModel.replyHoursLeft;
        return <TimelineStep>[
          requestedStep(),
          TimelineStep(
            title: l10n.providerBookingStepYourReply,
            subtitle: hours == null ? '' : l10n.providerRequestsReplyWithin(hours),
            state: TimelineStepState.current,
          ),
          eventStep(TimelineStepState.todo),
          completedStep(l10n.stepConfirmAfter),
        ];
      case 'declined':
        return <TimelineStep>[
          requestedStep(),
          TimelineStep(
            title: l10n.providerBookingStepYouDeclined,
            subtitle: when(booking.lastAt(TimelineEntryType.declined)),
            state: TimelineStepState.bad,
          ),
          eventStep(TimelineStepState.todo),
          completedStep(l10n.stepNotApplicable),
        ];
      case 'cancelled':
        return <TimelineStep>[
          requestedStep(),
          if (accepted != null) acceptedStep(),
          TimelineStep(
            title: switch (booking.cancelledBy) {
              CancelledBy.provider => l10n.stepCancelledByYou,
              CancelledBy.admin => l10n.providerBookingStepCancelledByEventor,
              _ => l10n.providerBookingStepCancelledBy(client),
            },
            subtitle: when(booking.lastAt(TimelineEntryType.cancelled)),
            state: TimelineStepState.bad,
          ),
          completedStep(l10n.stepNotApplicable),
        ];
      case 'completed':
        final DateTime? completed = booking.lastAt(TimelineEntryType.completed);
        return <TimelineStep>[
          requestedStep(),
          acceptedStep(),
          eventStep(TimelineStepState.done, range: true),
          TimelineStep(
            title: l10n.stepCompleted,
            subtitle: joined(<String>[
              if (completed != null) shortDate(completed.toLocal(), language),
              if (booking.checkedIn && booking.otherCheckedIn) l10n.providerBookingStepBothConfirmed,
            ]),
            state: TimelineStepState.current,
          ),
        ];
      default:
        final Reschedule? proposal = clientProposal(booking);
        final Reschedule? mine = booking.myPendingProposal;
        if (viewModel.eventPassed) {
          return <TimelineStep>[
            requestedStep(),
            acceptedStep(),
            eventStep(TimelineStepState.done, range: true),
            TimelineStep(
              title: l10n.providerBookingStepConfirmEvent,
              subtitle: booking.checkedIn
                  ? l10n.providerBookingStepYouConfirmed(client)
                  : booking.otherCheckedIn
                      ? l10n.providerBookingStepClientConfirmed(client)
                      : l10n.providerBookingStepWaitingBoth,
              state: TimelineStepState.current,
            ),
          ];
        }
        if (proposal != null || mine != null) {
          return <TimelineStep>[
            requestedStep(),
            acceptedStep(),
            if (proposal != null)
              TimelineStep(
                title: l10n.providerBookingStepClientProposed(client),
                subtitle: joined(<String>[when(proposal.createdAt), l10n.stepWaitingForYou]),
                state: TimelineStepState.current,
              )
            else
              TimelineStep(
                title: l10n.providerBookingStepYouProposed,
                subtitle: joined(<String>[when(mine!.createdAt), l10n.providerBookingStepWaitingFor(client)]),
                state: TimelineStepState.current,
              ),
            eventStep(TimelineStepState.todo),
          ];
        }
        return <TimelineStep>[
          requestedStep(),
          acceptedStep(),
          eventStep(TimelineStepState.current),
          completedStep(l10n.stepConfirmAfter),
        ];
    }
  }

  /// "10 h", "5 h 30 min" — how long the event runs.
  static String _duration(AppLocalizations l10n, int minutes) {
    final int hours = minutes ~/ 60;
    if (hours == 0) return l10n.bookingDurationHalfHour;
    return minutes % 60 == 0 ? l10n.bookingDurationHours(hours) : l10n.bookingDurationHoursHalf(hours);
  }
}

/// P2's "Client" card: who, and how to reach them once that is shared.
class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.booking,
    required this.eventPassed,
    required this.onCall,
    required this.onMail,
  });

  final ProviderBooking booking;
  final bool eventPassed;
  final ValueChanged<String> onCall;
  final ValueChanged<String> onMail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String client = booking.clientName;
    final String status = booking.status;
    final String? phone = booking.client.phone;
    final String? email = booking.client.email;
    final EdgeInsetsDirectional padding = EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.md.dw,
      vertical: AppSpacing.sm.dh,
    );

    final String? hidden = switch (status) {
      'pending' => l10n.providerBookingContactHidden,
      'declined' => l10n.providerBookingContactNotShared,
      'cancelled' when !booking.wasAccepted => l10n.providerBookingContactNotShared,
      _ => phone == null && email == null ? l10n.providerBookingContactNotShared : null,
    };
    final String helper = switch (status) {
      'pending' => l10n.providerBookingContactPending(client),
      'declined' => l10n.providerBookingContactDeclined,
      'cancelled' when !booking.wasAccepted => l10n.providerBookingContactWithdrawn,
      'accepted' when eventPassed => l10n.providerBookingContactUntilClosed(client),
      'accepted' => l10n.providerBookingContactAccepted(client),
      _ => l10n.providerBookingContactHistory,
    };

    Widget link(String value, String label, VoidCallback onTap) => Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.dh),
              child: Text(
                value,
                textDirection: TextDirection.ltr,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textBrand),
              ),
            ),
          ),
        );

    return BookingSection(
      title: l10n.providerBookingClientSection,
      child: DividedCard(
        children: <Widget>[
          Padding(
            padding: padding,
            child: Row(
              children: <Widget>[
                AppAvatar(name: client, photoUrl: booking.client.avatarUrl),
                SizedBox(width: AppSpacing.sm.dw),
                Expanded(
                  child: Text(client, style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary)),
                ),
                SizedBox(width: AppSpacing.xs.dw),
                if (hidden != null)
                  Text(hidden, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary))
                else if (phone != null)
                  link(phone, l10n.bookingCallLabel(client), () => onCall(phone)),
              ],
            ),
          ),
          if (hidden == null && email != null)
            Padding(
              padding: padding,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: link(email, email, () => onMail(email)),
              ),
            ),
          Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppIcon(
                  hidden == null ? AppIcons.check : AppIcons.eyeOff,
                  size: AppSizes.iconMd,
                  color: AppColors.iconDefault,
                ),
                SizedBox(width: AppSpacing.xs.dw),
                Expanded(
                  child: Text(
                    helper,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// P4a: the client's new date, the old one struck through, their reason,
/// and Decline / Accept.
class _ProposalBanner extends StatelessWidget {
  const _ProposalBanner({
    required this.proposal,
    required this.client,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final Reschedule proposal;
  final String client;
  final ProviderBookingBusy? busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    String at(DateTime date, String? time) => <String>[
          shortDate(date, language),
          ?time,
        ].join(' · ');

    Widget column(String value, String caption, {required bool old}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: (old ? textTheme.bodyMedium : textTheme.labelLarge)?.copyWith(
                color: old ? AppColors.textSecondary : AppColors.textPrimary,
                decoration: old ? TextDecoration.lineThrough : null,
              ),
            ),
            Text(caption, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
          ],
        );

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.sm.dh,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgBrandSubtle,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderBrandSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.providerBookingProposalTitle(client),
            style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.xs.dh),
          Row(
            children: <Widget>[
              column(at(proposal.oldDate, null), l10n.proposalCurrent, old: true),
              SizedBox(width: AppSpacing.sm.dw),
              // Directional: it mirrors in Arabic, still pointing at the new date.
              const AppIcon(AppIcons.chevronRight, color: AppColors.iconDefault),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(child: column(at(proposal.newDate, proposal.newStartTime), l10n.proposalProposed, old: false)),
            ],
          ),
          if (proposal.reason.isNotEmpty) ...<Widget>[
            SizedBox(height: AppSpacing.xs.dh),
            Text(
              '“${proposal.reason}”',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
            ),
          ],
          SizedBox(height: AppSpacing.xs.dh),
          Text(
            l10n.providerBookingProposalHelper(shortDate(proposal.oldDate, language), client),
            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.sm.dh),
          Row(
            children: <Widget>[
              Expanded(
                child: MainButton(
                  label: l10n.requestDecline,
                  style: MainButtonStyle.secondary,
                  isLoading: busy == ProviderBookingBusy.rejectProposal,
                  canBeTapped: busy == null,
                  onPressed: onDecline,
                ),
              ),
              SizedBox(width: AppSpacing.xs.dw),
              Expanded(
                child: MainButton(
                  label: l10n.proposalAccept(shortDate(proposal.newDate, language)),
                  isLoading: busy == ProviderBookingBusy.acceptProposal,
                  canBeTapped: busy == null,
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The bar under P2, per state — built only from `allowedActions`.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.booking,
    required this.viewModel,
    required this.onMessage,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
    required this.onReschedule,
    required this.onCheckIn,
    required this.onProblem,
    required this.onInvoice,
  });

  final ProviderBooking booking;
  final ProviderBookingViewModel viewModel;
  final VoidCallback onMessage;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onCheckIn;
  final VoidCallback onProblem;
  final VoidCallback onInvoice;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool idle = viewModel.busy == null;

    /// Two buttons side by side, the one that matters most at the end.
    Widget pair(MainButton? start, MainButton? end) => Row(
          children: <Widget>[
            if (start != null) Expanded(child: start),
            if (start != null && end != null) SizedBox(width: AppSpacing.xs.dw),
            if (end != null) Expanded(child: end),
          ],
        );

    final List<Widget> rows = <Widget>[
      if (booking.can(BookingAction.message))
        MainButton(
          label: l10n.providerBookingMessageClient(booking.clientName),
          style: MainButtonStyle.ghost,
          isLoading: viewModel.isOpeningChat,
          onPressed: onMessage,
        ),
    ];

    final bool accept = booking.can(BookingAction.accept);
    final bool decline = booking.can(BookingAction.decline);
    final bool reschedule = booking.can(BookingAction.reschedule);
    final bool cancel = booking.can(BookingAction.cancel);
    final bool checkIn = booking.can(BookingAction.checkIn);
    final bool dispute = booking.can(BookingAction.dispute);

    switch (booking.status) {
      case 'pending':
        if (accept || decline) {
          rows.add(pair(
            decline
                ? MainButton(
                    label: l10n.requestDecline,
                    style: MainButtonStyle.secondary,
                    canBeTapped: idle,
                    onPressed: onDecline,
                  )
                : null,
            accept
                ? MainButton(
                    label: l10n.providerBookingAcceptRequest,
                    isLoading: viewModel.busy == ProviderBookingBusy.accept,
                    canBeTapped: idle,
                    onPressed: onAccept,
                  )
                : null,
          ));
        }
      case 'accepted' when viewModel.eventPassed:
        if (dispute || checkIn) {
          rows.add(pair(
            dispute
                ? MainButton(
                    label: l10n.bookingReportProblem,
                    style: MainButtonStyle.secondary,
                    tone: MainButtonTone.danger,
                    onPressed: onProblem,
                  )
                : null,
            checkIn ? MainButton(label: l10n.providerBookingConfirmEvent, onPressed: onCheckIn) : null,
          ));
        }
      case 'accepted':
        if (reschedule || cancel) {
          rows.add(pair(
            reschedule
                ? MainButton(
                    label: l10n.bookingProposeDate,
                    style: MainButtonStyle.secondary,
                    canBeTapped: idle,
                    onPressed: onReschedule,
                  )
                : null,
            cancel
                ? MainButton(
                    label: l10n.bookingCancelBooking,
                    style: MainButtonStyle.secondary,
                    tone: MainButtonTone.danger,
                    canBeTapped: idle,
                    onPressed: onCancel,
                  )
                : null,
          ));
        }
      case 'completed':
        if (booking.can(BookingAction.invoice)) {
          rows.add(MainButton(
            label: l10n.bookingViewInvoice,
            style: MainButtonStyle.secondary,
            onPressed: onInvoice,
          ));
        }
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return BottomActionBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: AppSpacing.xs.dh),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// P2's shape while it loads: the reference, the timeline, the first cards.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
        children: <Widget>[
          Skeleton(height: 20.dh, width: 140.dw),
          SizedBox(height: AppSpacing.xs.dh),
          Skeleton(height: 14.dh, width: 180.dw),
          SizedBox(height: AppSpacing.md.dh),
          Skeleton(height: 220.dh, radius: AppRadii.mdAll),
          SizedBox(height: AppSpacing.md.dh),
          Skeleton(height: 72.dh, radius: AppRadii.mdAll),
          SizedBox(height: AppSpacing.md.dh),
          Skeleton(height: 180.dh, radius: AppRadii.mdAll),
        ],
      );
}
