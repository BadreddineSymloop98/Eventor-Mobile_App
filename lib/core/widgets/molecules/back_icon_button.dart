import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';

/// The back control used in the top bar of every screen that can be left.
///
/// The design's `Icon/chevron-left`, mirrored in Arabic — a chevron is
/// directional, so it must follow the text direction or it points the wrong
/// way out of the screen. [AppIcons.chevronLeft] carries that rule itself.
class BackIconButton extends StatelessWidget {
  const BackIconButton({
    this.onPressed,
    this.color = AppColors.iconBrand,
    super.key,
  });

  /// Defaults to popping the current route.
  final VoidCallback? onPressed;

  /// Colour of the glyph. Defaults to the brand purple, which is right on a
  /// light screen; pass [AppColors.iconOnBrand] when it sits on a photograph
  /// or a brand fill.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.backLabel,
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          // The glyph is 24, but the target it sits in is a full tap target.
          // Square on the width axis, like every other square in the app.
          dimension: AppSizes.touchTarget.dw,
          child: Center(child: AppIcon(AppIcons.chevronLeft, color: color)),
        ),
      ),
    );
  }
}
