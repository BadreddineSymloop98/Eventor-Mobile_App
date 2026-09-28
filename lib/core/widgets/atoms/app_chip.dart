import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// A pill-shaped filter or choice — the design's `Chip`.
///
/// Three states: default (outlined, grey label), selected (brand fill, white
/// label) and disabled (grey fill). A 36pt control; its tap area is extended to
/// the 48pt minimum around it without changing how it is drawn.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;

  /// `null` renders the chip disabled.
  final VoidCallback? onTap;

  bool get _isEnabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final Color background = !_isEnabled
        ? AppColors.bgDisabled
        : isSelected
            ? AppColors.bgBrand
            : AppColors.bgSurface;
    final Color foreground = isSelected && _isEnabled
        ? AppColors.textOnBrand
        : AppColors.textSecondary;
    final bool hasBorder = !isSelected || !_isEnabled;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: _isEnabled,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: AppSizes.touchTarget.dh),
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: AppSizes.controlSm.dh,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadii.fullAll,
                border: hasBorder
                    ? Border.all(color: AppColors.borderDefault)
                    : null,
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
