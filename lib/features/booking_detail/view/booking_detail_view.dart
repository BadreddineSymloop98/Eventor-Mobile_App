import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/bookings/bookings_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/service_query.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/localization/catalog_labels.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_avatar.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/atoms/category_icon.dart';
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
import '../view_model/booking_detail_view_model.dart';
import 'widgets/booking_sheets.dart';
import 'widgets/booking_timeline.dart';

/// B4 Booking detail — Accepted, and its variants: B4a Pending, B4b
/// Declined, B4c Cancelled, B4d Completed. B6a (a date the provider
/// proposes) is a banner on it; B5, the review and the problem report are
/// sheets over it. What can be done comes from `allowedActions`, so the
/// buttons and the server can never disagree.
class BookingDetailView extends StatefulWidget {
  const BookingDetailView({super.key});

  @override
  State<BookingDetailView> createState() => _BookingDetailViewState();
}

class _BookingDetailViewState extends State<BookingDetailView> {
  BookingDetailViewModel get _viewModel => context.read<BookingDetailViewModel>();

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

  Future<void> _cancel(BookingDetail booking) async {
    final AppLocalizations l10n = context.l10n;
    final bool isRequest = booking.status == 'pending';
    final bool cancelled = await showCancelBookingSheet(
      context,
      booking: booking,
      daysToEvent: _viewModel.daysToEvent,
      maxReason: BookingDetailViewModel.maxCancelReason,
      onCancel: _viewModel.cancel,
    );
    if (cancelled && mounted) {
      showAppToast(
        context,
        isRequest ? l10n.cancelRequestDone : l10n.cancelBookingDone,
        tone: AppToastTone.info,
      );
    }
  }

  Future<void> _reschedule(BookingDetail booking) async {
    final AppLocalizations l10n = context.l10n;
    final BookingDetail? updated = await context.push<BookingDetail>(
      AppRoutes.rescheduleFor(booking.id),
      extra: booking,
    );
    if (updated == null || !mounted) return;
    _viewModel.replace(updated);
    showAppToast(
      context,
      booking.status == 'pending' ? l10n.rescheduleMoved : l10n.rescheduleSent,
      tone: AppToastTone.info,
    );
  }

  Future<void> _checkIn(BookingDetail booking) async {
    final BookingDetail? updated = await context.push<BookingDetail>(
      AppRoutes.checkInFor(booking.id),
      extra: booking,
    );
    if (!mounted) return;
    if (updated != null) {
      _viewModel.replace(updated);
    } else {
      // A problem may have been reported from B7.
      await _viewModel.refresh();
    }
  }

  Future<void> _review(BookingDetail booking) async {
    final bool sent = await showReviewSheet(
      context,
      providerName: booking.card.providerName,
      onSubmit: _viewModel.review,
    );
    if (sent && mounted) {
      showAppToast(context, context.l10n.reviewDone, tone: AppToastTone.info);
    }
  }

  Future<void> _problem(BookingDetail booking) async {
    final bool sent = await showProblemSheet(
      context,
      providerName: booking.card.providerName,
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

  void _openSubject(BookingCard card) {
    final String? service = card.serviceId;
    final String? pack = card.packId;
    if (service != null) context.push(AppRoutes.serviceFor(service));
    if (pack != null) context.push(AppRoutes.packFor(pack));
  }

  void _findSimilar(BookingDetail booking) {
    final String? category = booking.card.category?.id;
    if (category != null) {
      context.go(AppRoutes.resultsFor(ServiceQuery(categoryIds: <String>{category})));
    } else {
      context.go(AppRoutes.packsFor(eventType: booking.eventType));
    }
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));
  }

  @override
  Widget build(BuildContext context) {
    final BookingDetailViewModel viewModel = context.watch<BookingDetailViewModel>();
    final AppLocalizations l10n = context.l10n;
    final BookingDetail? booking = viewModel.detail;

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
                      : const Center(child: AppSpinner()),
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
          BrandTopBar(title: l10n.bookingDetailTitle),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brand,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
                children: _body(context, viewModel, booking),
              ),
            ),
          ),
          _ActionBar(
            booking: booking,
            viewModel: viewModel,
            onMessage: _message,
            onCancel: () => _cancel(booking),
            onReschedule: () => _reschedule(booking),
            onCheckIn: () => _checkIn(booking),
            onReview: () => _review(booking),
            onInvoice: () => context.push(AppRoutes.invoiceFor(booking.id)),
            onFindSimilar: () => _findSimilar(booking),
            onBookAgain: () => _openSubject(booking.card),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    BookingDetailViewModel viewModel,
    BookingDetail booking,
  ) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final BookingCard card = booking.card;
    final String provider = card.providerName;
    final String status = card.status;
    final Reschedule? proposal = booking.proposalForMe;
    final Reschedule? mine = booking.myPendingProposal;
    final BookingDisputeSummary? dispute = booking.dispute;
    final DateTime? completedAt = _at(booking, TimelineEntryType.completed);
    final String times = timeRange(card.startTime, card.endTime, nextDay: l10n.bookingNextDayMark);
    final bool contactOpen = status == 'accepted' || status == 'completed';
    final String? phone = booking.providerPhone;
    final _Gap gap = _Gap(AppSpacing.md.dh);

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
                          shortDate((_at(booking, TimelineEntryType.created) ?? card.createdAt ?? card.eventDate).toLocal(), language),
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
          provider: provider,
          answering: viewModel.answering,
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
          title: l10n.proposalMineTitle(shortDate(mine.newDate, language)),
          message: l10n.proposalMineBody(provider),
          actionLabel: viewModel.answering == 'withdraw' ? null : l10n.proposalWithdraw,
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
      BookingTimeline(steps: _steps(context, viewModel, booking)),
      gap,
      if (status == 'declined') ...<Widget>[
        InlineBanner(
          title: l10n.declinedTitle(provider),
          message: <String>[
            if (booking.declineReason case final String reason when reason.isNotEmpty)
              l10n.reasonGiven(reason),
            l10n.declinedBody,
          ].join(' '),
        ),
        gap,
      ],
      if (status == 'cancelled') ...<Widget>[
        InlineBanner(
          title: booking.cancelledByClient ? l10n.cancelledByYouTitle : l10n.cancelledByOtherTitle(provider),
          message: <String>[
            if (booking.cancelReason case final String reason when reason.isNotEmpty)
              l10n.reasonGiven(reason),
            booking.cancelledByClient ? l10n.cancelledByYouBody(provider) : l10n.cancelledByOtherBody,
          ].join(' '),
        ),
        gap,
      ],
      if (booking.can(BookingAction.checkIn)) ...<Widget>[
        InlineBanner(
          tone: InlineBannerTone.info,
          title: l10n.checkInCalloutTitle,
          message: l10n.checkInCalloutBody(provider),
          actionLabel: l10n.checkInCalloutAction,
          onAction: () => _checkIn(booking),
        ),
        gap,
      ],
      if (booking.can(BookingAction.review)) ...<Widget>[
        InlineBanner(
          tone: InlineBannerTone.info,
          title: l10n.reviewCalloutTitle,
          message: l10n.reviewCalloutBody(provider),
        ),
        gap,
      ],
      // What was booked.
      BookingSection(
        title: booking.isPack ? l10n.bookingPackSection : l10n.bookingServiceSection,
        child: DividedCard(
          children: <Widget>[
            InkWell(
              onTap: () => _openSubject(card),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md.dw,
                  vertical: AppSpacing.sm.dh,
                ),
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
                            <String>[
                              provider,
                              ?card.category?.name.of(language),
                            ].join(' · '),
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
        title: l10n.bookingYourEvent,
        child: DividedCard(
          children: <Widget>[
            KeyValueRow(label: l10n.bookingDate, value: fullDate(card.eventDate, language)),
            if (times.isNotEmpty) KeyValueRow(label: l10n.bookingTime, value: times, isLtr: true),
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
          title: l10n.bookingYourNote,
          child: DividedCard(
            children: <Widget>[
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md.dw,
                  vertical: AppSpacing.sm.dh,
                ),
                child: Text(note, style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
        gap,
      ],
      BookingSection(
        title: l10n.bookingPrice,
        trailing: booking.can(BookingAction.invoice)
            ? MainButton(
                label: l10n.bookingViewInvoice,
                style: MainButtonStyle.ghost,
                onPressed: () => context.push(AppRoutes.invoiceFor(booking.id)),
              )
            : null,
        child: PriceLinesCard(
          lines: booking.lines,
          totalLabel: l10n.bookingTotalOnSite,
          total: card.total,
          highlightTotal: false,
        ),
      ),
      SizedBox(height: AppSpacing.xs.dh),
      Text(
        l10n.bookingCashFootnote(provider),
        style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
      ),
      gap,
      BookingSection(
        title: l10n.bookingContact,
        child: DividedCard(
          children: <Widget>[
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
                vertical: AppSpacing.sm.dh,
              ),
              child: Row(
                children: <Widget>[
                  AppAvatar(name: provider, photoUrl: booking.provider?.avatarUrl),
                  SizedBox(width: AppSpacing.sm.dw),
                  Expanded(
                    child: Text(provider, style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary)),
                  ),
                  if (contactOpen && phone != null)
                    Semantics(
                      button: true,
                      label: l10n.bookingCallLabel(provider),
                      child: GestureDetector(
                        onTap: () => _call(phone),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.dh),
                          child: Text(
                            phone,
                            textDirection: TextDirection.ltr,
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.textBrand),
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      l10n.bookingPhoneHidden,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
                vertical: AppSpacing.sm.dh,
              ),
              child: Row(
                children: <Widget>[
                  AppIcon(
                    contactOpen ? AppIcons.check : AppIcons.eye,
                    color: AppColors.iconDefault,
                  ),
                  SizedBox(width: AppSpacing.xs.dw),
                  Expanded(
                    child: Text(
                      switch (status) {
                        'pending' => l10n.contactNotePending(provider),
                        'accepted' => l10n.contactNoteAccepted,
                        'declined' => l10n.contactNoteDeclined,
                        'cancelled' => l10n.contactNoteCancelled,
                        _ => l10n.contactNoteCompleted,
                      },
                      style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (booking.cancellationPolicy case final String policy when policy.isNotEmpty) ...<Widget>[
        gap,
        BookingSection(
          title: l10n.bookingCancellationPolicy,
          child: DividedCard(
            children: <Widget>[
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md.dw,
                  vertical: AppSpacing.sm.dh,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.bookingPolicySetBy(provider),
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
      if (booking.can(BookingAction.dispute) && !booking.can(BookingAction.checkIn)) ...<Widget>[
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

  /// The timeline for the status, the dates filled in from what happened.
  List<TimelineStep> _steps(
    BuildContext context,
    BookingDetailViewModel viewModel,
    BookingDetail booking,
  ) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    final BookingCard card = booking.card;
    final String provider = card.providerName;
    String when(DateTime? at) =>
        at == null ? '' : '${shortDate(at.toLocal(), language)} · ${clockTime(at)}';
    final DateTime? requested = _at(booking, TimelineEntryType.created) ?? card.createdAt;
    final DateTime? accepted = _at(booking, TimelineEntryType.accepted);
    final String eventDay = <String>[
      shortDate(card.eventDate, language),
      if (card.startTime case final String start) start,
    ].join(' · ');
    final String eventRange = <String>[
      shortDate(card.eventDate, language),
      timeRange(card.startTime, card.endTime, nextDay: l10n.bookingNextDayMark),
    ].where((String s) => s.isNotEmpty).join(' · ');
    final Reschedule? proposal = booking.proposalForMe;

    TimelineStep requestedStep(TimelineStepState state) =>
        TimelineStep(title: l10n.stepRequested, subtitle: when(requested), state: state);
    TimelineStep acceptedStep(TimelineStepState state) => TimelineStep(
          title: l10n.stepAcceptedBy(provider),
          subtitle: when(accepted),
          state: state,
        );
    TimelineStep eventStep(TimelineStepState state, {bool range = false}) =>
        TimelineStep(title: l10n.stepEventDay, subtitle: range ? eventRange : eventDay, state: state);

    switch (card.status) {
      case 'pending':
        final String? reply = booking.provider?.replyTime;
        return <TimelineStep>[
          requestedStep(TimelineStepState.current),
          TimelineStep(
            title: l10n.stepWaitingFor(provider),
            subtitle: reply == null
                ? l10n.stepRepliesWithinHours(viewModel.replyDeadlineHours)
                : l10n.stepUsuallyReplies(reply),
            state: TimelineStepState.todo,
          ),
          eventStep(TimelineStepState.todo),
          TimelineStep(
            title: l10n.stepCompleted,
            subtitle: l10n.stepConfirmAfter,
            state: TimelineStepState.todo,
          ),
        ];
      case 'declined':
        return <TimelineStep>[
          requestedStep(TimelineStepState.done),
          TimelineStep(
            title: l10n.stepDeclinedBy(provider),
            subtitle: when(_at(booking, TimelineEntryType.declined)),
            state: TimelineStepState.bad,
          ),
          eventStep(TimelineStepState.todo),
          TimelineStep(
            title: l10n.stepCompleted,
            subtitle: l10n.stepNotApplicable,
            state: TimelineStepState.todo,
          ),
        ];
      case 'cancelled':
        return <TimelineStep>[
          requestedStep(TimelineStepState.done),
          if (accepted != null) acceptedStep(TimelineStepState.done),
          TimelineStep(
            title: booking.cancelledByClient ? l10n.stepCancelledByYou : l10n.stepCancelledBy(provider),
            subtitle: when(_at(booking, TimelineEntryType.cancelled)),
            state: TimelineStepState.bad,
          ),
          eventStep(TimelineStepState.todo),
        ];
      case 'completed':
        final DateTime? completed = _at(booking, TimelineEntryType.completed);
        return <TimelineStep>[
          requestedStep(TimelineStepState.done),
          acceptedStep(TimelineStepState.done),
          eventStep(TimelineStepState.done, range: true),
          TimelineStep(
            title: l10n.stepCompleted,
            subtitle: <String>[
              if (completed != null) shortDate(completed.toLocal(), language),
              if (booking.checkedIn) l10n.stepYouConfirmed,
            ].join(' · '),
            state: TimelineStepState.current,
          ),
        ];
      default:
        final bool passed = viewModel.eventPassed;
        return <TimelineStep>[
          requestedStep(TimelineStepState.done),
          acceptedStep(proposal == null && !passed ? TimelineStepState.current : TimelineStepState.done),
          if (proposal != null)
            TimelineStep(
              title: l10n.stepNewDateProposed,
              subtitle: <String>[
                when(proposal.createdAt),
                l10n.stepWaitingForYou,
              ].where((String s) => s.isNotEmpty).join(' · '),
              state: TimelineStepState.current,
            ),
          eventStep(passed ? TimelineStepState.done : TimelineStepState.todo, range: passed),
          TimelineStep(
            title: l10n.stepCompleted,
            subtitle: !passed
                ? l10n.stepConfirmAfter
                : booking.checkedIn
                    ? l10n.stepYouConfirmedWaiting(provider)
                    : l10n.stepHowDidItGo,
            state: passed ? TimelineStepState.current : TimelineStepState.todo,
          ),
        ];
    }
  }

  static DateTime? _at(BookingDetail booking, TimelineEntryType type) {
    DateTime? found;
    for (final TimelineEntry entry in booking.timeline) {
      if (entry.type == type) found = entry.at;
    }
    return found;
  }

}

/// B6a: the provider's new date, the old one struck through, their reason,
/// and Accept / Decline.
class _ProposalBanner extends StatelessWidget {
  const _ProposalBanner({
    required this.proposal,
    required this.provider,
    required this.answering,
    required this.onAccept,
    required this.onDecline,
  });

  final Reschedule proposal;
  final String provider;
  final String? answering;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final String newWhen = <String>[
      shortDate(proposal.newDate, language),
      if (proposal.newStartTime case final String start) start,
    ].join(' · ');
    final String oldWhen = shortDate(proposal.oldDate, language);

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
            l10n.proposalTitle(provider),
            style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.xs.dh),
          Row(
            children: <Widget>[
              column(oldWhen, l10n.proposalCurrent, old: true),
              SizedBox(width: AppSpacing.sm.dw),
              const AppIcon(AppIcons.chevronRight, color: AppColors.iconDefault),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(child: column(newWhen, l10n.proposalProposed, old: false)),
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
            l10n.proposalConsequence(shortDate(proposal.oldDate, language), provider),
            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.sm.dh),
          Row(
            children: <Widget>[
              Expanded(
                child: MainButton(
                  label: l10n.proposalAccept(shortDate(proposal.newDate, language)),
                  isLoading: answering == 'accept',
                  canBeTapped: answering == null,
                  onPressed: onAccept,
                ),
              ),
              SizedBox(width: AppSpacing.xs.dw),
              Expanded(
                child: MainButton(
                  label: l10n.proposalDecline,
                  style: MainButtonStyle.secondary,
                  isLoading: answering == 'reject',
                  canBeTapped: answering == null,
                  onPressed: onDecline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The bar under B4, per status — as drawn for each variant.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.booking,
    required this.viewModel,
    required this.onMessage,
    required this.onCancel,
    required this.onReschedule,
    required this.onCheckIn,
    required this.onReview,
    required this.onInvoice,
    required this.onFindSimilar,
    required this.onBookAgain,
  });

  final BookingDetail booking;
  final BookingDetailViewModel viewModel;
  final VoidCallback onMessage;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onCheckIn;
  final VoidCallback onReview;
  final VoidCallback onInvoice;
  final VoidCallback onFindSimilar;
  final VoidCallback onBookAgain;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String provider = booking.card.providerName;
    final bool canMessage = booking.can(BookingAction.message);

    MainButton message({required bool primary}) => MainButton(
          label: l10n.bookingMessageProvider(provider),
          style: primary ? MainButtonStyle.primary : MainButtonStyle.secondary,
          isLoading: viewModel.isOpeningChat,
          onPressed: onMessage,
        );

    final List<Widget> rows;
    switch (booking.status) {
      case 'pending':
        rows = <Widget>[
          if (canMessage) message(primary: true),
          if (booking.can(BookingAction.cancel))
            MainButton(
              label: l10n.bookingCancelRequest,
              style: MainButtonStyle.ghost,
              tone: MainButtonTone.danger,
              onPressed: onCancel,
            ),
        ];
      case 'declined':
        rows = <Widget>[
          MainButton(label: l10n.bookingFindSimilar, onPressed: onFindSimilar),
          if (canMessage) message(primary: false),
        ];
      case 'cancelled':
        rows = <Widget>[
          MainButton(label: l10n.bookingBookAgain(provider), onPressed: onBookAgain),
          if (canMessage) message(primary: false),
        ];
      case 'completed':
        rows = <Widget>[
          if (booking.can(BookingAction.review))
            MainButton(label: l10n.bookingLeaveReview, onPressed: onReview)
          else if (canMessage)
            message(primary: true),
          if (booking.can(BookingAction.invoice))
            MainButton(
              label: l10n.bookingViewInvoice,
              style: MainButtonStyle.secondary,
              onPressed: onInvoice,
            ),
        ];
      default:
        final bool reschedule = booking.can(BookingAction.reschedule);
        final bool cancel = booking.can(BookingAction.cancel);
        rows = <Widget>[
          if (booking.can(BookingAction.checkIn)) ...<Widget>[
            MainButton(label: l10n.checkInCalloutAction, onPressed: onCheckIn),
            if (canMessage) message(primary: false),
          ] else if (canMessage)
            message(primary: true),
          if (reschedule || cancel)
            Row(
              children: <Widget>[
                if (reschedule)
                  Expanded(
                    child: MainButton(
                      label: l10n.bookingProposeDate,
                      style: MainButtonStyle.secondary,
                      onPressed: onReschedule,
                    ),
                  ),
                if (reschedule && cancel) SizedBox(width: AppSpacing.xs.dw),
                if (cancel)
                  Expanded(
                    child: MainButton(
                      label: l10n.bookingCancelBooking,
                      style: MainButtonStyle.ghost,
                      tone: MainButtonTone.danger,
                      onPressed: onCancel,
                    ),
                  ),
              ],
            ),
        ];
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

/// Vertical space between B4's sections.
class _Gap extends StatelessWidget {
  const _Gap(this.height);

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}
