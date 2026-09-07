import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/localization/app_localizations_x.dart';

/// Row of dots showing which section of a paged flow is active.
///
/// The active step is a pill rather than a larger dot — the design's note on
/// the component is that the width change is what reads at a glance.
///
/// Colours are fixed white rather than themed: this only ever sits on a
/// scrimmed photograph, where the theme's surface colours would be invisible.
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    required this.count,
    required this.currentIndex,
    super.key,
  });

  /// Design-frame sizes. Both axes of a dot come from the width so it stays
  /// round rather than becoming an ellipse on a tall screen.
  static const double _dotSize = 6;
  static const double _activeDotWidth = 20;
  static const Duration _animationDuration = Duration(milliseconds: 200);

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // The dots themselves say nothing useful out loud, so the row as a
      // whole announces the position instead.
      label: context.l10n.sectionProgress(currentIndex + 1, count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(count, (int index) {
            final bool isActive = index == currentIndex;

            return AnimatedContainer(
              duration: _animationDuration,
              margin: EdgeInsetsDirectional.symmetric(
                horizontal: (AppSpacing.xs2 / 2).dw,
              ),
              width: (isActive ? _activeDotWidth : _dotSize).dw,
              height: _dotSize.dw,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.textOnBrand
                    : AppColors.textOnBrand.withValues(alpha: 0.35),
                borderRadius: AppRadii.fullAll,
              ),
            );
          }),
        ),
      ),
    );
  }
}
