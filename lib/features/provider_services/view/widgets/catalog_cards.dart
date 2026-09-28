import 'package:flutter/material.dart';
// Only DateFormat: intl's own TextDirection would shadow Flutter's.
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/catalog/models/json_read.dart';
import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/formatting/money_format.dart';
import '../../../../core/formatting/rating_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/localization/catalog_labels.dart';
import '../../../../core/provider_catalog/provider_catalog_repository.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/app_network_image.dart';
import '../../../../core/widgets/atoms/outlined_status_pill.dart';
import '../../../../core/widgets/atoms/skeleton.dart';
import '../../../../core/widgets/atoms/status_badge.dart';
import '../../../../core/widgets/molecules/meta_line.dart';
import '../../../../core/widgets/molecules/price_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../catalog_wording.dart';

/// The card shell of P6 and P10 (§1.9): the head, a hairline, the figures, a
/// hairline, then an optional note and the actions.
class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.thumbUrl,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.badge,
    required this.figures,
    required this.price,
    required this.actions,
    required this.onTap,
    this.note,
  });

  final String? thumbUrl;
  final String title;
  final String? subtitle;
  final String? meta;
  final Widget badge;

  /// The start column of the middle band.
  final Widget figures;
  final Widget price;
  final String? note;
  final Widget actions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? line2 = subtitle;
    final String? line3 = meta;
    final String? caption = note;
    const Widget divider = Divider(height: 1, thickness: 1, color: AppColors.borderDefault);
    final EdgeInsetsDirectional inset =
        EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw);

    return DecoratedBox(
      decoration: const BoxDecoration(borderRadius: AppRadii.mdAll, boxShadow: AppElevation.sm),
      child: Material(
        color: AppColors.bgSurface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.mdAll,
          side: BorderSide(color: AppColors.borderDefault),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.dh),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                button: true,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: inset,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppNetworkImage(
                          url: thumbUrl,
                          width: 44.dw,
                          height: 44.dw,
                          radius: AppRadii.smAll,
                        ),
                        SizedBox(width: AppSpacing.sm.dw),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                              ),
                              if (line2 != null)
                                Text(
                                  line2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                ),
                              if (line3 != null)
                                Text(
                                  line3,
                                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs.dw),
                        badge,
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.sm.dh),
              divider,
              SizedBox(height: AppSpacing.sm.dh),
              Padding(
                padding: inset,
                child: Row(
                  children: <Widget>[
                    Expanded(child: figures),
                    SizedBox(width: AppSpacing.sm.dw),
                    price,
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.sm.dh),
              divider,
              SizedBox(height: AppSpacing.sm.dh),
              Padding(
                padding: inset,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (caption != null) ...<Widget>[
                      Text(
                        caption,
                        style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: AppSpacing.xs.dh),
                    ],
                    actions,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A P6 card: one of the provider's services, with its note (decision 4)
/// and the actions its status allows — built by the caller.
class ServiceCatalogCard extends StatelessWidget {
  const ServiceCatalogCard({
    required this.service,
    required this.actions,
    required this.onTap,
    this.note,
    this.hiddenAt,
    super.key,
  });

  final ProviderServiceSummary service;
  final Widget actions;
  final VoidCallback onTap;
  final String? note;
  final DateTime? hiddenAt;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final DateTime? hidden = hiddenAt;
    final String? meta = switch (service.status) {
      ProviderServiceStatus.draft => l10n.providerServiceNotPublishedYet,
      ProviderServiceStatus.hidden when hidden != null =>
        l10n.providerServiceHiddenOn('${hidden.day} ${DateFormat.MMMM(language).format(hidden)}'),
      ProviderServiceStatus.hidden => null,
      ProviderServiceStatus.published => service.ratingCount > 0
          ? l10n.providerServiceRatingLine(service.ratingCount, formatRating(service.avgRating))
          : l10n.providerServiceNoReviews,
    };
    return _CatalogCard(
      thumbUrl: service.coverUrl,
      title: service.title.of(language),
      subtitle: service.category?.nameFor(language),
      meta: meta,
      badge: ServiceStatusBadge(switch (service.status) {
        ProviderServiceStatus.published => ServiceStatusKind.published,
        ProviderServiceStatus.draft => ServiceStatusKind.draft,
        ProviderServiceStatus.hidden => ServiceStatusKind.hidden,
      }),
      figures: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.priceTypeLine(service.priceType),
            style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
          ),
          MetaLine(
            parts: <MetaPart>[
              MetaPart(l10n.providerServicePhotosCount(service.photosCount)),
              MetaPart(l10n.providerServiceBookingsCount(service.bookingsCount)),
            ],
          ),
        ],
      ),
      price: PriceText(
        amount: service.basePrice,
        amountStyle: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
      ),
      note: note,
      actions: actions,
      onTap: onTap,
    );
  }
}

/// A P10 card: one of the provider's packs.
class PackCatalogCard extends StatelessWidget {
  const PackCatalogCard({
    required this.pack,
    required this.actions,
    required this.onTap,
    this.note,
    super.key,
  });

  final ProviderPackSummary pack;
  final Widget actions;
  final VoidCallback onTap;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final bool saves = amountIsPositive(pack.savings);
    final String? meta = switch (pack.status) {
      PackStatus.published => pack.ratingCount > 0
          ? l10n.providerServiceRatingLine(pack.ratingCount, formatRating(pack.rating))
          : l10n.providerServiceNoReviews,
      PackStatus.draft => l10n.providerServiceNotPublishedYet,
      PackStatus.unpublished => null,
    };
    return _CatalogCard(
      thumbUrl: pack.coverUrl,
      title: pack.name.of(language),
      subtitle: pack.categoryNames.isEmpty
          ? null
          : pack.categoryNames.map((LocalizedText n) => n.of(language)).join(' · '),
      meta: meta,
      badge: PackStatusBadge(pack.status),
      figures: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MetaLine(
            style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
            parts: <MetaPart>[
              MetaPart(l10n.eventTypeLabel(pack.eventType)),
              MetaPart(l10n.providerPackServicesCount(pack.itemsCount)),
              if (pack.wilaya.code != 0) MetaPart(pack.wilaya.nameFor(language)),
            ],
          ),
          // "Saves 45 000 DA", or the sum while the price is not below it —
          // the amount its own token, so Arabic keeps its digit groups.
          MetaLine(
            parts: <MetaPart>[
              MetaPart(saves ? l10n.providerPackSaves : l10n.providerPackSumOfItems),
              MetaPart.amount(saves ? pack.savings : pack.sumOfItems),
            ],
          ),
        ],
      ),
      price: PriceText(
        amount: pack.price,
        amountStyle: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
      ),
      note: note,
      actions: actions,
      onTap: onTap,
    );
  }
}

/// A pack's Published / Draft / Unpublished pill.
class PackStatusBadge extends StatelessWidget {
  const PackStatusBadge(this.status, {super.key});

  final PackStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return switch (status) {
      PackStatus.published =>
        OutlinedStatusPill(label: l10n.serviceStatusPublished, color: AppColors.statusAccepted),
      PackStatus.draft =>
        OutlinedStatusPill(label: l10n.serviceStatusDraft, color: AppColors.statusCompleted),
      PackStatus.unpublished =>
        OutlinedStatusPill(label: l10n.providerPackStatusUnpublished, color: AppColors.statusCompleted),
    };
  }
}

/// G1 for P6 / P10: three cards' worth of grey.
class CatalogListSkeleton extends StatelessWidget {
  const CatalogListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < 3; i++) ...<Widget>[
          if (i > 0) SizedBox(height: AppSpacing.md.dh),
          Skeleton(height: 196.dh, radius: AppRadii.mdAll),
        ],
      ],
    );
  }
}

/// P6a / P10a: the mark, a title, a line and one way forward, centred.
class CatalogEmptyState extends StatelessWidget {
  const CatalogEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    super.key,
  });

  final AppIcons icon;
  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: 44.dw,
            height: 44.dw,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.bgBrandSubtle,
              borderRadius: AppRadii.smAll,
            ),
            child: AppIcon(icon, color: AppColors.iconBrand),
          ),
        ),
        SizedBox(height: AppSpacing.md.dh),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
        ),
        SizedBox(height: AppSpacing.xs.dh),
        Text(
          body,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
        ),
        SizedBox(height: AppSpacing.md.dh),
        action,
      ],
    );
  }
}
