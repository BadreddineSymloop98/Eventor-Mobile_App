import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/models/booking_card.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/provider/provider_repository.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/molecules/app_text_area.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/note_callout.dart';
import '../../../core/widgets/organisms/booking_cards.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/calendar_card.dart';
import '../../../core/widgets/organisms/discard_guard.dart';
import '../../../core/widgets/organisms/month_calendar.dart';
import '../../../core/widgets/organisms/sticky_action_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../booking_request/view/widgets/booking_form_sections.dart' show FieldErrorText, TimeBlock;
import '../view_model/provider_reschedule_view_model.dart';

/// P4 Propose a new date — or, on a request, change it at once. Closes with
/// the booking as it now stands.
class ProviderRescheduleView extends StatefulWidget {
  const ProviderRescheduleView({super.key});

  @override
  State<ProviderRescheduleView> createState() => _ProviderRescheduleViewState();
}

class _ProviderRescheduleViewState extends State<ProviderRescheduleView> {
  final TextEditingController _reason = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _reason.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ProviderRescheduleViewModel viewModel = context.read<ProviderRescheduleViewModel>();
    FocusScope.of(context).unfocus();
    final ProviderBooking? updated = await viewModel.submit();
    if (!mounted) return;
    if (updated != null) {
      Navigator.of(context).pop(updated);
      return;
    }
    switch (viewModel.problem) {
      case ProviderRescheduleProblem.stale:
        final Failure? failure = viewModel.failure;
        if (failure != null) {
          showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
        }
        // P2 reloads and shows where things stand.
        Navigator.of(context).pop();
      case ProviderRescheduleProblem.dateTaken || ProviderRescheduleProblem.failed:
        await _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProviderRescheduleViewModel viewModel = context.watch<ProviderRescheduleViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final BookingCard card = viewModel.booking.card;
    final String client = viewModel.booking.clientName;
    final DateTime? picked = viewModel.selectedDate;
    final DateTime? taken = viewModel.takenDate;
    final Failure? failure = viewModel.failure;

    return DiscardGuard(
      isDirty: viewModel.isDirty,
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(
              title: viewModel.isProposal ? l10n.rescheduleTitle : l10n.rescheduleTitlePending,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (viewModel.problem == ProviderRescheduleProblem.dateTaken && taken != null) ...<Widget>[
                      InlineBanner(
                        title: l10n.bookingTakenTitle(weekdayDayMonth(taken, language)),
                        message: l10n.providerBookingRescheduleTakenBody,
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                    ],
                    if (viewModel.problem == ProviderRescheduleProblem.failed) ...<Widget>[
                      InlineBanner(
                        title: l10n.rescheduleFailedTitle,
                        message: failure is NetworkFailure || failure == null
                            ? l10n.bookingFailedOffline
                            : '${l10n.forFailure(failure)} ${l10n.bookingFailedKept}',
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                    ],
                    // What stands now.
                    Container(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.md.dw,
                        vertical: AppSpacing.sm.dh,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: AppRadii.mdAll,
                        border: Border.all(color: AppColors.borderDefault),
                        boxShadow: AppElevation.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            viewModel.isProposal ? l10n.rescheduleCurrentlyBooked : l10n.rescheduleCurrentlyRequested,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: language == 'ar' ? 0 : 0.66,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs2.dh),
                          Wrap(
                            spacing: AppSpacing.xs2.dw,
                            children: <Widget>[
                              Text(
                                fullDate(card.eventDate, language),
                                style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
                              ),
                              if (card.startTime != null) ...<Widget>[
                                Text('·', style: textTheme.labelLarge),
                                Text(
                                  timeRange(card.startTime, card.endTime, nextDay: l10n.bookingNextDayMark),
                                  textDirection: TextDirection.ltr,
                                  style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${card.title.of(language)} · $client',
                            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg.dh),
                    BookingSection(
                      title: l10n.rescheduleNewDate,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          CalendarCard(
                            month: viewModel.visibleMonth,
                            firstMonth: viewModel.firstMonth,
                            availability: viewModel.availability,
                            monthFailed: viewModel.monthFailed,
                            selected: picked,
                            onSelect: viewModel.selectDate,
                            onMonthChanged: viewModel.showMonth,
                            onRetry: viewModel.retryMonth,
                            marked: card.eventDate,
                            legend: CalendarLegendLabels(
                              available: l10n.providerBookingLegendFree,
                              booked: l10n.calendarBooked,
                              unavailable: l10n.providerBookingLegendBlocked,
                              marked: l10n.rescheduleLegendCurrent,
                            ),
                            footer: TimeBlock(
                              date: picked,
                              start: viewModel.startTime,
                              end: viewModel.endTime,
                              enabled: !viewModel.isBusy,
                              helper: l10n.providerBookingTimeHelper,
                              onStart: viewModel.setStartTime,
                              onEnd: viewModel.setEndTime,
                            ),
                            notes: <String>[l10n.providerBookingRescheduleFootnote],
                          ),
                          if (viewModel.dateMissing) FieldErrorText(l10n.bookingDateError),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg.dh),
                    AppTextArea(
                      controller: _reason,
                      label: l10n.rescheduleReasonLabel,
                      hintText: l10n.providerBookingRescheduleReasonHint,
                      helperText: l10n.rescheduleReasonHelper(client),
                      errorText: viewModel.reasonMissing ? l10n.providerBookingRescheduleReasonError(client) : null,
                      maxLength: ProviderRescheduleViewModel.maxReason,
                      enabled: !viewModel.isBusy,
                      onChanged: viewModel.setReason,
                    ),
                    SizedBox(height: AppSpacing.md.dh),
                    NoteCallout(
                      icon: AppIcons.calendar,
                      text: viewModel.isProposal
                          ? l10n.providerBookingRescheduleHold(shortDate(card.eventDate, language), client)
                          : l10n.providerBookingReschedulePendingNote(client),
                    ),
                  ],
                ),
              ),
            ),
            StickyActionBar(
              leading: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    picked == null ? '—' : shortDate(picked, language),
                    style: textTheme.titleMedium?.copyWith(
                      color: picked == null ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    l10n.rescheduleProposedCaption,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              actions: <Widget>[
                MainButton(
                  label: viewModel.isProposal ? l10n.rescheduleSend : l10n.rescheduleMove,
                  isLoading: viewModel.isBusy,
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
