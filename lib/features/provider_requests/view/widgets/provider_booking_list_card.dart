import 'package:flutter/material.dart';

import '../../../../core/bookings/models/booking_card.dart';
import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/formatting/booking_format.dart';
import '../../../../core/formatting/date_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/category_icon.dart';
import '../../../../core/widgets/atoms/status_badge.dart';
import '../../../../core/widgets/molecules/main_button.dart';
import '../../../../core/widgets/molecules/meta_line.dart';
import '../../../../core/widgets/molecules/price_text.dart';
import '../../../../l10n/app_localizations.dart';

/// One request or booking on P1: what, from whom, its reference and status;
/// then when, where and the total; and, on a request, how long is left to
/// answer with Decline and Accept.
class ProviderBookingListCard extends StatelessWidget {
  const ProviderBookingListCard({
    required this.booking,
    required this.onTap,
    this.replyHours,
    this.onAccept,
    this.onDecline,
    this.isBusy = false,
    this.isAccepting = false,
    super.key,
  });

  final BookingCard booking;
  final VoidCallback onTap;

  /// "Reply within N h" — only on a request.
  final int? replyHours;

  /// `null` hides the button: the server does not allow it.
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  /// An Accept is running somewhere on the list — both buttons wait.
  final bool isBusy;

  /// This card's Accept is the one running.
  final bool isAccepting;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final String times = timeRange(
      booking.startTime,
      booking.endTime,
      nextDay: l10n.bookingNextDayMark,
    );
    final int? guests = booking.guests;
    final String? where = booking.wilaya?.nameFor(language);
    final bool answers = onAccept != null || onDecline != null;
    final int? hours = replyHours;
    const Divider divider = Divider(height: 1, thickness: 1, color: AppColors.borderDefault);

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
                              booking.counterpartyName,
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
                divider,
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
                                if (times.isNotEmpty) MetaPart(times, isLtr: true),
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
                      SizedBox(width: AppSpacing.xs.dw),
                      PriceText(
                        amount: booking.total,
                        amountStyle: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                if (answers) ...<Widget>[
                  SizedBox(height: AppSpacing.sm.dh),
                  divider,
                  SizedBox(height: AppSpacing.sm.dh),
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (hours != null) ...<Widget>[
                          Text(
                            l10n.providerRequestsReplyWithin(hours),
                            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                          ),
                          SizedBox(height: AppSpacing.xs.dh),
                        ],
                        Row(
                          children: <Widget>[
                            if (onDecline != null)
                              Expanded(
                                child: MainButton(
                                  label: l10n.requestDecline,
                                  style: MainButtonStyle.secondary,
                                  canBeTapped: !isBusy,
                                  onPressed: onDecline,
                                ),
                              ),
                            if (onDecline != null && onAccept != null)
                              SizedBox(width: AppSpacing.xs.dw),
                            if (onAccept != null)
                              Expanded(
                                child: MainButton(
                                  label: l10n.requestAccept,
                                  isLoading: isAccepting,
                                  canBeTapped: !isBusy,
                                  onPressed: onAccept,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
