import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';
import '../molecules/nav_item.dart';

/// One tab of an [AppBottomNav].
class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badgeCount = 0,
  });

  /// The idle outline.
  final AppIcons icon;

  /// The filled glyph shown while this tab is active — see [NavItem].
  final AppIcons? activeIcon;

  final String label;
  final int badgeCount;
}

/// The tab bar along the bottom of a signed-in screen — the design's
/// `Bottom Nav`.
///
/// White, hairline on top, equal-width [NavItem]s, and a 32×3 brand
/// indicator that travels to the active tab. Per the design's RTL rules the
/// *order* of the tabs does not reverse in Arabic — the same tab sits in the
/// same place in both languages; only the labels translate.
///
/// The indicator moves like a drop of ink rather than a sliding block: its
/// leading edge sets off first and reaches the new tab early, its trailing
/// edge follows and catches up, so it stretches across the gap and snaps
/// back to 32 on arrival. With "reduce motion" on it simply jumps.
class AppBottomNav extends StatefulWidget {
  const AppBottomNav({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  /// Finds the indicator in a test.
  @visibleForTesting
  static const Key indicatorKey = ValueKey<String>('appBottomNavIndicator');

  final List<AppNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  static const double _indicatorWidth = 32;
  static const double _indicatorHeight = 3;
  static const Duration _travel = Duration(milliseconds: 380);

  // The leading edge covers the distance in the first two thirds of the
  // travel; the trailing edge waits a beat, then eases in behind it. The gap
  // between the two curves is the stretch.
  static const Curve _leading = Interval(0, 0.65, curve: Curves.easeOutCubic);
  static const Curve _trailing = Interval(
    0.25,
    1,
    curve: Curves.easeInOutCubic,
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _travel,
    value: 1,
  );

  // Where each edge of the indicator set off from, in tab units: tab `i`
  // puts both edges at `i`. Kept as edges rather than an index so a tap
  // mid-travel sets off from where the indicator actually is.
  late double _fromStart = widget.currentIndex.toDouble();
  late double _fromEnd = widget.currentIndex.toDouble();

  bool _reduceMotion = false;

  @override
  void didUpdateWidget(AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == oldWidget.currentIndex) return;

    final (double start, double end) = _edgesFor(oldWidget.currentIndex);
    _fromStart = start;
    _fromEnd = end;
    if (_reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  /// Both edges for the current frame of a trip towards [target].
  (double, double) _edgesFor(int target) {
    final double to = target.toDouble();
    final double t = _controller.value;
    if (t >= 1) return (to, to);

    // Whichever edge faces the destination leads.
    final bool towardsEnd = to >= (_fromStart + _fromEnd) / 2;
    final double startProgress =
        (towardsEnd ? _trailing : _leading).transform(t);
    final double endProgress =
        (towardsEnd ? _leading : _trailing).transform(t);
    return (
      _fromStart + (to - _fromStart) * startProgress,
      _fromEnd + (to - _fromEnd) * endProgress,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // Read before the row is pinned left to right below, so each tab can hand
    // its own content the app's real direction back.
    final TextDirection appDirection = Directionality.of(context);
    final List<AppNavDestination> destinations = widget.destinations;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        // Pinned left to right: the tab order is fixed across languages.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double slot = constraints.maxWidth / destinations.length;
              final double indicatorWidth = _indicatorWidth.dw;

              return Stack(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.dh),
                    child: Row(
                      children: <Widget>[
                        for (int i = 0; i < destinations.length; i++)
                          Expanded(
                            // Each tab's own content still follows the app's
                            // language — only the row order is pinned.
                            child: Directionality(
                              textDirection: appDirection,
                              child: NavItem(
                                icon: destinations[i].icon,
                                activeIcon: destinations[i].activeIcon,
                                label: destinations[i].label,
                                badgeCount: destinations[i].badgeCount,
                                isActive: i == widget.currentIndex,
                                onTap: () => widget.onSelected(i),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, Widget? child) {
                      final (double start, double end) =
                          _edgesFor(widget.currentIndex);
                      // At rest both edges sit on the tab, so the width is
                      // the design's 32; in flight it grows by the gap.
                      final double stretch = (end - start).abs() * slot;
                      final double leftEdge = start < end ? start : end;
                      return Positioned(
                        top: 0,
                        left: leftEdge * slot + (slot - indicatorWidth) / 2,
                        width: indicatorWidth + stretch,
                        height: _indicatorHeight,
                        child: child!,
                      );
                    },
                    child: DecoratedBox(
                      key: AppBottomNav.indicatorKey,
                      decoration: BoxDecoration(
                        color: AppColors.bgBrand,
                        borderRadius: AppRadii.fullAll,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
