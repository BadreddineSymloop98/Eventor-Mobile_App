import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// How a photograph is darkened so that content can sit on top of it.
///
/// The design uses two treatments, and the difference is deliberate.
enum PhotoScrimTone {
  /// Purple. Only the splash, where the brand *is* the content.
  brand,

  /// Near-black. Every other photographic screen, where the copy is the
  /// content and a purple cast would fight the photograph.
  neutral,
}

/// A full-bleed photograph with the scrims that make content legible over it.
///
/// Used by every pre-auth screen that sits on an image. The layering is always
/// the same — photograph, a flat wash, a top-to-bottom gradient, then a
/// lighter wash across the top — and only the colours change with [tone].
class PhotoBackdrop extends StatelessWidget {
  const PhotoBackdrop({
    required this.asset,
    this.tone = PhotoScrimTone.neutral,
    super.key,
  });

  /// Height of the top wash in the design frame.
  static const double _topScrimDesignHeight = 220;

  /// Path of the image to draw.
  final String asset;

  final PhotoScrimTone tone;

  bool get _isBrand => tone == PhotoScrimTone.brand;

  /// The flat wash under the gradient. It holds the whole image back evenly.
  Color get _wash => _isBrand
      ? AppColors.bgOverlay.withValues(alpha: 0.45)
      : AppColors.scrimDeep.withValues(alpha: 0.3);

  /// The gradient over it, which deepens towards the bottom so that copy and
  /// controls resting there stay legible whatever the photograph is doing.
  List<Color> get _gradient => _isBrand
      ? <Color>[
          AppColors.scrimHighlight.withValues(alpha: 0.3),
          AppColors.bgOverlay.withValues(alpha: 0.55),
          AppColors.bgOverlay.withValues(alpha: 0.96),
        ]
      : <Color>[
          AppColors.scrimDeep.withValues(alpha: 0.1),
          AppColors.scrimDeep.withValues(alpha: 0.45),
          AppColors.scrimDeep.withValues(alpha: 0.94),
        ];

  /// The wash across the top, which lifts the status bar area off the image.
  Color get _topWash => _isBrand
      ? AppColors.scrimHighlight.withValues(alpha: 0.55)
      : AppColors.scrimLift.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          asset,
          fit: BoxFit.cover,
          // The exports are far larger than any phone can show, and an
          // unbounded decode costs tens of megabytes of bitmap. Capping at the
          // window's real pixel width costs nothing visually.
          cacheWidth:
              (mediaQuery.size.width * mediaQuery.devicePixelRatio).round(),
          // Decorative. The copy on top of it already says what the screen is.
          excludeFromSemantics: true,
        ),
        DecoratedBox(decoration: BoxDecoration(color: _wash)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const <double>[0, 0.45, 1],
              colors: _gradient,
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.topCenter,
          child: SizedBox(
            height: _topScrimDesignHeight.dh,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    _topWash,
                    _topWash.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
