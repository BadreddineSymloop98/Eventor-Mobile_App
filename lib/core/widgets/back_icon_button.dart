import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/ui_helpers.dart';
import '../localization/app_localizations_x.dart';

/// The back control used in the top bar of every screen that can be left.
///
/// The glyph is the design's own chevron rather than a Material icon. It is
/// mirrored in Arabic — a chevron is directional, so unlike the top bar it
/// sits in, it *must* follow the text direction or it will point the wrong
/// way out of the screen.
class BackIconButton extends StatelessWidget {
  const BackIconButton({
    this.onPressed,
    this.color = AppColors.iconBrand,
    super.key,
  });

  static const String _icon = 'assets/icons/back.svg';

  /// Defaults to popping the current route.
  final VoidCallback? onPressed;

  /// Colour of the glyph. Defaults to the brand purple, which is right on a
  /// light screen; pass [AppColors.iconOnBrand] when it sits on a photograph
  /// or a brand fill.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      button: true,
      label: context.l10n.backLabel,
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          // The glyph is 24, but the target it sits in is a full tap target.
          height: AppSizes.touchTarget.dh,
          width: AppSizes.touchTarget.dw,
          child: Center(
            child: Transform.flip(
              flipX: isRtl,
              child: SvgPicture.asset(
                _icon,
                width: AppSizes.iconLg.dw,
                height: AppSizes.iconLg.dw,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
