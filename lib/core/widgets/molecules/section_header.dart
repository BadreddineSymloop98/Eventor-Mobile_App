import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// A section title with an optional link on the far side — "Ready Packs ·
/// See all".
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? label = actionLabel;
    final VoidCallback? action = onAction;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ),
        if (label != null && action != null)
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: action,
              behavior: HitTestBehavior.opaque,
              // A full touch target around a small link.
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: AppSizes.touchTarget.dh),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: AppSpacing.sm.dw),
                  child: Align(
                    widthFactor: 1,
                    child: Text(
                      label,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textBrand,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
