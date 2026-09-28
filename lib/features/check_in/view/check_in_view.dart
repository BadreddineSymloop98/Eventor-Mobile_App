import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/bookings_repository.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/atoms/category_icon.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/meta_line.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../booking_detail/view/widgets/booking_sheets.dart';
import '../view_model/check_in_view_model.dart';

/// B7 After the event. Closes with the booking as it now stands after
/// "All good", with nothing after a problem report or "Not now" — B4
/// reloads either way.
class CheckInView extends StatelessWidget {
  const CheckInView({super.key});

  Future<void> _allGood(BuildContext context, CheckInViewModel viewModel) async {
    final AppLocalizations l10n = context.l10n;
    final String provider = viewModel.booking.card.providerName;
    final BookingDetail? updated = await viewModel.confirm();
    if (!context.mounted) return;
    if (updated == null) {
      final Failure? failure = viewModel.failure;
      if (failure != null) {
        showAppToast(context, l10n.forFailure(failure), tone: AppToastTone.error);
      }
      // Too early, or it moved meanwhile: B4 shows where it stands.
      if (failure is ApiFailure) Navigator.of(context).pop();
      return;
    }
    showAppToast(
      context,
      updated.status == 'completed' ? l10n.checkInClosed : l10n.checkInWaiting(provider),
      tone: AppToastTone.info,
    );
    Navigator.of(context).pop(updated);
  }

  Future<void> _problem(BuildContext context, CheckInViewModel viewModel) async {
    final bool sent = await showProblemSheet(
      context,
      providerName: viewModel.booking.card.providerName,
      onSubmit: viewModel.reportProblem,
    );
    if (!sent || !context.mounted) return;
    showAppToast(context, context.l10n.problemDone, tone: AppToastTone.info);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final CheckInViewModel viewModel = context.watch<CheckInViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final BookingCard card = viewModel.booking.card;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(title: l10n.checkInTitle),
          Expanded(
            child: SingleChildScrollView(
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
                    l10n.checkInBody(weekdayDayMonth(card.eventDate, language)),
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
                                  MetaPart(card.providerName),
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
                    body: l10n.checkInAllGoodBody,
                    emphasised: true,
                    isLoading: viewModel.isConfirming,
                    onTap: viewModel.isConfirming ? null : () => _allGood(context, viewModel),
                  ),
                  SizedBox(height: AppSpacing.sm.dh),
                  _ChoiceCard(
                    icon: AppIcons.close,
                    title: l10n.checkInProblem,
                    body: l10n.checkInProblemBody,
                    onTap: viewModel.isConfirming ? null : () => _problem(context, viewModel),
                  ),
                  SizedBox(height: AppSpacing.xl.dh),
                  MainButton(
                    label: l10n.checkInNotNow,
                    style: MainButtonStyle.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(height: AppSpacing.xs.dh),
                  Text(
                    l10n.checkInFootnote,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
