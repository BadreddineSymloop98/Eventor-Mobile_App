import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import 'app_icon.dart';

/// A filled star, the score, and optionally how many reviews it rests on —
/// the design's `Rating`.
///
/// Laid out as a row of separate pieces rather than one interpolated string,
/// so the score and the count keep their own direction inside Arabic copy
/// (the standing rule on numbers inside Arabic text).
class RatingView extends StatelessWidget {
  const RatingView({
    required this.score,
    this.count,
    super.key,
  });

  /// Already formatted for display, one decimal — `4.8`. A string because the
  /// API sends ratings as strings, and re-formatting a double here would be a
  /// second place to disagree about rounding.
  final String score;

  /// Number of reviews, or `null` to show the score alone.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int? reviews = count;

    return Semantics(
      label: reviews == null
          ? context.l10n.ratingLabel(score)
          : context.l10n.ratingWithCountLabel(score, reviews),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIcon(
              AppIcons.starFilled,
              size: AppSizes.iconSm,
              color: AppColors.ratingFilled,
            ),
            SizedBox(width: AppSpacing.xs2.dw),
            Text(
              score,
              textDirection: TextDirection.ltr,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (reviews != null) ...<Widget>[
              SizedBox(width: AppSpacing.xs2.dw),
              Text(
                context.l10n.reviewCount(reviews),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
