import 'package:flutter/material.dart';

import '../../catalog/models/catalog_models.dart';
import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_network_image.dart';
import '../atoms/category_icon.dart';
import '../molecules/price_text.dart';

/// One saved item in 17's grid: photo with a filled heart, title, provider,
/// "From X DA".
///
/// A service or pack that stopped being listed stays in the grid, faded,
/// saying so — it cannot be opened, but it can still be removed.
class FavouriteTile extends StatelessWidget {
  const FavouriteTile(
    this.favourite, {
    required this.onRemove,
    this.onTap,
    super.key,
  });

  final Favourite favourite;
  final VoidCallback onRemove;

  /// Ignored for an item that is no longer available.
  final VoidCallback? onTap;

  static const double _photoHeight = 110;
  static const double _discSize = 30;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final bool available = favourite.available;

    return Semantics(
      button: available,
      child: GestureDetector(
        onTap: available ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadii.lgAll,
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppElevation.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: _photoHeight.dh,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Opacity(
                      opacity: available ? 1 : 0.4,
                      child: AppNetworkImage(
                        url: favourite.coverUrl,
                        height: _photoHeight.dh,
                        placeholderIcon: favourite.kind == FavouriteKind.pack
                            ? AppIcons.layers
                            : categoryIcon(favourite.category?.icon),
                      ),
                    ),
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: Semantics(
                        button: true,
                        label: context.l10n.favouriteSaved,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: onRemove,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox.square(
                            dimension: AppSizes.touchTarget.dw,
                            child: Center(
                              child: Container(
                                width: _discSize.dw,
                                height: _discSize.dw,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.bgSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: AppIcon(
                                  AppIcons.heartFilled,
                                  size: AppSizes.iconSm,
                                  color: AppColors.iconBrand,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      favourite.title.of(language),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: available ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs2.dh),
                    Text(
                      favourite.providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: AppSpacing.xs.dh),
                    if (available)
                      PriceText(
                        amount: favourite.fromPrice,
                        prefix: context.l10n.priceFrom,
                        amountStyle: textTheme.labelLarge?.copyWith(color: AppColors.textBrand),
                        labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.textBrand),
                      )
                    else
                      Text(
                        context.l10n.noLongerAvailable,
                        style: textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
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
