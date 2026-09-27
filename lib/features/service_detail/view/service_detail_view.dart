import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/category_icon.dart';
import '../../../core/widgets/atoms/rating_line.dart';
import '../../../core/widgets/atoms/verified_badge.dart';
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
import '../view_model/service_detail_view_model.dart';

/// Screen 12 — a service.
///
/// Gallery, head, the provider, key facts, about, the provider's own policy,
/// extras, the live calendar, reviews and the provider's packs, over a
/// sticky bar with the price and the booking button. When the provider has
/// paused bookings the bar says so instead (13's drawn state) and the
/// calendar only shows.
class ServiceDetailView extends StatelessWidget {
  const ServiceDetailView({super.key});

  static const double _photoHeight = 280;

  static void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final ServiceDetailViewModel viewModel = context
        .watch<ServiceDetailViewModel>();
    final ServiceDetail? service = viewModel.service;

    if (viewModel.isGone) return DetailGoneView(onBack: () => _back(context));
    if (service == null) {
      if (viewModel.hasError) {
        return DetailErrorView(
          onRetry: viewModel.load,
          onBack: () => _back(context),
        );
      }
      return DetailSkeleton(photoHeight: _photoHeight.dh);
    }
    return _ServiceDetailContent(viewModel: viewModel, service: service);
  }
}

class _ServiceDetailContent extends StatelessWidget {
  const _ServiceDetailContent({required this.viewModel, required this.service});

  final ServiceDetailViewModel viewModel;
  final ServiceDetail service;

  Future<void> _message(BuildContext context) async {
    final String? route = await viewModel.chatRouteWith(
      userId: service.provider.id,
      name: service.provider.businessName,
    );
    if (route != null && context.mounted) context.push(route);
  }

  void _comingSoon(BuildContext context) =>
      showComingSoon(context, context.l10n.comingSoon);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final LocalizedText? policy = service.cancellationPolicy;
    final int? guests = service.maxGuests;
    final int minNotice = viewModel.availability?.minNoticeDays ?? 1;

    Widget section(
      String title,
      Widget child, {
      String? action,
      VoidCallback? onAction,
    }) => Padding(
      padding: EdgeInsets.only(top: AppSpacing.xl.dh),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(title: title, actionLabel: action, onAction: onAction),
          SizedBox(height: AppSpacing.xs.dh),
          child,
        ],
      ),
    );

    final List<InfoRow> facts = <InfoRow>[
      for (final ServiceFact fact in service.facts)
        InfoRow(
          icon: AppIcons.check,
          text: '${fact.label.of(language)} · ${fact.value.of(language)}',
        ),
      if (guests != null)
        InfoRow(icon: AppIcons.user, text: l10n.upToGuests(guests)),
      if (service.wilayas.isNotEmpty)
        InfoRow(
          icon: AppIcons.mapPin,
          text: service.wilayas
              .map((Wilaya w) => w.nameFor(language))
              .join(' · '),
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
                  photos: service.photos,
                  height: ServiceDetailView._photoHeight.dh,
                  placeholderIcon: categoryIcon(service.category?.icon),
                  overlay: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.xs.dw,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          PhotoBackButton(
                            onPressed: () => ServiceDetailView._back(context),
                          ),
                          const Spacer(),
                          FavouriteButton(
                            target: FavouriteTarget.service(service.id),
                            initial: service.isFavourite,
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
                      if (service.provider.verified)
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: VerifiedBadge(),
                        ),
                      SizedBox(height: AppSpacing.xs.dh),
                      Text(
                        service.title.of(language),
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs.dh),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: RatingLine(
                          avgRating: service.avgRating,
                          ratingCount: service.ratingCount,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                      ProviderMiniCard(
                        provider: service.provider,
                        onTap: () => context.push(
                          AppRoutes.providerFor(service.provider.id),
                        ),
                      ),
                      if (facts.isNotEmpty) ...<Widget>[
                        SizedBox(height: AppSpacing.md.dh),
                        InfoCard(rows: facts),
                      ],
                      section(
                        l10n.serviceAbout,
                        ReadMoreText(service.description.of(language)),
                      ),
                      if (policy != null) ...<Widget>[
                        SizedBox(height: AppSpacing.md.dh),
                        InfoCard(
                          title: l10n.serviceGoodToKnow,
                          rows: <InfoRow>[
                            InfoRow(
                              icon: AppIcons.fileText,
                              text: l10n.serviceCancellation(
                                policy.of(language),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (service.extras.isNotEmpty)
                        section(
                          l10n.serviceExtras,
                          Column(
                            children: <Widget>[
                              for (final ServiceExtra extra in service.extras)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs.dh,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      AppIcon(
                                        AppIcons.plus,
                                        size: AppSizes.iconMd,
                                        color: AppColors.iconBrand,
                                      ),
                                      SizedBox(width: AppSpacing.xs.dw),
                                      Expanded(
                                        child: Text(
                                          extra.name.of(language),
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      PriceText(
                                        amount: extra.price,
                                        prefix: '+',
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                          onSelect: viewModel.canBook
                              ? viewModel.selectDate
                              : null,
                          onMonthChanged: viewModel.showMonth,
                          onRetry: viewModel.retryMonth,
                          notes: <String>[
                            l10n.calendarMinNotice(minNotice),
                            if (viewModel.canBook) l10n.calendarConfirmNote,
                          ],
                        ),
                      ),
                      section(
                        l10n.serviceReviews,
                        service.ratingCount == 0
                            ? Text(
                                l10n.serviceNoReviews,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  RatingSummary(
                                    avgRating: service.avgRating,
                                    ratingCount: service.ratingCount,
                                    breakdown: service.ratingBreakdown,
                                  ),
                                  for (final Review review
                                      in service.recentReviews) ...<Widget>[
                                    SizedBox(height: AppSpacing.sm.dh),
                                    ReviewCard(review),
                                  ],
                                ],
                              ),
                        action:
                            service.ratingCount > service.recentReviews.length
                            ? l10n.seeAllCount(service.ratingCount)
                            : null,
                        onAction: () => _comingSoon(context),
                      ),
                      if (service.providerPacks.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.xl.dh),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              SectionHeader(
                                title: l10n.servicePacksFromProvider,
                              ),
                              SizedBox(height: AppSpacing.xs.dh),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (service.providerPacks.isNotEmpty)
                  PacksRail(
                    packs: service.providerPacks,
                    onOpen: (PackCard pack) =>
                        context.push(AppRoutes.packFor(pack.id)),
                  ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.xs.dw,
                    AppSpacing.md.dh,
                    AppSpacing.md.dw,
                    AppSpacing.xl.dh,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MainButton(
                      label: l10n.serviceReport,
                      style: MainButtonStyle.ghost,
                      onPressed: () => _comingSoon(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (viewModel.canBook)
            StickyActionBar(
              leading: ServicePrice(
                amount: service.basePrice,
                type: service.priceType,
                fromOnOwnLine: true,
                amountStyle: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              actions: <Widget>[
                MessageIconButton(
                  isLoading: viewModel.isOpeningChat,
                  onPressed: () => _message(context),
                ),
                MainButton(
                  label: l10n.requestBooking,
                  // B1 is not built; the chosen date is kept for when it is.
                  onPressed: () => _comingSoon(context),
                ),
              ],
            )
          else
            StickyActionBar.notAccepting(
              isMessageLoading: viewModel.isOpeningChat,
              onMessage: () => _message(context),
            ),
        ],
      ),
    );
  }
}
