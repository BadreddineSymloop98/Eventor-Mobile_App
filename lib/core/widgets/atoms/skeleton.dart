import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// A grey block standing in for content that is loading — the design's G1.
///
/// Screens draw these in the shape of what is coming instead of showing a
/// spinner, so the layout does not jump when the content arrives. Hidden from
/// screen readers: there is nothing to read yet.
class Skeleton extends StatelessWidget {
  const Skeleton({
    required this.height,
    this.width,
    this.radius = AppRadii.mdAll,
    super.key,
  });

  /// Logical pixels — already converted by the caller.
  final double height;

  /// Fills the width available when `null`.
  final double? width;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.bgDisabled,
          borderRadius: radius,
        ),
      ),
    );
  }
}
