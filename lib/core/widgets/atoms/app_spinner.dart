import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import 'app_icon.dart';

/// The design's `Icon/spinner` — a three-quarter arc, turning.
///
/// Used wherever the design shows work in progress inside a control: a
/// loading button, a document that is uploading. Drawn from the same glyph as
/// the design rather than a Material progress indicator, so it has the
/// design's weight and gap.
class AppSpinner extends StatefulWidget {
  const AppSpinner({
    this.size = AppSizes.iconLg,
    this.color = AppColors.iconBrand,
    super.key,
  });

  /// Design pixels.
  final double size;
  final Color color;

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  /// One full turn.
  static const Duration _period = Duration(milliseconds: 900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  )..repeat();

  @override
  Widget build(BuildContext context) {
    // A spinner is progress, not content: screen readers get the label of the
    // control it sits in instead.
    return ExcludeSemantics(
      child: RotationTransition(
        turns: _controller,
        child: AppIcon(
          AppIcons.spinner,
          size: widget.size,
          color: widget.color,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
