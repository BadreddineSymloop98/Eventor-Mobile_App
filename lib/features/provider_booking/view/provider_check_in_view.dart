import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/models/booking_card.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/provider/provider_repository.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/atoms/category_icon.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/meta_line.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/detail_states.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/provider_check_in_view_model.dart';
import 'widgets/provider_booking_sheets.dart';

/// P5 After the event. Closes with the booking as it now stands after "All
/// good", with nothing after a problem report or "Remind me tomorrow" — P2
/// reloads either way.
class ProviderCheckInView extends StatelessWidget {
  const ProviderCheckInView({super.key});

  Future<void> _allGood(BuildContext context, ProviderCheckInViewModel viewModel) async {
    final AppLocalizations l10n = context.l10n;
    final ProviderBooking? updated = await viewModel.confirm();
    if (!context.mounted) return;
    if (updated == null) {
      final Failure? failure = viewModel.failure;
      if (failure != null) {
        showAppToast(context, l10n.forFailure(failure), tone: AppToastTone.error);
      }
      // Too early, no longer possible, or a dispute holds it: P2 shows
      // where it stands. Offline stays here to try again.
      if (failure is ApiFailure) Navigator.of(context).pop();
      return;
    }
    showAppToast(
      context,
      updated.status == 'completed'
          ? l10n.checkInClosed
          : l10n.providerBookingCheckInWaiting(updated.clientName),
      tone: AppToastTone.info,
    );
    Navigator.of(context).pop(updated);
  }

  Future<void> _problem(BuildContext context, ProviderCheckInViewModel viewModel) async {
    final ProviderBooking? booking = viewModel.booking;
    if (booking == null) return;
    final bool sent = await showProviderProblemSheet(
      context,
      clientName: booking.clientName,
      onSubmit: viewModel.reportProblem,
    );
    if (!sent || !context.mounted) return;
    showAppToast(context, context.l10n.problemDone, tone: AppToastTone.info);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ProviderCheckInViewModel viewModel = context.watch<ProviderCheckInViewModel>();
    final AppLocalizations l10n = context.l10n;
    final ProviderBooking? booking = viewModel.booking;

    final Widget body;
    if (booking == null) {
      body = viewModel.isGone
          ? DetailGoneView(onBack: () => context.pop())
          : viewModel.hasError
              ? DetailErrorView(onRetry: viewModel.load, onBack: () => context.pop())
              : const _Skeleton();
    } else if (!viewModel.canConfirm && !viewModel.isConfirming) {
      // Opened from an old notification: it was confirmed, disputed or
      // closed meanwhile.
      body = Padding(
        padding: AppSpacing.screenPaddingAll,
        child: StateCard.empty(
          icon: AppIcons.check,
          title: l10n.providerBookingCheckInNothing,
          actionLabel: l10n.providerBookingOpen,
          onAction: () => context.pushReplacement(AppRoutes.providerBookingFor(booking.id)),
        ),
      );
    } else {
      body = _Choices(
        booking: booking,
        viewModel: viewModel,
        onAllGood: () => _allGood(context, viewModel),
        onProblem: () => _problem(context, viewModel),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(title: l10n.checkInTitle),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.booking,
    required this.viewModel,
    required this.onAllGood,
    required this.onProblem,
  });

  final ProviderBooking booking;
  final ProviderCheckInViewModel viewModel;
  final VoidCallback onAllGood;
  final VoidCallback onProblem;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final BookingCard card = booking.card;
    final String client = booking.clientName;
    final bool confirming = viewModel.isConfirming;

    return CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.checkInHeading,
                  style: textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary),
                ),
                SizedBox(height: AppSpacing.xs.dh),
                Text(
                  l10n.providerBookingCheckInBody(client, weekdayDayMonth(card.eventDate, language)),
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: AppSpacing.md.dh),
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
                            MetaLine(
                              parts: <MetaPart>[
                                MetaPart(client),
                                MetaPart(card.reference, isLtr: true),
                                MetaPart.amount(card.total),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.md.dh),
                _ChoiceCard(
                  icon: AppIcons.check,
                  title: l10n.checkInAllGood,
                  body: l10n.providerBookingAllGoodBody(client),
                  emphasised: true,
                  isLoading: confirming,
                  onTap: confirming ? null : onAllGood,
                ),
                SizedBox(height: AppSpacing.sm.dh),
                _ChoiceCard(
                  icon: AppIcons.close,
                  title: l10n.checkInProblem,
                  body: l10n.providerBookingProblemBody,
                  onTap: confirming ? null : onProblem,
                ),
                const Spacer(),
                SizedBox(height: AppSpacing.xl.dh),
                MainButton(
                  label: l10n.providerBookingRemindTomorrow,
                  style: MainButtonStyle.ghost,
                  onPressed: confirming ? null : () => Navigator.of(context).pop(),
                ),
                SizedBox(height: AppSpacing.xs.dh),
                Text(
                  l10n.providerBookingCheckInFootnote,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One of P5's two answers: a tappable card, the recommended one outlined
/// in brand.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.emphasised = false,
    this.isLoading = false,
  });

  final AppIcons icon;
  final String title;
  final String body;
  final VoidCallback? onTap;
  final bool emphasised;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.mdAll,
          child: Container(
            padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
            decoration: BoxDecoration(
              borderRadius: AppRadii.mdAll,
              border: Border.all(
                color: emphasised ? AppColors.borderBrand : AppColors.borderDefault,
                width: emphasised ? 1.5 : 1,
              ),
              boxShadow: AppElevation.sm,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40.dw,
                  height: 40.dw,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: emphasised ? AppColors.bgBrandSubtle : AppColors.bgCanvas,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(icon, color: AppColors.iconBrand),
                ),
                SizedBox(width: AppSpacing.sm.dw),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary)),
                      SizedBox(height: AppSpacing.xs2.dh / 2),
                      Text(body, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.xs.dw),
                if (isLoading)
                  const AppSpinner(size: AppSizes.iconMd)
                else
                  const AppIcon(AppIcons.chevronRight, color: AppColors.iconDefault),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// P5's shape while the booking loads (opened from a notification).
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
        children: <Widget>[
          Skeleton(height: 28.dh, width: 200.dw),
          SizedBox(height: AppSpacing.xs.dh),
          Skeleton(height: 40.dh),
          SizedBox(height: AppSpacing.md.dh),
          Skeleton(height: 68.dh, radius: AppRadii.mdAll),
          SizedBox(height: AppSpacing.md.dh),
          Skeleton(height: 88.dh, radius: AppRadii.mdAll),
          SizedBox(height: AppSpacing.sm.dh),
          Skeleton(height: 88.dh, radius: AppRadii.mdAll),
        ],
      );
}
