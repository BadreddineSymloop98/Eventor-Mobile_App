import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';
import 'nav_ambient.dart';

/// One destination in the bottom navigation — the design's `Nav Item`.
///
/// Icon over label, grey outline when idle and a brand-filled glyph when
/// active, with an optional red count badge pinned to the icon's top-end
/// corner.
///
/// Becoming active is a small piece of choreography rather than a colour
/// swap: the icon squashes under the finger, cross-fades from its outline to
/// its filled twin while it pops past full size and springs back, and icon
/// and label fade from grey to brand together. Leaving is a plain fade back,
/// so the eye stays on the tab that was chosen.
///
/// While it stays active, a tab whose glyph has a [NavAmbient] signature
/// plays it once every few seconds — a short cycle, then a long rest, so the
/// bar feels alive without ever holding the eye. With the system's "reduce
/// motion" setting on, every state change is instant and nothing loops.
class NavItem extends StatefulWidget {
  const NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeIcon,
    this.badgeCount = 0,
    super.key,
  });

  /// The idle glyph — the design's outline.
  final AppIcons icon;

  /// The glyph drawn while active, such as [AppIcons.homeFilled]. `null`
  /// keeps [icon] in both states, so only the colour changes.
  final AppIcons? activeIcon;

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  /// Unread items behind this destination. `0` hides the badge.
  final int badgeCount;

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> with TickerProviderStateMixin {
  /// Counts above this read as "9+" so the badge stays a circle.
  static const int _maxBadge = 9;
  static const double _badgeSize = 16;

  // The press registers before the finger lifts; the fill-in is quick enough
  // to feel like a response rather than a transition; the fill-out is quicker
  // still, because nobody is looking at the tab being left.
  static const Duration _pressDuration = Duration(milliseconds: 80);
  static const Duration _fillInDuration = Duration(milliseconds: 200);
  static const Duration _fillOutDuration = Duration(milliseconds: 150);
  static const Duration _popDuration = Duration(milliseconds: 320);

  static const double _pressedScale = 0.9;

  /// How far past full size the icon overshoots when it becomes active.
  static const double _selectPeak = 1.12;

  /// A gentler pop for tapping the tab that is already active — it answers
  /// the tap without pretending anything changed.
  static const double _repeatPeak = 1.06;

  // The signature waits for the selection to settle before its first cycle,
  // then rests far longer than it moves: motion that never stops in the
  // corner of the eye stops being subtle.
  static const Duration _ambientDelay = Duration(milliseconds: 900);
  static const Duration _ambientCycle = Duration(milliseconds: 1600);
  static const Duration _ambientRest = Duration(milliseconds: 4400);

  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: _pressDuration,
  );

  /// 0 is the grey outline, 1 the brand-filled glyph.
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: _fillInDuration,
    reverseDuration: _fillOutDuration,
    value: widget.isActive ? 1 : 0,
  );

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: _popDuration,
  );

  /// One cycle of the tab's [NavAmbient] signature, 0 to 1.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: _ambientCycle,
  )..addStatusListener(_onAmbientStatus);

  /// The wait before the next cycle. A timer rather than a longer animation,
  /// so nothing asks for frames while the tab rests.
  Timer? _ambientTimer;

  late final Listenable _motion = Listenable.merge(
    <Listenable>[_press, _fill, _pop, _ambient],
  );

  double _popPeak = _selectPeak;

  /// Kept from the last dependency change, so the gesture callbacks and
  /// [didUpdateWidget] do not look the setting up outside of a build.
  bool _reduceMotion = false;

  NavAmbient get _signature => NavAmbient.forGlyph(widget.activeIcon);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) {
      _stopAmbient();
    } else if (widget.isActive &&
        _ambientTimer == null &&
        !_ambient.isAnimating) {
      // Active from the start — the app opening on this tab.
      _scheduleAmbient(_ambientDelay);
    }
  }

  @override
  void didUpdateWidget(NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    // Driven by the state rather than the tap, so a tab that becomes active
    // any other way — a deep link, a redirect — gets the same motion.
    widget.isActive ? _activate() : _deactivate();
  }

  void _activate() {
    if (_reduceMotion) {
      _fill.value = 1;
      return;
    }
    _fill.forward();
    _popPeak = _selectPeak;
    _pop.forward(from: 0);
    _scheduleAmbient(_ambientDelay);
  }

  void _deactivate() {
    _stopAmbient();
    _pop.value = 0;
    if (_reduceMotion) {
      _fill.value = 0;
      return;
    }
    _fill.reverse();
  }

  void _scheduleAmbient(Duration after) {
    _ambientTimer?.cancel();
    _ambientTimer = null;
    if (!widget.isActive || _reduceMotion) return;
    if (_signature == NavAmbient.none) return;
    _ambientTimer = Timer(after, () {
      _ambientTimer = null;
      if (mounted && widget.isActive) _ambient.forward(from: 0);
    });
  }

  void _onAmbientStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // Back to rest, so the painter draws nothing until the next cycle.
    _ambient.value = 0;
    _scheduleAmbient(_ambientRest);
  }

  void _stopAmbient() {
    _ambientTimer?.cancel();
    _ambientTimer = null;
    _ambient
      ..stop()
      ..value = 0;
  }

  void _handleTap() {
    if (widget.isActive) {
      if (!_reduceMotion) {
        _popPeak = _repeatPeak;
        _pop.forward(from: 0);
      }
    } else {
      // The same light tick the buttons give; only for a real change of tab.
      HapticFeedback.selectionClick();
    }
    widget.onTap();
  }

  void _setPressed(bool isPressed) {
    if (_reduceMotion) return;
    isPressed ? _press.forward() : _press.reverse();
  }

  /// The icon's scale for the current frame: the press squash, the pop, and
  /// the breath of a signature that moves the whole glyph.
  double get _scale {
    final double press = 1 -
        (1 - _pressedScale) * Curves.easeOut.transform(_press.value);
    return press *
        _popScale(_pop.value) *
        _signature.scaleAt(_ambient.value);
  }

  /// Up to the peak over the first 40%, then a spring back to rest that
  /// dips just under full size before it settles.
  double _popScale(double t) {
    if (t <= 0 || t >= 1) return 1;
    const double rise = 0.4;
    if (t < rise) {
      return 1 + (_popPeak - 1) * Curves.easeOutCubic.transform(t / rise);
    }
    final double settle = Curves.easeOutBack.transform((t - rise) / (1 - rise));
    return _popPeak + (1 - _popPeak) * settle;
  }

  /// Exact at both ends, so a settled tab reads the palette's own colours.
  static Color _blend(Color idle, Color active, double t) {
    if (t <= 0) return idle;
    if (t >= 1) return active;
    return Color.lerp(idle, active, t)!;
  }

  @override
  void dispose() {
    _ambientTimer?.cancel();
    _press.dispose();
    _fill.dispose();
    _pop.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle = Theme.of(context).textTheme.labelMedium;
    final TextDirection direction = Directionality.of(context);
    final AppIcons? activeIcon = widget.activeIcon;

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: widget.badgeCount > 0
          ? '${widget.label}, ${widget.badgeCount}'
          : widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs2.dh),
          child: AnimatedBuilder(
            animation: _motion,
            builder: (BuildContext context, Widget? child) {
              final double fill = Curves.easeOut.transform(_fill.value);
              final Color iconColor =
                  _blend(AppColors.iconDefault, AppColors.iconBrand, fill);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Transform.scale(
                        scale: _scale,
                        child: activeIcon == null
                            ? AppIcon(widget.icon, color: iconColor)
                            // Both glyphs share one silhouette, so a straight
                            // cross-fade reads as the outline filling in.
                            : CustomPaint(
                                foregroundPainter: NavAmbientPainter(
                                  signature: _signature,
                                  progress: _ambient.value,
                                  glyphColor: iconColor,
                                  textDirection: direction,
                                ),
                                child: Stack(
                                  children: <Widget>[
                                    Opacity(
                                      opacity: 1 - fill,
                                      child: AppIcon(
                                        widget.icon,
                                        color: iconColor,
                                      ),
                                    ),
                                    Opacity(
                                      opacity: fill,
                                      child: AppIcon(
                                        activeIcon,
                                        color: iconColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      // Outside the scale: a count that pulses with the icon
                      // reads as a new notification.
                      if (widget.badgeCount > 0)
                        PositionedDirectional(
                          top: -AppSpacing.xs2.dw,
                          end: -AppSpacing.xs.dw,
                          child: _Badge(
                            count: widget.badgeCount,
                            size: _badgeSize,
                            max: _maxBadge,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs2.dh),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle?.copyWith(
                      color: _blend(
                        AppColors.textSecondary,
                        AppColors.textBrand,
                        fill,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.size, required this.max});

  final int count;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: size.dw, minHeight: size.dw),
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs2.dw),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.bgDanger,
        borderRadius: AppRadii.fullAll,
        // A white ring separates the badge from the icon it overlaps.
        border: Border.all(color: AppColors.bgSurface, width: 1.5),
      ),
      child: Text(
        count > max ? '$max+' : '$count',
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textOnDanger,
              height: 1,
            ),
      ),
    );
  }
}
