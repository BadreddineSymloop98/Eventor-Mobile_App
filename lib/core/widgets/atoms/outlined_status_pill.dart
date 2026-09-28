import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// A white pill outlined, dotted and lettered in one status colour — the
/// hand-built status pills of section 10 that have no `Status Badge`
/// variant: a pack's Published / Draft / Unpublished, and a photo's Cover /
/// Processing badges ([compact], no dot).
class OutlinedStatusPill extends StatelessWidget {
  const OutlinedStatusPill({
    required this.label,
    required this.color,
    this.compact = false,
    super.key,
  });

  static const double _dotSize = 6;

  final String label;
  final Color color;

  /// The photo badge: 8/2 padding and no dot.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: (compact ? AppSpacing.xs : AppSpacing.sm).dw,
        vertical: compact ? 2.dh : AppSpacing.xs2.dh,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!compact) ...<Widget>[
            Container(
              width: _dotSize.dw,
              height: _dotSize.dw,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: AppSpacing.xs2.dw),
          ],
          Text(
            label,
            style: (compact ? textTheme.labelSmall : textTheme.labelMedium)
                ?.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
