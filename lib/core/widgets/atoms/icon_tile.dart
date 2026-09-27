import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import 'app_icon.dart';

/// A brand icon on the design's pale purple gradient tile.
///
/// One widget for the design's two components of this shape:
/// `Icon Container` (40pt, used beside list rows) and `Service Thumb` (48pt,
/// standing in for a service photo). Both are the same gradient, hairline and
/// 12pt corner around a 24pt icon; only the size differs.
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    this.size = containerSize,
    this.muted = false,
    super.key,
  });

  /// `Service Thumb` — a service without a photo yet.
  const IconTile.serviceThumb(this.icon, {super.key})
      : size = thumbSize,
        muted = false;

  /// `Icon Container`.
  static const double containerSize = 40;

  /// `Service Thumb`.
  static const double thumbSize = 48;

  final AppIcons icon;

  /// Design pixels.
  final double size;

  /// Grey instead of purple — something not settled yet, like a budget line
  /// with no booking (18).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final double side = size.dw;

    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadii.mdAll,
        color: muted ? AppColors.bgCanvas : null,
        border: Border.all(
          color: muted ? AppColors.borderDefault : AppColors.tileBorder,
        ),
        // Top-start to bottom-end, following the design's diagonal.
        gradient: muted
            ? null
            : const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: <Color>[
            AppColors.tileGradientStart,
            AppColors.tileGradientEnd,
          ],
        ),
      ),
      child: AppIcon(
        icon,
        color: muted ? AppColors.iconDefault : AppColors.iconBrand,
      ),
    );
  }
}
