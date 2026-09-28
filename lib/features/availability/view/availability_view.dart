import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/availability/availability_repository.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/availability_view_model.dart';
import 'widgets/availability_sheets.dart';
import 'widgets/provider_calendar.dart';

/// P15 Availability — the provider's month, painted by what is on each day.
///
/// Tapping a day picks it and opens P15c (decision 3); "Block a day" blocks
/// the picked day through P15a. The month reloads on pull, when the app
/// comes back to the front, and on the way back from a booking opened from
/// a day, so a request answered meanwhile shows.
class AvailabilityView extends StatefulWidget {
  const AvailabilityView({super.key});

  @override
  State<AvailabilityView> createState() => _AvailabilityViewState();
}

class _AvailabilityViewState extends State<AvailabilityView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<AvailabilityViewModel>().refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _toastFailure(Failure failure) {
    final AppLocalizations l10n = context.l10n;
    final String message = switch (failure) {
      ApiFailure(code: ApiErrorCode.availabilityBlockNotFound) => l10n.availabilityErrorNotFound,
      ApiFailure(code: ApiErrorCode.availabilityBlockNotRemovable) => l10n.availabilityErrorNotRemovable,
      ApiFailure(code: ApiErrorCode.availabilityDatePast) => l10n.availabilityErrorDatePast,
      _ => l10n.forFailure(failure),
    };
    showAppToast(context, message, tone: AppToastTone.error);
  }

  Future<void> _refresh(AvailabilityViewModel viewModel) async {
    final Failure? failure = await viewModel.refresh();
    if (failure != null && mounted) _toastFailure(failure);
  }

  /// P15c for [date], then whatever it was closed with.
  Future<void> _openDay(AvailabilityViewModel viewModel, DateTime date) async {
    viewModel.selectDay(date);
    final DaySheetAction? action = await showDaySheet(
      context,
      day: viewModel.dayOf(date) ?? ProviderDay.empty(date),
      isPast: viewModel.isPast(date),
      refusal: viewModel.whyNotBlockable(date),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case RemoveBlock(:final ProviderDayItem item):
        await _remove(viewModel, item);
      case BlockDay(:final BlockMode mode):
        await _block(viewModel, date, mode);
      case OpenBooking(:final String bookingId):
        await context.push(AppRoutes.providerBookingFor(bookingId));
        if (mounted) await _refresh(viewModel);
    }
  }

  /// P15a / P15b for [date]; a toast once it is blocked.
  Future<void> _block(AvailabilityViewModel viewModel, DateTime date, BlockMode mode) async {
    final BlockMode? blocked = await showBlockSheet(
      context,
      viewModel: viewModel,
      day: viewModel.dayOf(date) ?? ProviderDay.empty(date),
      mode: mode,
    );
    if (blocked == null || !mounted) return;
    final AppLocalizations l10n = context.l10n;
    final String day = weekdayDayMonth(date, Localizations.localeOf(context).languageCode);
    showAppToast(
      context,
      blocked == BlockMode.wholeDay ? l10n.availabilityBlockedDayToast(day) : l10n.availabilityBlockedSlotToast(day),
    );
  }

  /// Removes at once, with Undo (decision 6).
  Future<void> _remove(AvailabilityViewModel viewModel, ProviderDayItem item) async {
    if (viewModel.isRemoving(item)) return;
    final Failure? failure = await viewModel.remove(item);
    if (!mounted) return;
    if (failure != null) {
      _toastFailure(failure);
      return;
    }
    final AppLocalizations l10n = context.l10n;
    showAppToast(
      context,
      l10n.availabilityRemovedToast,
      tone: AppToastTone.info,
      actionLabel: l10n.undo,
      onAction: () => _undo(viewModel, item),
    );
  }

  Future<void> _undo(AvailabilityViewModel viewModel, ProviderDayItem item) async {
    final Failure? failure = await viewModel.restore(item);
    if (!mounted) return;
    if (failure != null) {
      _toastFailure(failure);
    } else {
      showAppToast(context, context.l10n.availabilityRestoredToast);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AvailabilityViewModel viewModel = context.watch<AvailabilityViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? caption = textTheme.labelSmall?.copyWith(color: AppColors.textSecondary);
    final DateTime? picked = viewModel.selectedDate;
    final int notice = viewModel.minNoticeDays;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(
            title: l10n.availabilityTitle,
            onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.providerHome),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.bgBrand,
              onRefresh: () => _refresh(viewModel),
              child: ListView(
                // Pull to refresh needs something to pull on a short month.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md.dw,
                  AppSpacing.md.dh,
                  AppSpacing.md.dw,
                  AppSpacing.xl.dh,
                ),
                children: <Widget>[
                  // The design repeats the month above the card; the card's
                  // own month row is enough.
                  Container(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.sm.dw,
                      vertical: AppSpacing.sm.dh,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: AppRadii.lgAll,
                      border: Border.all(color: AppColors.borderDefault),
                      boxShadow: AppElevation.sm,
                    ),
                    child: ProviderMonthCalendar(
                      month: viewModel.visibleMonth,
                      data: viewModel.month,
                      failure: viewModel.monthFailure == null
                          ? null
                          : _MonthFailed(failure: viewModel.monthFailure!, onRetry: viewModel.retryMonth),
                      today: viewModel.today,
                      selected: picked,
                      canGoBack: viewModel.canGoBack,
                      onDayTap: (DateTime date) => _openDay(viewModel, date),
                      onMonthChanged: viewModel.showMonth,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm.dh),
                  if (notice > 0) Text(l10n.availabilityNotice(notice), style: caption),
                  Text(l10n.availabilityTapHint, style: caption),
                ],
              ),
            ),
          ),
          BottomActionBar(
            child: MainButton(
              label: l10n.availabilityBlockDay,
              onPressed: picked != null && viewModel.canBlockSelected
                  ? () => _block(viewModel, picked, BlockMode.wholeDay)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A month that could not load: why, and a retry, in place of the grid.
class _MonthFailed extends StatelessWidget {
  const _MonthFailed({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.dh),
      child: Column(
        children: <Widget>[
          Text(
            l10n.monthLoadFailed,
            textAlign: TextAlign.center,
            style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.xs2.dh),
          Text(
            l10n.forFailure(failure),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xs.dh),
          MainButton(
            label: l10n.stateRetry,
            style: MainButtonStyle.ghost,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
