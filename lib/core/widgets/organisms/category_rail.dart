import 'package:flutter/material.dart';

import '../../catalog/models/catalog_ref.dart';
import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';
import '../atoms/category_icon.dart';

/// Home's row of category discs — a 56pt white circle with the brand glyph,
/// the name beneath. Scrolls sideways and runs off the edge, as drawn, so it
/// reads as "there is more".
class CategoryRail extends StatelessWidget {
  const CategoryRail({required this.categories, required this.onTap, super.key});

  final List<CategoryRef> categories;
  final ValueChanged<CategoryRef> onTap;

  static const double _disc = 56;
  static const double _itemWidth = 76;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;

    return SizedBox(
      height: (_disc + 32).dh,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
        itemCount: categories.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.xs.dw),
        itemBuilder: (BuildContext context, int index) {
          final CategoryRef category = categories[index];
          return Semantics(
            button: true,
            child: GestureDetector(
              onTap: () => onTap(category),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: _itemWidth.dw,
                child: Column(
                  children: <Widget>[
                    Container(
                      width: _disc.dw,
                      height: _disc.dw,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: AppIcon(
                        categoryIcon(category.icon),
                        color: AppColors.iconBrand,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs.dh),
                    Text(
                      category.name.of(language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
