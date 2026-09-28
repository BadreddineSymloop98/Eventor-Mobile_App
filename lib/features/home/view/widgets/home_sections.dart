import 'package:flutter/material.dart';

import '../../../../core/catalog/models/catalog_models.dart';
import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/formatting/date_format.dart';
import '../../../../core/formatting/rating_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/localization/catalog_labels.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/dashed_border_box.dart';
import '../../../../core/widgets/atoms/status_badge.dart';
import '../../../../core/widgets/molecules/main_button.dart';
import '../../../../core/widgets/molecules/price_text.dart';
import '../../../../core/widgets/organisms/cards.dart';
import '../../../../l10n/app_localizations.dart';

/// "Your bookings" — the next two.
class UpcomingBookingsList extends StatelessWidget {
  const UpcomingBookingsList({required this.bookings, required this.onOpen, super.key});

  final List<UpcomingBooking> bookings;
  final ValueChanged<UpcomingBooking> onOpen;

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    return Column(
      children: <Widget>[
        for (final UpcomingBooking booking in bookings) ...<Widget>[
          if (booking != bookings.first) SizedBox(height: AppSpacing.sm.dh),
          BookingCard(
            counterpartName: booking.providerName,
            meta: <String>[
              ?booking.category?.name.of(language),
              shortDate(booking.eventDate, language),
            ].join(' · '),
            status: BookingStatusKind.fromApi(booking.status),
            onTap: () => onOpen(booking),
          ),
        ],
      ],
    );
  }
}

/// The budget card: spent against planned, or — with no budget yet — the
/// invitation to make one (11c).
class BudgetCard extends StatelessWidget {
  const BudgetCard({required this.budget, required this.onOpen, super.key});

  final BudgetSummary budget;
  final VoidCallback onOpen;

  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Widget content = budget.exists
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Spent, "of", planned, "planned" — separate runs, so both
              // amounts keep their digits in order in Arabic.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xs.dw,
                children: <Widget>[
                  PriceText(
                    amount: budget.spentTotal,
                    amountStyle: textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
                  ),
                  Text(l10n.budgetOf, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  PriceText(
                    amount: budget.totalAmount,
                    amountStyle: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    labelStyle: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(l10n.budgetPlanned, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              SizedBox(height: AppSpacing.sm.dh),
              ClipRRect(
                borderRadius: AppRadii.fullAll,
                child: LinearProgressIndicator(
                  value: (budget.spentPercent / 100).clamp(0, 1).toDouble(),
                  minHeight: _barHeight.dh,
                  backgroundColor: AppColors.bgDisabled,
                  // Over budget reads in the danger colour.
                  color: budget.spentPercent > 100 ? AppColors.bgDanger : AppColors.bgBrand,
                ),
              ),
              SizedBox(height: AppSpacing.xs.dh),
              Text(
                l10n.budgetBooked(budget.bookedCount, budget.itemsCount),
                style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const AppIcon(AppIcons.pieChart, color: AppColors.iconBrand),
                  SizedBox(width: AppSpacing.xs.dw),
                  Expanded(
                    child: Text(
                      l10n.budgetEmptyTitle,
                      style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs.dh),
              Text(
                l10n.budgetEmptyBody,
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: AppSpacing.md.dh),
              MainButton(
                label: l10n.budgetCreate,
                style: MainButtonStyle.secondary,
                onPressed: onOpen,
              ),
            ],
          );

    // 11c: an invitation, drawn dashed like every "nothing here yet, add
    // one" card.
    if (!budget.exists) {
      return DashedBorderBox(
        padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
        child: content,
      );
    }

    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadii.mdAll,
          border: Border.all(color: AppColors.borderDefault),
          boxShadow: AppElevation.sm,
        ),
        child: content,
      ),
    );
  }
}

/// "Services near you" — the design's provider cards, carrying services
/// (the API's `nearbyServices`): title, "Provider · Category", price, rating.
class NearbyServicesList extends StatelessWidget {
  const NearbyServicesList({required this.services, required this.onOpen, super.key});

  final List<ServiceCard> services;
  final ValueChanged<ServiceCard> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;

    return Column(
      children: <Widget>[
        for (final ServiceCard service in services) ...<Widget>[
          if (service != services.first) SizedBox(height: AppSpacing.sm.dh),
          ProviderCard(
            name: service.title.of(language),
            meta: <String>[
              service.provider.businessName,
              ?service.category?.name.of(language),
            ].join(' · '),
            amount: service.basePrice,
            unit: l10n.priceUnit(service.priceType) ?? '',
            quoteLabel: service.priceType == PriceType.onQuote ? l10n.priceOnQuote : null,
            photoUrl: service.coverUrl,
            score: service.isRated ? formatRating(service.avgRating) : null,
            reviewCount: service.isRated ? service.ratingCount : null,
            isNew: !service.isRated,
            onTap: () => onOpen(service),
          ),
        ],
      ],
    );
  }
}
