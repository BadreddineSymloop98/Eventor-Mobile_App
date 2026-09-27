import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';

/// One figure in a [StatStrip] — "4.8 · 32 reviews".
class StatItem {
  const StatItem({required this.value, required this.label, this.icon});

  /// Kept left to right, so digits never reorder inside Arabic copy.
  final String value;
  final String label;

  /// Before the value — the star beside a rating.
  final AppIcons? icon;
}

/// Figures side by side with hairlines between them — 13's
/// "★4.8 · 48 bookings completed · 6 yrs in business".
class StatStrip extends StatelessWidget {
  const StatStrip(this.items, {super.key});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0)
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.borderDefault,
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (items[i].icon case final AppIcons icon) ...<Widget>[
                        AppIcon(
                          icon,
                          size: AppSizes.iconSm,
                          color: AppColors.ratingFilled,
                        ),
                        SizedBox(width: AppSpacing.xs2.dw),
                      ],
                      Text(
                        items[i].value,
                        textDirection: TextDirection.ltr,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs2.dh),
                  Text(
                    items[i].label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
