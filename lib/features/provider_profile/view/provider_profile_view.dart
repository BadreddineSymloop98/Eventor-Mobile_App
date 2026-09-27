import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Only DateFormat: intl's own TextDirection would shadow Flutter's.
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/formatting/rating_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_avatar.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_network_image.dart';
import '../../../core/widgets/atoms/category_icon.dart';
import '../../../core/widgets/atoms/verified_badge.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/price_text.dart';
import '../../../core/widgets/molecules/read_more_text.dart';
import '../../../core/widgets/molecules/section_header.dart';
import '../../../core/widgets/molecules/stat_strip.dart';
import '../../../core/widgets/organisms/detail_states.dart';
import '../../../core/widgets/organisms/info_card.dart';
import '../../../core/widgets/organisms/pack_cards.dart';
import '../../../core/widgets/organisms/photo_carousel.dart';
import '../../../core/widgets/organisms/review_views.dart';
import '../../../core/widgets/organisms/sticky_action_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/provider_profile_view_model.dart';

/// Screen 13 — a provider's profile, and its "not accepting bookings" state.
///
/// There is no booking button here, as drawn: the bar offers a message, and
/// says how fast they reply when the API knows. When bookings are paused the
/// bar says that instead — messages still work.
class ProviderProfileView extends StatelessWidget {
  const ProviderProfileView({super.key});

  static void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final ProviderProfileViewModel viewModel = context.watch<ProviderProfileViewModel>();
    final ProviderDetail? provider = viewModel.provider;

    if (viewModel.isGone) return DetailGoneView(onBack: () => _back(context));
    if (provider == null) {
      if (viewModel.hasError) {
        return DetailErrorView(onRetry: viewModel.load, onBack: () => _back(context));
      }
      return DetailSkeleton(photoHeight: 180.dh);
    }
    return _ProfileContent(viewModel: viewModel, provider: provider);
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.viewModel, required this.provider});

  final ProviderProfileViewModel viewModel;
  final ProviderDetail provider;

  static const double _coverHeight = 180;
  static const double _avatarRing = 88;

  void _comingSoon(BuildContext context) =>
      showComingSoon(context, context.l10n.comingSoon);

  String _checkTitle(AppLocalizations l10n, ProviderCheck check) => switch (check.code) {
        'identity' => l10n.checkIdentity,
        'registration' => l10n.checkRegistration,
        'reply_time' => l10n.checkReplyTime,
        _ => check.title,
      };

  String _language(AppLocalizations l10n, String code) => switch (code) {
        'ar' => l10n.langAr,
        'fr' => l10n.langFr,
        'en' => l10n.langEn,
        _ => code,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final LocalizedText? bio = provider.bio;
    final int? years = provider.yearsActive;
    final String? replyTime = provider.replyTime;
    final List<ProviderCheck> checks = viewModel.passedChecks;

    Widget section(String title, Widget child, {String? action, VoidCallback? onAction}) =>
        Padding(
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

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // The brand cover (the API has no cover photo), with the
                // avatar ring overlapping its lower edge.
                SizedBox(
                  height: (_coverHeight + _avatarRing / 2).dh,
                  child: Stack(
                    children: <Widget>[
                      Container(
                        height: _coverHeight.dh,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                            colors: <Color>[AppColors.bgBrand, AppColors.bgBrandPressed],
                          ),
                        ),
                      ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(start: AppSpacing.xs.dw),
                          child: PhotoBackButton(
                            onPressed: () => ProviderProfileView._back(context),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: AppSpacing.md.dw,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsetsDirectional.all(AppSpacing.xs2.dw),
                          decoration: const BoxDecoration(
                            color: AppColors.bgSurface,
                            shape: BoxShape.circle,
                          ),
                          child: AppAvatar(
                            name: provider.businessName,
                            photoUrl: provider.avatarUrl,
                            size: AppAvatarSize.large,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md.dw,
                    AppSpacing.sm.dh,
                    AppSpacing.md.dw,
                    AppSpacing.md.dh,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (provider.verified)
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: VerifiedBadge(),
                        ),
                      SizedBox(height: AppSpacing.xs.dh),
                      Text(
                        provider.businessName,
                        style: textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary),
                      ),
                      Text(
                        <String>[
                          ?provider.category?.name.of(language),
                          ...provider.wilayas.take(2).map((Wilaya w) => w.nameFor(language)),
                        ].join(' · '),
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.dh),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: AppRadii.mdAll,
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: StatStrip(<StatItem>[
                          StatItem(
                            value: provider.isRated
                                ? formatRating(provider.avgRating)
                                : l10n.ratingNew,
                            label: l10n.statReviewsLabel(provider.ratingCount),
                            icon: AppIcons.starFilled,
                          ),
                          StatItem(
                            value: '${provider.completedBookingsCount}',
                            label: l10n.statCompletedLabel(provider.completedBookingsCount),
                          ),
                          if (years != null)
                            StatItem(value: '$years', label: l10n.statYearsLabel(years)),
                        ]),
                      ),
                      if (checks.isNotEmpty)
                        section(
                          l10n.profileChecked,
                          InfoCard(
                            rows: <InfoRow>[
                              for (final ProviderCheck check in checks)
                                InfoRow(
                                  icon: AppIcons.check,
                                  text: check.detail.isEmpty
                                      ? _checkTitle(l10n, check)
                                      : '${_checkTitle(l10n, check)} · ${check.detail}',
                                ),
                            ],
                          ),
                        ),
                      if (bio != null) section(l10n.profileAbout, ReadMoreText(bio.of(language))),
                      if (provider.services.isNotEmpty)
                        section(
                          l10n.profileServices,
                          Column(
                            children: <Widget>[
                              for (final ServiceCard service in provider.services)
                                _ServiceRow(
                                  service: service,
                                  onTap: () => context.push(AppRoutes.serviceFor(service.id)),
                                ),
                            ],
                          ),
                          // The profile lists ten at most; nothing lists the
                          // rest yet (spec D10).
                          action: provider.hasMoreServices
                              ? l10n.seeAllCount(provider.servicesCount)
                              : null,
                          onAction: () => _comingSoon(context),
                        ),
                    ],
                  ),
                ),
                if (provider.packs.isNotEmpty) ...<Widget>[
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.md.dw,
                      AppSpacing.md.dh,
                      AppSpacing.md.dw,
                      AppSpacing.xs.dh,
                    ),
                    child: SectionHeader(title: l10n.homeReadyPacks),
                  ),
                  PacksRail(
                    packs: provider.packs,
                    onOpen: (PackCard pack) => context.push(AppRoutes.packFor(pack.id)),
                  ),
                ],
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      section(
                        l10n.profileWhereTheyWork,
                        InfoCard(
                          rows: <InfoRow>[
                            if (provider.wilayas.isNotEmpty)
                              InfoRow(
                                icon: AppIcons.mapPin,
                                text: provider.wilayas
                                    .map((Wilaya w) => w.nameFor(language))
                                    .join(' · '),
                              ),
                            if (provider.languagesSpoken.isNotEmpty)
                              InfoRow(
                                icon: AppIcons.message,
                                text: l10n.profileLanguages(
                                  provider.languagesSpoken
                                      .map((String code) => _language(l10n, code))
                                      .join(' · '),
                                ),
                              ),
                            InfoRow(
                              icon: AppIcons.calendar,
                              // Month name and year apart: the year keeps
                              // Western digits in Arabic.
                              text: '${l10n.profileMemberSince} '
                                  '${DateFormat.MMMM(language).format(provider.memberSince)} '
                                  '${provider.memberSince.year}',
                            ),
                          ],
                        ),
                      ),
                      section(
                        l10n.serviceReviews,
                        provider.ratingCount == 0
                            ? Text(
                                l10n.serviceNoReviews,
                                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  RatingSummary(
                                    avgRating: provider.avgRating,
                                    ratingCount: provider.ratingCount,
                                    breakdown: provider.ratingBreakdown,
                                  ),
                                  for (final Review review in provider.recentReviews) ...<Widget>[
                                    SizedBox(height: AppSpacing.sm.dh),
                                    ReviewCard(review),
                                  ],
                                ],
                              ),
                        action: provider.ratingCount > provider.recentReviews.length
                            ? l10n.seeAllCount(provider.ratingCount)
                            : null,
                        onAction: () => _comingSoon(context),
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: MainButton(
                          label: l10n.profileReport,
                          style: MainButtonStyle.ghost,
                          flushStart: true,
                          onPressed: () => _comingSoon(context),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl.dh),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (provider.acceptingBookings)
            StickyActionBar(
              leading: replyTime == null
                  ? const SizedBox.shrink()
                  : Text(
                      l10n.repliesIn(replyTime),
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
              actions: <Widget>[
                MainButton(label: l10n.sendMessage, onPressed: () => _comingSoon(context)),
              ],
            )
          else
            StickyActionBar.notAccepting(onMessage: () => _comingSoon(context)),
        ],
      ),
    );
  }
}

/// One of the provider's services: photo, title, category, price.
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service, required this.onTap});

  final ServiceCard service;
  final VoidCallback onTap;

  static const double _thumb = 56;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.dh),
          child: Row(
            children: <Widget>[
              AppNetworkImage(
                url: service.coverUrl,
                width: _thumb.dw,
                height: _thumb.dw,
                radius: AppRadii.mdAll,
                placeholderIcon: categoryIcon(service.category?.icon),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      service.title.of(language),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                    ),
                    SizedBox(height: AppSpacing.xs2.dh),
                    ServicePrice(amount: service.basePrice, type: service.priceType),
                  ],
                ),
              ),
              AppIcon(AppIcons.chevronRight, size: AppSizes.iconMd, color: AppColors.iconDefault),
            ],
          ),
        ),
      ),
    );
  }
}
