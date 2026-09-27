import 'package:flutter/material.dart';

import '../../catalog/models/catalog_models.dart';
import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_network_image.dart';
import '../atoms/category_icon.dart';
import '../atoms/rating_line.dart';
import '../molecules/favourite_button.dart';
import '../molecules/price_text.dart';

/// A service in search results (S2): photo, title, "Provider · Category",
/// rating and a heart; then where, how often booked, and the price.
class ServiceResultCard extends StatefulWidget {
  const ServiceResultCard(this.service, {this.onTap, super.key});

  final ServiceCard service;
  final VoidCallback? onTap;

  @override
  State<ServiceResultCard> createState() => _ServiceResultCardState();
}

class _ServiceResultCardState extends State<ServiceResultCard> {
  static const double _thumb = 56;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final ServiceCard service = widget.service;
    final String? category = service.category?.name.of(language);
    final String where = service.wilayas
        .take(2)
        .map((Wilaya w) => w.nameFor(language))
        .join(' · ');

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.bgSurfacePressed : AppColors.bgSurface,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppElevation.sm,
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md.dw,
                  AppSpacing.sm.dh,
                  AppSpacing.xs.dw,
                  AppSpacing.sm.dh,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs2.dh),
                          Text(
                            <String>[
                              service.provider.businessName,
                              ?category,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs2.dh),
                          RatingLine(
                            avgRating: service.avgRating,
                            ratingCount: service.ratingCount,
                          ),
                        ],
                      ),
                    ),
                    FavouriteButton(
                      target: FavouriteTarget.service(service.id),
                      initial: service.isFavourite,
                      style: FavouriteButtonStyle.inline,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md.dw,
                  vertical: AppSpacing.sm.dh,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            where,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            context.l10n.bookedTimes(service.bookingsCount),
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ServicePrice(
                      amount: service.basePrice,
                      type: service.priceType,
                      amountStyle: textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
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
