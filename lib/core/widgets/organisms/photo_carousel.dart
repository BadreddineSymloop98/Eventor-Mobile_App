import 'package:flutter/material.dart';

import '../../catalog/models/photo.dart';
import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_network_image.dart';

/// The swipeable gallery at the top of 12 and 20, with its "1 / 12" counter
/// and whatever floats over it (Back, the heart).
///
/// A soft dark gradient across the top keeps white controls legible on any
/// photo. With no photos it shows the category's placeholder tile, once.
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({
    required this.photos,
    required this.height,
    required this.overlay,
    this.placeholderIcon = AppIcons.camera,
    super.key,
  });

  final List<Photo> photos;

  /// Logical pixels, already converted.
  final double height;

  /// Laid over the photos, top to bottom — the back button and the heart.
  final Widget overlay;
  final AppIcons placeholderIcon;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Photo> photos = widget.photos;

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (photos.isEmpty)
            AppNetworkImage(
              url: null,
              height: widget.height,
              placeholderIcon: widget.placeholderIcon,
            )
          else
            PageView.builder(
              itemCount: photos.length,
              onPageChanged: (int index) => setState(() => _index = index),
              itemBuilder: (BuildContext context, int index) => AppNetworkImage(
                url: photos[index].mediumUrl,
                height: widget.height,
                placeholderIcon: widget.placeholderIcon,
              ),
            ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: <Color>[
                    AppColors.scrimDeep.withValues(alpha: 0.45),
                    AppColors.scrimDeep.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          if (photos.length > 1)
            PositionedDirectional(
              end: AppSpacing.md.dw,
              bottom: AppSpacing.md.dh,
              child: Semantics(
                label: context.l10n.photoCounterLabel(_index + 1, photos.length),
                excludeSemantics: true,
                child: Container(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.xs.dw,
                    vertical: AppSpacing.xs2.dh,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.scrimDeep.withValues(alpha: 0.6),
                    borderRadius: AppRadii.fullAll,
                  ),
                  child: Text(
                    '${_index + 1} / ${photos.length}',
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textOnBrand,
                        ),
                  ),
                ),
              ),
            ),
          widget.overlay,
        ],
      ),
    );
  }
}

/// The round white Back button that floats over a photo.
class PhotoBackButton extends StatelessWidget {
  const PhotoBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  static const double _discSize = 40;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.backLabelOnPhoto,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: AppSizes.touchTarget.dw,
          child: Center(
            child: Container(
              width: _discSize.dw,
              height: _discSize.dw,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                shape: BoxShape.circle,
                boxShadow: AppElevation.sm,
              ),
              child: AppIcon(
                AppIcons.chevronLeft,
                size: AppSizes.iconMd,
                color: AppColors.iconBrand,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
