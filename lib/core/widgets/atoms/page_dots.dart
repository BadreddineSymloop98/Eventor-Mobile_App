import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';

/// What the dots sit on, which decides their colours.
enum PageDotsTone {
  /// On a light surface: brand for the current step, grey for the rest — the
  /// component as the design draws it.
  normal,

  /// On a scrimmed photograph: white for the current step, white at 35% for
  /// the rest — how the onboarding screens override it.
  inverse,
}

/// Row of dots showing which step of a paged flow is active — the design's
/// `Page Dots`.
///
/// The active step is a 20pt pill rather than a larger dot; the width change
/// is what reads at a glance.
class PageDots extends StatelessWidget {
  const PageDots({
    required this.count,
    required this.currentIndex,
    this.tone = PageDotsTone.normal,
    super.key,
  });

  /// Design-frame sizes. Both axes of a dot come from the width so it stays
  /// round rather than becoming an ellipse on a tall screen.
  static const double _dotSize = 6;
  static const double _activeDotWidth = 20;
  static const Duration _animationDuration = Duration(milliseconds: 200);

  final int count;
  final int currentIndex;
  final PageDotsTone tone;

  @override
  Widget build(BuildContext context) {
    final bool isInverse = tone == PageDotsTone.inverse;
    final Color active = isInverse ? AppColors.textOnBrand : AppColors.bgBrand;
    final Color inactive = isInverse
        ? AppColors.textOnBrand.withValues(alpha: 0.35)
        : AppColors.bgDisabled;

    return Semantics(
      // The dots themselves say nothing useful out loud, so the row as a
      // whole announces the position instead.
      label: context.l10n.sectionProgress(currentIndex + 1, count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
                color: isActive ? active : inactive,
                borderRadius: AppRadii.fullAll,
              ),
            );
          }),
        ),
      ),
    );
  }
}
