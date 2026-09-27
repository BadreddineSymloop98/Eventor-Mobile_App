import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import 'app_icon.dart';

/// Five stars, the first [rating] of them filled (rounded to the nearest
/// whole star). Decorative: the number beside it is what is read out.
class StarsRow extends StatelessWidget {
  const StarsRow({required this.rating, this.size = AppSizes.iconSm, super.key});

  final num rating;

  /// Design pixels per star.
  final double size;

  @override
  Widget build(BuildContext context) {
    final int filled = rating.round().clamp(0, 5);

    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < 5; i++)
            AppIcon(
              i < filled ? AppIcons.starFilled : AppIcons.star,
              size: size,
              color: i < filled ? AppColors.ratingFilled : AppColors.ratingEmpty,
            ),
        ],
      ),
    );
  }
}
