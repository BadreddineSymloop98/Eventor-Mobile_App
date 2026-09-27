import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../catalog/favourites_controller.dart';
import '../../catalog/models/favourite.dart';
import '../../constants/ui_helpers.dart';
import '../../errors/failure.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import 'app_toast.dart';

/// Where a [FavouriteButton] sits.
enum FavouriteButtonStyle {
  /// A white disc over a photograph — cards and galleries.
  onPhoto,

  /// A bare heart beside text — result rows.
  inline,
}

/// The heart. Fills at once when tapped; if the server refuses, it empties
/// again and says so.
///
/// Reads [FavouritesController], so a heart changed on one screen shows the
/// same on every other.
class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    required this.target,
    required this.initial,
    this.style = FavouriteButtonStyle.onPhoto,
    super.key,
  });

  final FavouriteTarget target;

  /// The card's own `isFavourite`, used until the heart is tapped.
  final bool initial;
  final FavouriteButtonStyle style;

  static const double _discSize = 40;

  Future<void> _toggle(BuildContext context, bool current) async {
    HapticFeedback.selectionClick();
    final String failed = context.l10n.favouriteFailed;
    final Failure? failure = await context
        .read<FavouritesController>()
        .toggle(target, current: current);
    if (failure != null && context.mounted) {
      showAppToast(context, failed, tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSaved = context
        .watch<FavouritesController>()
        .isFavourite(target, fallback: initial);
    final Widget heart = AppIcon(
      isSaved ? AppIcons.heartFilled : AppIcons.heart,
      size: style == FavouriteButtonStyle.onPhoto
          ? AppSizes.iconMd
          : AppSizes.iconLg,
      color: isSaved ? AppColors.iconBrand : AppColors.iconDefault,
    );

    return Semantics(
      button: true,
      toggled: isSaved,
      label: isSaved ? context.l10n.favouriteSaved : context.l10n.favouriteSave,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _toggle(context, isSaved),
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: AppSizes.touchTarget.dw,
          child: Center(
            child: style == FavouriteButtonStyle.onPhoto
                ? Container(
                    width: _discSize.dw,
                    height: _discSize.dw,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      shape: BoxShape.circle,
                      boxShadow: AppElevation.sm,
                    ),
                    child: heart,
                  )
                : heart,
          ),
        ),
      ),
    );
  }
}
