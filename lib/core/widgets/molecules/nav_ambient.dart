import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';

/// The small piece of life an active nav tab plays while it stays active.
///
/// One signature per filled glyph, each made from detail the glyph already
/// has rather than anything added to it: the door lights up, the lens catches
/// the light, the dates twinkle, the typing dots type, the person breathes.
enum NavAmbient {
  none,
  doorGlow,
  lensGlint,
  dateTwinkle,
  typingDots,
  breath;

  /// The signature that belongs to [glyph] — a tab's active icon.
  static NavAmbient forGlyph(AppIcons? glyph) => switch (glyph) {
        AppIcons.homeFilled => doorGlow,
        AppIcons.searchFilled => lensGlint,
        AppIcons.calendarFilled => dateTwinkle,
        AppIcons.messageFilled => typingDots,
        AppIcons.userFilled => breath,
        _ => none,
      };

  static const double _breathDepth = 0.04;

  /// How much the whole glyph is scaled at [progress] through a cycle. Only
  /// the breath moves the glyph itself; the others paint over it.
  double scaleAt(double progress) {
    if (this != breath || progress <= 0 || progress >= 1) return 1;
    return 1 + _breathDepth * math.sin(math.pi * progress);
  }
}

/// Paints one frame of a [NavAmbient] over its filled glyph.
///
/// Works on the icons' own 24-unit grid, so every shape below is the same
/// coordinates as the cut-out it animates in `assets/icons/*-filled.svg` —
/// change one and the other must follow. Paints nothing between cycles, so a
/// resting tab is exactly the SVG.
class NavAmbientPainter extends CustomPainter {
  const NavAmbientPainter({
    required this.signature,
    required this.progress,
    required this.glyphColor,
    required this.textDirection,
  });

  final NavAmbient signature;

  /// Where the current cycle is, 0 to 1.
  final double progress;

  /// The glyph's own colour, used to cover a cut-out while it moves.
  final Color glyphColor;

  /// Sequences run in reading order: right to left in Arabic.
  final TextDirection textDirection;

  static const double _grid = 24;

  /// What shows through a cut-out: the nav bar is white, so a moved cut-out
  /// is redrawn in the surface colour.
  static const Color _cutout = AppColors.bgSurface;

  /// Warm light on purple — the palette's gold for use on the brand colour.
  static const Color _light = AppColors.iconOnBrandAccent;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    canvas.save();
    canvas.scale(size.width / _grid, size.height / _grid);
    switch (signature) {
      case NavAmbient.doorGlow:
        _paintDoorGlow(canvas);
      case NavAmbient.lensGlint:
        _paintLensGlint(canvas);
      case NavAmbient.dateTwinkle:
        _paintDateTwinkle(canvas);
      case NavAmbient.typingDots:
        _paintTypingDots(canvas);
      case NavAmbient.breath:
      case NavAmbient.none:
        break;
    }
    canvas.restore();
  }

  /// A rise and fall over [length] of the cycle starting at [start]; 0
  /// outside that window.
  double _pulse(double start, double length) {
    final double local = (progress - start) / length;
    if (local <= 0 || local >= 1) return 0;
    return math.sin(math.pi * local);
  }

  /// `home-filled`'s doorway: 4 wide, rounded at the top, open at the sill.
  void _paintDoorGlow(Canvas canvas) {
    final double glow = math.sin(math.pi * Curves.easeInOut.transform(progress));
    final Path door = Path()
      ..moveTo(10, 23)
      ..lineTo(10, 15)
      ..arcToPoint(const Offset(11, 14), radius: const Radius.circular(1))
      ..lineTo(13, 14)
      ..arcToPoint(const Offset(14, 15), radius: const Radius.circular(1))
      ..lineTo(14, 23)
      ..close();
    canvas.drawPath(door, Paint()..color = _light.withValues(alpha: 0.9 * glow));
  }

  /// A soft band of light crossing `search-filled`'s ring and handle
  /// diagonally, clipped to the glyph so it only ever lights the glass rim.
  void _paintLensGlint(Canvas canvas) {
    final Path ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: const Offset(11, 11), radius: 9))
      ..addOval(Rect.fromCircle(center: const Offset(11, 11), radius: 6.25));
    final Path handle = Path()
      ..moveTo(17.6223, 15.6777)
      ..lineTo(21.9723, 20.0277)
      ..arcToPoint(
        const Offset(20.0277, 21.9723),
        radius: const Radius.circular(1.375),
      )
      ..lineTo(15.6777, 17.6223)
      ..close();

    // From beyond the top-left corner to beyond the bottom-right one, so the
    // band enters and leaves the glyph rather than appearing on it.
    final double centre = -4 + 32 * Curves.easeInOut.transform(progress);
    final Paint band = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centre - 3, centre - 3),
        Offset(centre + 3, centre + 3),
        <Color>[
          _cutout.withValues(alpha: 0),
          _cutout.withValues(alpha: 0.55),
          _cutout.withValues(alpha: 0),
        ],
        <double>[0, 0.5, 1],
      );

    canvas.save();
    canvas.clipPath(Path.combine(PathOperation.union, ring, handle));
    canvas.drawRect(const Rect.fromLTWH(0, 0, _grid, _grid), band);
    canvas.restore();
  }

  /// `calendar-filled`'s five date cells, lit gold one after another.
  void _paintDateTwinkle(Canvas canvas) {
    const List<Offset> firstRow = <Offset>[
      Offset(6, 13),
      Offset(10.75, 13),
      Offset(15.5, 13),
    ];
    const List<Offset> secondRow = <Offset>[
      Offset(6, 17.5),
      Offset(10.75, 17.5),
    ];
    final bool rtl = textDirection == TextDirection.rtl;
    final List<Offset> order = <Offset>[
      ...(rtl ? firstRow.reversed : firstRow),
      ...(rtl ? secondRow.reversed : secondRow),
    ];

    for (int i = 0; i < order.length; i++) {
      final double glow = _pulse(i * 0.14, 0.36);
      if (glow == 0) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          order[i] & const Size(2.5, 2.5),
          const Radius.circular(0.75),
        ),
        Paint()..color = _light.withValues(alpha: glow),
      );
    }
  }

  /// `message-filled`'s three dots, rising and falling in turn like someone
  /// typing. Each moving dot's own hole is covered in the glyph's colour and
  /// the dot redrawn higher.
  void _paintTypingDots(Canvas canvas) {
    const List<Offset> dots = <Offset>[
      Offset(8, 11.5),
      Offset(12, 11.5),
      Offset(16, 11.5),
    ];
    final List<Offset> order = textDirection == TextDirection.rtl
        ? dots.reversed.toList()
        : dots;
    final Paint cover = Paint()..color = glyphColor;
    final Paint dot = Paint()..color = _cutout;

    for (int i = 0; i < order.length; i++) {
      final double lift = 1.6 * _pulse(i * 0.18, 0.46);
      if (lift == 0) continue;
      // A touch wider than the 1.25 hole, so no sliver of its edge survives.
      canvas.drawCircle(order[i], 1.55, cover);
      canvas.drawCircle(order[i] - Offset(0, lift), 1.25, dot);
    }
  }

  @override
  bool shouldRepaint(NavAmbientPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.signature != signature ||
      oldDelegate.glyphColor != glyphColor ||
      oldDelegate.textDirection != textDirection;
}
