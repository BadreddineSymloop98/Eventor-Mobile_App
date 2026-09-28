import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/bookings_repository.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/meta_line.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/booking_cards.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/divided_card.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/request_sent_view_model.dart';

/// B2 Request sent. Takes B1's (or B9a's) place, so Back returns to the
/// service or the pack; "View booking" takes this screen's place in turn.
class RequestSentView extends StatelessWidget {
  const RequestSentView({super.key});

  Future<void> _message(BuildContext context, RequestSentViewModel viewModel) async {
    final String? route = await viewModel.chatRoute();
    if (route != null && context.mounted) context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final RequestSentViewModel viewModel = context.watch<RequestSentViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final BookingDetail booking = viewModel.booking;
    final BookingCard card = booking.card;
    final String provider = card.providerName;
    final String? replyTime = viewModel.args.replyTime;
    final String times = timeRange(card.startTime, card.endTime, nextDay: l10n.bookingNextDayMark);

    Widget fact(AppIcons icon, Widget text) => Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          child: Row(
            children: <Widget>[
              AppIcon(icon, size: AppSizes.iconMd, color: AppColors.iconBrand),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(child: text),
            ],
          ),
        );
    final TextStyle? factStyle = textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary);
    final String place = <String>[
      ?booking.communeName,
      ?booking.wilaya?.nameFor(language),
    ].join(', ');

    Widget step(int number, String title, String body) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm.dh),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: AppSpacing.xl.dw,
                height: AppSpacing.xl.dw,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.bgBrandSubtle,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: textTheme.labelMedium?.copyWith(color: AppColors.textBrand),
                ),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary)),
                    SizedBox(height: AppSpacing.xs2.dh / 2),
                    Text(body, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(title: l10n.requestSentTitle),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.bgBrandSubtle,
                          borderRadius: AppRadii.mdAll,
                        ),
                        child: const AppIcon(AppIcons.check, color: AppColors.iconBrand),
                      ),
                      SizedBox(width: AppSpacing.xs.dw),
                      Expanded(
                        child: Text(
                          l10n.requestSentHeading,
                          style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md.dh),
                  DividedCard(
                    children: <Widget>[
                      fact(
                        AppIcons.fileText,
                        MetaLine(
                          style: factStyle,
                          parts: <MetaPart>[
                            MetaPart(l10n.requestSentReference),
                            MetaPart(card.reference, isLtr: true),
                          ],
                        ),
                      ),
                      fact(
                        AppIcons.calendar,
                        MetaLine(
                          style: factStyle,
                          parts: <MetaPart>[
                            MetaPart(shortDate(card.eventDate, language)),
                            MetaPart(times, isLtr: true),
                          ],
                        ),
                      ),
                      if (place.isNotEmpty)
                        fact(AppIcons.mapPin, Text(place, style: factStyle)),
                      fact(
                        AppIcons.user,
                        MetaLine(
                          style: factStyle,
                          parts: <MetaPart>[
                            if (booking.guests case final int guests)
                              MetaPart(l10n.bookingGuestsCount(guests)),
                            MetaPart.amount(card.total),
                            MetaPart(l10n.bookingTotalCaption),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg.dh),
                  BookingSection(
                    title: l10n.requestSentNext,
                    child: Container(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.md.dw,
                        AppSpacing.sm.dh,
                        AppSpacing.md.dw,
                        0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: AppRadii.mdAll,
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Column(
                        children: <Widget>[
                          step(
                            1,
                            l10n.requestSentStep1(provider),
                            replyTime == null
                                ? l10n.requestSentStep1Deadline(viewModel.replyDeadlineHours)
                                : l10n.requestSentStep1Usually(replyTime),
                          ),
                          step(2, l10n.requestSentStep2, l10n.requestSentStep2Body),
                          step(3, l10n.requestSentStep3, l10n.requestSentStep3Body),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                MainButton(
                  label: l10n.requestSentViewBooking,
                  onPressed: () => context.pushReplacement(AppRoutes.bookingFor(card.id)),
                ),
                SizedBox(height: AppSpacing.xs.dh),
                MainButton(
                  label: l10n.bookingMessageProvider(provider),
                  style: MainButtonStyle.secondary,
                  isLoading: viewModel.isOpeningChat,
                  onPressed: () => _message(context, viewModel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
