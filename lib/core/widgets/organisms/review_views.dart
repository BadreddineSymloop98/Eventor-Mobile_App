import 'package:flutter/material.dart';
// Only DateFormat: intl's own TextDirection would shadow Flutter's.
import 'package:intl/intl.dart' show DateFormat;

import '../../catalog/models/review.dart';
import '../../constants/ui_helpers.dart';
import '../../formatting/rating_format.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_avatar.dart';
import '../atoms/stars_row.dart';

/// The big score above a list of reviews: "4.8 ★★★★★ Based on 32 reviews",
/// then the five bars.
class RatingSummary extends StatelessWidget {
  const RatingSummary({
    required this.avgRating,
    required this.ratingCount,
    this.breakdown = const <RatingBucket>[],
    super.key,
  });

  final String avgRating;
  final int ratingCount;
  final List<RatingBucket> breakdown;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double score = double.tryParse(avgRating) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              formatRating(avgRating),
              textDirection: TextDirection.ltr,
              style: textTheme.displayLarge?.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(width: AppSpacing.sm.dw),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                StarsRow(rating: score, size: AppSizes.iconMd),
                SizedBox(height: AppSpacing.xs2.dh),
                Text(
                  context.l10n.basedOnReviews(ratingCount),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (breakdown.isNotEmpty) ...<Widget>[
          SizedBox(height: AppSpacing.sm.dh),
          for (final RatingBucket bucket in breakdown)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs2.dh),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: AppSpacing.md.dw,
                    child: Text(
                      '${bucket.stars}',
                      textDirection: TextDirection.ltr,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadii.fullAll,
                      child: LinearProgressIndicator(
                        value: bucket.percent / 100,
                        minHeight: AppSpacing.xs.dh,
                        backgroundColor: AppColors.bgDisabled,
                        color: AppColors.ratingFilled,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs.dw),
                  SizedBox(
                    width: AppSpacing.xl.dw,
                    child: Text(
                      '${bucket.count}',
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.end,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// One review: who, when, how many stars, what they said — and the
/// provider's answer when there is one.
class ReviewCard extends StatelessWidget {
  const ReviewCard(this.review, {super.key});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String locale = Localizations.localeOf(context).languageCode;
    final String? reply = review.reply;

    return Container(
      padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(
                name: review.authorName,
                photoUrl: review.authorAvatarUrl,
                size: AppAvatarSize.small,
              ),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      review.authorName,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    // Month and year apart, so the year keeps Western digits.
                    Row(
                      children: <Widget>[
                        Text(
                          DateFormat.MMMM(locale).format(review.createdAt),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs2.dw),
                        Text(
                          '${review.createdAt.year}',
                          textDirection: TextDirection.ltr,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StarsRow(rating: review.rating),
            ],
          ),
          SizedBox(height: AppSpacing.sm.dh),
          Text(
            review.comment,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
          if (reply != null) ...<Widget>[
            SizedBox(height: AppSpacing.sm.dh),
            Container(
              width: double.infinity,
              padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
              decoration: BoxDecoration(
                color: AppColors.bgCanvas,
                borderRadius: AppRadii.smAll,
              ),
              child: Text(
                reply,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
