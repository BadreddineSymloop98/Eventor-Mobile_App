import 'package:flutter/material.dart';

import '../../../../core/bookings/bookings_repository.dart';
import '../../../../core/catalog/models/catalog_models.dart';
import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/formatting/booking_format.dart';
import '../../../../core/formatting/date_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/localization/catalog_labels.dart';
import '../../../../core/models/account.dart';
import '../../../../core/widgets/atoms/app_chip.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/category_icon.dart';
import '../../../../core/widgets/molecules/app_select_field.dart';
import '../../../../core/widgets/molecules/app_text_area.dart';
import '../../../../core/widgets/molecules/app_text_field.dart';
import '../../../../core/widgets/molecules/app_toast.dart';
import '../../../../core/widgets/molecules/inline_banner.dart';
import '../../../../core/widgets/molecules/price_text.dart';
import '../../../../core/widgets/molecules/quantity_input.dart';
import '../../../../core/widgets/molecules/quantity_stepper.dart';
import '../../../../core/widgets/organisms/booking_cards.dart';
import '../../../../core/widgets/organisms/calendar_card.dart';
import '../../../../core/widgets/organisms/month_calendar.dart';
import '../../../../core/widgets/organisms/selection_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../view_model/booking_request_view_model.dart';

/// A red line under a section the request cannot go without.
class FieldErrorText extends StatelessWidget {
  const FieldErrorText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs.dh),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textDanger,
            ),
      ),
    );
  }
}

/// B1's first block: what is being requested, from whom.
class BookingSubjectPill extends StatelessWidget {
  const BookingSubjectPill({
    required this.title,
    required this.providerName,
    required this.icon,
    super.key,
  });

  final String title;
  final String providerName;
  final AppIcons icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm.dw,
        vertical: AppSpacing.xs.dh,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgBrandSubtle,
        borderRadius: AppRadii.mdAll,
      ),
      child: Row(
        children: <Widget>[
          AppIcon(icon, color: AppColors.iconBrand),
          SizedBox(width: AppSpacing.xs.dw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(color: AppColors.textBrand),
                ),
                Text(
                  providerName,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The failed-send banners: B1a (could not send), B1b (the date was just
/// taken), and the two refusals the form can do something about.
class SendProblemBanner extends StatelessWidget {
  const SendProblemBanner({required this.viewModel, super.key});

  final BookingRequestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    final String provider = viewModel.providerName;
    final DateTime? taken = viewModel.takenDate;
    final Failure? failure = viewModel.failure;
    return switch (viewModel.problem) {
      null => const SizedBox.shrink(),
      SendProblem.dateTaken => InlineBanner(
          title: taken == null
              ? l10n.bookingTakenTitleUndated
              : l10n.bookingTakenTitle(weekdayDayMonth(taken, language)),
          message: l10n.bookingTakenBody(provider),
        ),
      SendProblem.tooSoon => InlineBanner(
          title: l10n.bookingTooSoonTitle,
          message: l10n.bookingTooSoonBody,
        ),
      SendProblem.notAccepting => InlineBanner(
          title: l10n.bookingNotAcceptingTitle(provider),
          message: l10n.bookingNotAcceptingBody,
        ),
      SendProblem.failed => InlineBanner(
          title: l10n.bookingFailedTitle,
          message: failure is NetworkFailure || failure == null
              ? l10n.bookingFailedOffline
              : '${l10n.forFailure(failure)} ${l10n.bookingFailedKept}',
        ),
    };
  }
}

/// "Date and time": the calendar, the From / To pickers under it and the
/// summary of what is picked. [legend] words it for a pack (B9).
class BookingDateSection extends StatelessWidget {
  const BookingDateSection({
    required this.viewModel,
    this.legend = const CalendarLegendLabels(),
    this.intro,
    super.key,
  });

  final BookingRequestViewModel viewModel;
  final CalendarLegendLabels legend;

  /// A line under the heading — B9's "Only days when all 3 services are
  /// free can be picked."
  final String? intro;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime? picked = viewModel.selectedDate;
    final String? line = intro;
    final int notice = viewModel.availability?.minNoticeDays ?? 0;
    final bool canPick = viewModel.canPickDates;
    final Widget footer = TimeBlock(
      date: picked,
      start: viewModel.startTime,
      end: viewModel.endTime,
      enabled: canPick,
      helper: viewModel.needsTimes ? l10n.bookingTimeHelperHourly : l10n.bookingTimeHelper,
      hasError: viewModel.missing.contains(BookingField.time),
      refused: viewModel.dateRefused,
      onStart: viewModel.setStartTime,
      onEnd: viewModel.setEndTime,
    );


    return BookingSection(
      title: l10n.bookingDateTime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (line != null) ...<Widget>[
            Text(line, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            SizedBox(height: AppSpacing.xs.dh),
          ],
          CalendarCard(
            month: viewModel.visibleMonth,
            firstMonth: viewModel.firstMonth,
            availability: viewModel.availability,
            monthFailed: viewModel.monthFailed,
            selected: picked,
            onSelect: canPick ? viewModel.selectDate : null,
            onMonthChanged: viewModel.showMonth,
            onRetry: viewModel.retryMonth,
            legend: legend,
            footer: footer,
            notes: <String>[
              if (notice > 0) l10n.bookingNoticeDays(notice),
              l10n.bookingProviderConfirmsTime,
            ],
          ),
          if (viewModel.missing.contains(BookingField.date))
            FieldErrorText(l10n.bookingDateError),
        ],
      ),
    );
  }
}

/// The time part of a date card (B1, B6, B9): From and To pickers in
/// half-hour steps — both optional unless the price is per hour — and the
/// summary of the day and times picked.
///
/// To lists the half hours after From as a growing duration, running past
/// midnight into the next day, so an evening event can end at 02:00 and the
/// same time as From (a 24-hour event) cannot be picked.
class TimeBlock extends StatelessWidget {
  const TimeBlock({
    required this.date,
    required this.start,
    required this.end,
    required this.enabled,
    required this.helper,
    required this.onStart,
    required this.onEnd,
    this.hasError = false,
    this.refused = false,
    super.key,
  });

  final DateTime? date;
  final String? start;
  final String? end;
  final bool enabled;
  final String helper;
  final ValueChanged<String?> onStart;
  final ValueChanged<String?> onEnd;
  final bool hasError;

  /// The picked day can no longer be booked.
  final bool refused;

  Future<void> _pick(BuildContext context, {required bool isStart}) async {
    final AppLocalizations l10n = context.l10n;
    final String? current = isStart ? start : end;
    final String? from = start;
    const String none = '';
    final Set<String>? picked = await showSelectionSheet<String>(
      context,
      title: isStart ? l10n.bookingFrom : l10n.bookingTo,
      selected: <String>{current ?? none},
      options: <SelectionOption<String>>[
        SelectionOption<String>(value: none, label: l10n.bookingNoTime),
        if (isStart || from == null)
          for (final String slot in halfHourSlots())
            SelectionOption<String>(value: slot, label: slot)
        else
          for (final String slot in endSlotsAfter(from))
            SelectionOption<String>(
              value: slot,
              label: slot,
              detail: <String>[
                if (endsNextDay(from, slot)) l10n.bookingNextDay,
                _duration(l10n, spanMinutes(from, slot)),
              ].join(' · '),
            ),
      ],
    );
    if (picked == null || picked.isEmpty) return;
    final String? value = picked.first == none ? null : picked.first;
    if (isStart) {
      onStart(value);
    } else {
      onEnd(value);
    }
  }

  /// "30 min", "8 h", "5 h 30 min" — how long the event runs.
  static String _duration(AppLocalizations l10n, int minutes) {
    final int hours = minutes ~/ 60;
    if (hours == 0) return l10n.bookingDurationHalfHour;
    return minutes % 60 == 0
        ? l10n.bookingDurationHours(hours)
        : l10n.bookingDurationHoursHalf(hours);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;

    Widget box(String label, String? value, VoidCallback? onTap, {String? mark}) => Expanded(
          child: Semantics(
            button: true,
            label: label,
            value: value == null ? l10n.bookingNoTime : <String>[value, ?mark].join(' '),
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm.dw,
                  vertical: AppSpacing.xs.dh,
                ),
                decoration: BoxDecoration(
                  color: onTap == null ? AppColors.bgCanvas : AppColors.bgSurface,
                  borderRadius: AppRadii.mdAll,
                  border: Border.all(
                    color: hasError ? AppColors.borderDanger : AppColors.borderDefault,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            label,
                            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                          ),
                          Row(
                            children: <Widget>[
                              Text(
                                value ?? '--:--',
                                textDirection: TextDirection.ltr,
                                style: textTheme.titleMedium?.copyWith(
                                  color: value == null ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                              if (mark != null) ...<Widget>[
                                SizedBox(width: AppSpacing.xs2.dw),
                                Flexible(
                                  child: Text(
                                    mark,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelSmall?.copyWith(color: AppColors.textBrand),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      const AppIcon(
                        AppIcons.chevronDown,
                        size: AppSizes.iconSm,
                        color: AppColors.iconDefault,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
        SizedBox(height: AppSpacing.sm.dh),
        Text(
          l10n.bookingTimeOverline,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.66,
          ),
        ),
        SizedBox(height: AppSpacing.xs.dh),
        Row(
          children: <Widget>[
            box(l10n.bookingFrom, start, enabled ? () => _pick(context, isStart: true) : null),
            SizedBox(width: AppSpacing.xs.dw),
            const AppIcon(AppIcons.chevronRight, size: AppSizes.iconSm, color: AppColors.iconDefault),
            SizedBox(width: AppSpacing.xs.dw),
            box(
              l10n.bookingTo,
              end,
              enabled && start != null ? () => _pick(context, isStart: false) : null,
              mark: endsNextDay(start, end) ? l10n.bookingNextDayMark : null,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs.dh),
        Text(
          helper,
          style: textTheme.labelSmall?.copyWith(
            color: hasError ? AppColors.textDanger : AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.sm.dh),
        _SelectionSummary(
          date: date,
          start: start,
          end: end,
          refused: refused,
          language: language,
        ),
      ],
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.date,
    required this.start,
    required this.end,
    required this.refused,
    required this.language,
  });

  final DateTime? date;
  final String? start;
  final String? end;
  final bool refused;
  final String language;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime? day = date;
    final bool has = day != null && !refused;
    final TextStyle? style = textTheme.labelLarge?.copyWith(
      color: has ? AppColors.textBrand : AppColors.textSecondary,
    );
    final String times = timeRange(start, end, nextDay: l10n.bookingNextDayMark);

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm.dw,
        vertical: AppSpacing.xs.dh,
      ),
      decoration: BoxDecoration(
        color: has ? AppColors.bgBrandSubtle : AppColors.bgCanvas,
        borderRadius: AppRadii.mdAll,
      ),
      child: Row(
        children: <Widget>[
          if (has) ...<Widget>[
            const AppIcon(AppIcons.check, size: AppSizes.iconMd, color: AppColors.iconBrand),
            SizedBox(width: AppSpacing.xs.dw),
          ],
          Expanded(
            child: day == null
                ? Text(l10n.bookingNoDate, style: style)
                : refused
                    ? Text(l10n.bookingDateRefused, style: style)
                    : Wrap(
                        spacing: AppSpacing.xs2.dw,
                        children: <Widget>[
                          Text(shortDate(day, language), style: style),
                          if (times.isNotEmpty) ...<Widget>[
                            Text('·', style: style),
                            Text(times, textDirection: TextDirection.ltr, style: style),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

/// "Your event": the type of event and the guests.
class BookingEventSection extends StatelessWidget {
  const BookingEventSection({required this.viewModel, super.key});

  final BookingRequestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int? maxGuests = viewModel.maxGuests;
    final bool guestsMissing = viewModel.missing.contains(BookingField.guests);
    final bool overLimit = viewModel.guestsOverLimit;

    return BookingSection(
      title: l10n.bookingYourEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.xs.dw,
            runSpacing: AppSpacing.xs.dh,
            children: <Widget>[
              for (final EventType type in EventType.browsable)
                AppChip(
                  label: l10n.eventTypeLabel(type),
                  isSelected: viewModel.eventType == type,
                  onTap: () => viewModel.setEventType(type),
                ),
            ],
          ),
          if (viewModel.missing.contains(BookingField.eventType))
            FieldErrorText(l10n.bookingEventTypeError),
          SizedBox(height: AppSpacing.md.dh),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.bookingGuests,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                    ),
                    // Over the cap, the helper itself turns into the
                    // reason, as soon as the number is typed.
                    Text(
                      overLimit
                          ? l10n.bookingGuestsTooMany(viewModel.guestLimit)
                          : maxGuests == null
                              ? l10n.bookingGuestsHelper
                              : l10n.bookingGuestsMax(maxGuests),
                      style: textTheme.labelSmall?.copyWith(
                        color: overLimit ? AppColors.textDanger : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              QuantityInput(
                label: l10n.bookingGuests,
                value: viewModel.guests,
                max: viewModel.guestLimit,
                hasError: guestsMissing || overLimit,
                onChanged: viewModel.setGuests,
              ),
            ],
          ),
          if (guestsMissing && !overLimit) FieldErrorText(l10n.bookingGuestsError),
        ],
      ),
    );
  }
}

/// "Where": wilaya, commune (when the wilaya has any listed), address.
class BookingWhereSection extends StatelessWidget {
  const BookingWhereSection({
    required this.viewModel,
    required this.address,
    super.key,
  });

  final BookingRequestViewModel viewModel;
  final TextEditingController address;

  Future<void> _pickWilaya(BuildContext context) async {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    FocusScope.of(context).unfocus();
    final List<Wilaya> options = viewModel.wilayaOptions;
    if (options.isEmpty) {
      showAppToast(context, l10n.bookingNoWilayas, tone: AppToastTone.error);
      return;
    }
    final Set<int>? picked = await showSelectionSheet<int>(
      context,
      title: l10n.bookingWilaya,
      subtitle: l10n.bookingWilayaSheetBody(viewModel.providerName),
      selected: <int>{?viewModel.wilaya?.code},
      searchHint: options.length > 8 ? l10n.bookingSearchWilaya : null,
      options: <SelectionOption<int>>[
        for (final Wilaya w in options)
          SelectionOption<int>(value: w.code, label: '${w.code} · ${w.nameFor(language)}'),
      ],
    );
    if (picked == null || picked.isEmpty) return;
    for (final Wilaya w in options) {
      if (w.code == picked.first) await viewModel.setWilaya(w);
    }
  }

  Future<void> _pickCommune(BuildContext context) async {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    FocusScope.of(context).unfocus();
    const String none = '';
    final List<Commune> communes = viewModel.communes;
    final Set<String>? picked = await showSelectionSheet<String>(
      context,
      title: l10n.bookingCommune,
      selected: <String>{viewModel.commune?.id ?? none},
      searchHint: communes.length > 8 ? l10n.bookingSearchCommune : null,
      options: <SelectionOption<String>>[
        SelectionOption<String>(value: none, label: l10n.bookingNoCommune),
        for (final Commune c in communes)
          SelectionOption<String>(value: c.id, label: c.nameFor(language)),
      ],
    );
    if (picked == null || picked.isEmpty) return;
    Commune? chosen;
    for (final Commune c in communes) {
      if (c.id == picked.first) chosen = c;
    }
    viewModel.setCommune(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    final bool showCommune =
        viewModel.isLoadingCommunes || viewModel.communes.isNotEmpty;

    return BookingSection(
      title: l10n.bookingWhere,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSelectField(
            label: l10n.bookingWilaya,
            value: viewModel.wilaya?.nameFor(language),
            placeholder: l10n.bookingWilayaPlaceholder,
            onTap: () => _pickWilaya(context),
          ),
          if (viewModel.missing.contains(BookingField.wilaya))
            FieldErrorText(l10n.bookingWilayaError),
          if (showCommune) ...<Widget>[
            SizedBox(height: AppSpacing.md.dh),
            AppSelectField(
              label: l10n.bookingCommune,
              value: viewModel.commune?.nameFor(language),
              placeholder: l10n.bookingCommunePlaceholder,
              isLoading: viewModel.isLoadingCommunes,
              onTap: viewModel.isLoadingCommunes ? null : () => _pickCommune(context),
            ),
          ],
          SizedBox(height: AppSpacing.md.dh),
          AppTextField(
            controller: address,
            label: l10n.bookingAddress,
            hintText: l10n.bookingAddressHint,
            textCapitalization: TextCapitalization.sentences,
            onChanged: viewModel.setAddress,
          ),
        ],
      ),
    );
  }
}

/// "Extras": each add-on with its price and how many.
class BookingExtrasSection extends StatelessWidget {
  const BookingExtrasSection({required this.viewModel, required this.extras, super.key});

  final BookingRequestViewModel viewModel;
  final List<ServiceExtra> extras;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;

    return BookingSection(
      title: l10n.bookingExtras,
      child: Column(
        children: <Widget>[
          for (final ServiceExtra extra in extras)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs.dh),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          extra.name.of(language),
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                        ),
                        PriceText(amount: extra.price, prefix: '+'),
                      ],
                    ),
                  ),
                  QuantityStepper(
                    label: extra.name.of(language),
                    value: viewModel.extraCount(extra.id),
                    onChanged: (int n) => viewModel.setExtra(extra.id, n),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Note for the provider (optional)".
class BookingNoteField extends StatelessWidget {
  const BookingNoteField({required this.viewModel, required this.controller, super.key});

  final BookingRequestViewModel viewModel;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return AppTextArea(
      controller: controller,
      label: l10n.bookingNote,
      hintText: l10n.bookingNoteHint,
      maxLength: BookingRequestViewModel.maxNote,
      showCounter: controller.text.length > BookingRequestViewModel.maxNote - 200,
      onChanged: viewModel.setNote,
    );
  }
}

/// "Price": the lines, the total to pay on the day, and the cash note.
class BookingPriceSection extends StatelessWidget {
  const BookingPriceSection({required this.viewModel, super.key});

  final BookingRequestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    final ServiceDetail? service = viewModel.service;
    final String? unit = service == null ? null : l10n.priceUnit(service.priceType);

    return BookingSection(
      title: l10n.bookingPrice,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PriceLinesCard(
            lines: viewModel.lines(language, packSavingLabel: l10n.bookingPackSaving),
            totalLabel: l10n.bookingTotalOnSite,
            total: viewModel.total,
            unitOf: (BookingLine line) =>
                line.kind == BookingLineKind.service && unit != null
                    ? l10n.bookingBasePrice(unit)
                    : null,
          ),
          SizedBox(height: AppSpacing.xs.dh),
          Text(
            l10n.bookingCashFootnote(viewModel.providerName),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// The price block on the sticky bar — the total, or "—" while there is no
/// date to price.
class BookingBarTotal extends StatelessWidget {
  const BookingBarTotal({required this.total, required this.caption, this.isEmpty = false, super.key});

  final String total;
  final String caption;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (isEmpty)
          Text('—', style: textTheme.titleMedium?.copyWith(color: AppColors.textSecondary))
        else
          PriceText(
            amount: total,
            amountStyle: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
        Text(caption, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

/// The glyph for what is being booked.
AppIcons subjectIcon(CategoryRef? category) => categoryIcon(category?.icon);
