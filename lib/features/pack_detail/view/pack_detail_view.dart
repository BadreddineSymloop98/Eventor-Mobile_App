import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/category_icon.dart';
import '../../../core/widgets/atoms/icon_tile.dart';
import '../../../core/widgets/atoms/rating_line.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/favourite_button.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/price_text.dart';
import '../../../core/widgets/molecules/read_more_text.dart';
import '../../../core/widgets/molecules/section_header.dart';
import '../../../core/widgets/organisms/calendar_card.dart';
import '../../../core/widgets/organisms/detail_states.dart';
import '../../../core/widgets/organisms/info_card.dart';
import '../../../core/widgets/organisms/pack_cards.dart';
import '../../../core/widgets/organisms/photo_carousel.dart';
import '../../../core/widgets/organisms/provider_mini_card.dart';
import '../../../core/widgets/organisms/review_views.dart';
import '../../../core/widgets/organisms/sticky_action_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/pack_detail_view_model.dart';

/// Screen 20 — a Ready Pack.
///
/// No cancellation line: the API has no pack policy, and the app never states
/// one of its own. When the provider paused bookings, the bar says so and the
/// calendar only shows.
class PackDetailView extends StatelessWidget {
  const PackDetailView({super.key});

  static const double _photoHeight = 280;

  static void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final PackDetailViewModel viewModel = context.watch<PackDetailViewModel>();
    final PackDetail? pack = viewModel.pack;

    if (viewModel.isGone) return DetailGoneView(onBack: () => _back(context));
    if (pack == null) {
      if (viewModel.hasError) {
        return DetailErrorView(onRetry: viewModel.load, onBack: () => _back(context));
      }
      return DetailSkeleton(photoHeight: _photoHeight.dh);
    }
    return _PackContent(viewModel: viewModel, pack: pack);
  }
}

class _PackContent extends StatelessWidget {
  const _PackContent({required this.viewModel, required this.pack});

  final PackDetailViewModel viewModel;
  final PackDetail pack;

  void _comingSoon(BuildContext context) =>
      showComingSoon(context, context.l10n.comingSoon);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final LocalizedText? description = pack.description;
    final int? guests = pack.maxGuests;
    final int minNotice = viewModel.availability?.minNoticeDays ?? 1;

    Widget section(String title, Widget child) => Padding(
          padding: EdgeInsets.only(top: AppSpacing.xl.dh),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionHeader(title: title),
              SizedBox(height: AppSpacing.xs.dh),
              child,
            ],
          ),
        );

    final List<InfoRow> goodToKnow = <InfoRow>[
      if (guests != null) InfoRow(icon: AppIcons.user, text: l10n.upToGuests(guests)),
      if (pack.wilayas.isNotEmpty)
        InfoRow(
          icon: AppIcons.mapPin,
          text: l10n.packAvailableIn(
            pack.wilayas.map((Wilaya w) => w.nameFor(language)).join(' · '),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                PhotoCarousel(
                  photos: pack.photos,
                  height: PackDetailView._photoHeight.dh,
                  placeholderIcon: AppIcons.layers,
                  overlay: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs.dw),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          PhotoBackButton(onPressed: () => PackDetailView._back(context)),
                          const Spacer(),
                          FavouriteButton(
                            target: FavouriteTarget.pack(pack.id),
                            initial: pack.isFavourite,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md.dw,
                    AppSpacing.md.dh,
                    AppSpacing.md.dw,
                    AppSpacing.xl.dh,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.xs.dw,
                            vertical: AppSpacing.xs2.dh,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgBrandSubtle,
                            borderRadius: AppRadii.fullAll,
                          ),
                          child: Text(
                            l10n.packBadge(pack.itemsCount),
                            style: textTheme.labelMedium?.copyWith(color: AppColors.textBrand),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs.dh),
                      Text(
                        pack.name.of(language),
                        style: textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary),
                      ),
                      SizedBox(height: AppSpacing.xs.dh),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs.dw,
                        children: <Widget>[
                          RatingLine(avgRating: pack.avgRating, ratingCount: pack.ratingCount),
                          Text(
                            l10n.packBookings(pack.bookingsCount),
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xs2.dh),
                      Row(
                        children: <Widget>[
                          AppIcon(AppIcons.mapPin, size: AppSizes.iconSm, color: AppColors.iconDefault),
                          SizedBox(width: AppSpacing.xs2.dw),
                          Text(
                            pack.wilaya.nameFor(language),
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                      _PriceCard(pack: pack),
                      SizedBox(height: AppSpacing.md.dh),
                      ProviderMiniCard(
                        provider: pack.provider,
                        onTap: () => context.push(AppRoutes.providerFor(pack.provider.id)),
                      ),
                      section(
                        l10n.packInside,
                        _Inside(
                          pack: pack,
                          onOpen: (PackItem item) => context.push(AppRoutes.serviceFor(item.serviceId)),
                        ),
                      ),
                      section(
                        l10n.servicePickDate,
                        CalendarCard(
                          month: viewModel.visibleMonth,
                          firstMonth: viewModel.firstMonth,
                          availability: viewModel.availability,
                          monthFailed: viewModel.monthFailed,
                          selected: viewModel.selectedDate,
                          onSelect: viewModel.canBook ? viewModel.selectDate : null,
                          onMonthChanged: viewModel.showMonth,
                          onRetry: viewModel.retryMonth,
                          notes: <String>[l10n.packCalendarHint, l10n.calendarMinNotice(minNotice)],
                        ),
                      ),
                      if (description != null)
                        section(l10n.packAbout, ReadMoreText(description.of(language))),
                      if (goodToKnow.isNotEmpty) ...<Widget>[
                        SizedBox(height: AppSpacing.md.dh),
                        InfoCard(title: l10n.serviceGoodToKnow, rows: goodToKnow),
                      ],
                      if (pack.recentReviews.isNotEmpty)
                        section(
                          l10n.serviceReviews,
                          Column(
                            children: <Widget>[
                              for (final Review review in pack.recentReviews) ...<Widget>[
                                if (review != pack.recentReviews.first)
                                  SizedBox(height: AppSpacing.sm.dh),
                                ReviewCard(review),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (viewModel.canBook)
            StickyActionBar(
              leading: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PriceText(
                    amount: pack.price,
                    amountStyle: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                  Text(
                    l10n.packAllServices(pack.itemsCount),
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              actions: <Widget>[
                MessageIconButton(onPressed: () => _comingSoon(context)),
                MainButton(
                  label: l10n.requestPack,
                  // B9a is not built; the day picked here is kept for it.
                  onPressed: () => _comingSoon(context),
                ),
              ],
            )
          else
            StickyActionBar.notAccepting(onMessage: () => _comingSoon(context)),
        ],
      ),
    );
  }
}

/// The price card: the pack's price, what it would cost booked separately
/// (struck through), and the saving.
class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.pack});

  final PackDetail pack;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? struck = textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
      decoration: TextDecoration.lineThrough,
    );

    return Container(
      padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: AppElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.sm.dw,
            children: <Widget>[
              PriceText(
                amount: pack.price,
                amountStyle: textTheme.displayLarge?.copyWith(color: AppColors.textPrimary),
              ),
              PriceText(amount: pack.sumOfItems, amountStyle: struck, labelStyle: struck),
            ],
          ),
          SizedBox(height: AppSpacing.xs.dh),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs.dw,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.fullAll,
                  border: Border.all(color: AppColors.borderAccent),
                ),
                child: SavingsPill(savings: pack.savings, percent: pack.savingsPercent),
              ),
              Text(
                context.l10n.packVersus,
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "What is inside": each service with its own price, then the total they
/// would cost booked one by one.
class _Inside extends StatelessWidget {
  const _Inside({required this.pack, required this.onOpen});

  final PackDetail pack;
  final ValueChanged<PackItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: AppElevation.sm,
      ),
      child: Column(
        children: <Widget>[
          for (final PackItem item in pack.items) ...<Widget>[
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: () => onOpen(item),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md.dw,
                    vertical: AppSpacing.sm.dh,
                  ),
                  child: Row(
                    children: <Widget>[
                      IconTile(categoryIcon(item.category?.icon)),
                      SizedBox(width: AppSpacing.sm.dw),
                      Expanded(
                        child: Text(
                          item.title.of(language),
                          style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                      ServicePrice(amount: item.price, type: item.priceType, showFrom: false),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
          ],
          Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md.dw,
              vertical: AppSpacing.sm.dh,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.l10n.packBookedSeparately,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                PriceText(amount: pack.sumOfItems),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
