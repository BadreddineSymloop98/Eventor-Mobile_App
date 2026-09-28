import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// A box with a dashed hairline — the design's "nothing here yet, add one"
/// cards (11c's budget invitation, 18c's empty expense list).
///
/// The dash is drawn rather than bordered: Flutter has no dashed `Border`.
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    required this.child,
    this.padding,
    this.color = AppColors.bgSurface,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// The fill inside the dashes.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedRRectPainter(),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(color: color, borderRadius: AppRadii.lgAll),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter();

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.borderDefault
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Half a stroke in, so the line sits inside the box like a border would.
    final RRect shape = AppRadii.lgAll
        .resolve(TextDirection.ltr)
        .toRRect(Offset.zero & size)
        .deflate(0.5);
    for (final PathMetric metric in (Path()..addRRect(shape)).computeMetrics()) {
      for (double at = 0; at < metric.length; at += _dash + _gap) {
        canvas.drawPath(metric.extractPath(at, at + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) => false;
}
