import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../formatting/rating_format.dart';
import '../../localization/app_localizations_x.dart';
import 'app_icon.dart';
import 'rating_view.dart';

/// A rating, or "New" when nobody has reviewed yet.
///
/// The API reports an unrated item as `"0.00"` from 0 reviews; zero stars
/// would read as bad, not as new.
class RatingLine extends StatelessWidget {
  const RatingLine({
    required this.avgRating,
    required this.ratingCount,
    this.showCount = true,
    super.key,
  });

  /// The API's string — `"4.80"`.
  final String avgRating;
  final int ratingCount;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    if (ratingCount > 0) {
      return RatingView(
        score: formatRating(avgRating),
        count: showCount ? ratingCount : null,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppIcon(AppIcons.star, size: AppSizes.iconSm, color: AppColors.iconAccent),
        SizedBox(width: AppSpacing.xs2.dw),
        Text(
          context.l10n.ratingNew,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textAccent,
              ),
        ),
      ],
    );
  }
}
