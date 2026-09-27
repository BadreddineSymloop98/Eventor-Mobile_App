import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/ui_helpers.dart';

/// Every icon the app draws, by the name the design gives it.
///
/// A closed list rather than asset paths at the call site: a typo in a path
/// fails at runtime on the one screen that uses it, a typo here fails to
/// compile. The names are the design's `Icon/*` components; the files under
/// `assets/icons/` were exported from them, so one can be re-exported without
/// touching a widget.
///
/// The exports carry the design's grey or purple, but that colour is never
/// shown — [AppIcon] tints every icon from a single colour, which works for the
/// filled icons and the stroked ones alike.
enum AppIcons {
  alertTriangle('alert-triangle'),
  bell('bell'),
  briefcase('briefcase'),
  brush('brush'),
  building('building'),
  calendar('calendar'),
  camera('camera'),
  catering('catering'),
  check('check'),
  chevronDown('chevron-down'),
  chevronLeft('chevron-left', isDirectional: true),
  chevronRight('chevron-right', isDirectional: true),
  close('close'),
  decor('decor'),
  fileText('file-text'),
  filter('filter'),
  flower('flower'),
  heart('heart'),
  helpCircle('help-circle'),
  home('home'),
  layers('layers'),
  mapPin('map-pin'),
  message('message'),
  moreHorizontal('more-horizontal'),
  music('music'),
  pieChart('pie-chart'),
  plus('plus'),
  search('search'),
  settings('settings'),
  smartphone('smartphone'),
  spinner('spinner'),
  star('star'),
  starFilled('star-filled'),
  user('user'),
  video('video'),

  // Not in the design's icon set.
  //
  // The selected state of the bottom nav's five tabs. Feather has no filled
  // glyphs, so each is its outline twin's outer silhouette — same 24pt grid,
  // same rounded corners — made solid, with the inner detail cut out (the
  // door, the date grid, the typing dots) so it still tints from one colour.
  // Search is the exception: a filled lens reads as a blob, so its selected
  // form is a heavier 2.75pt ring instead.
  homeFilled('home-filled'),
  searchFilled('search-filled'),
  calendarFilled('calendar-filled'),
  messageFilled('message-filled'),
  userFilled('user-filled'),

  // `eye` / `eye-off` are Feather's own, drawn in the same 2pt stroke as the
  // rest, for the password visibility toggle. `document`, `upload` and `trash`
  // predate the design's set and are only used by the document upload field
  // and its action sheet.
  eye('eye'),
  eyeOff('eye-off'),
  document('document'),
  upload('upload'),
  trash('trash');

  const AppIcons(this._fileName, {this.isDirectional = false});

  final String _fileName;

  /// Whether the glyph points somewhere, and so must be mirrored in a
  /// right-to-left layout. A chevron pointing "back" points left in English
  /// and right in Arabic; a bell is the same either way.
  final bool isDirectional;

  String get assetPath => 'assets/icons/$_fileName.svg';
}

/// One of the design's icons, tinted and sized.
///
/// [size] is in design pixels on the 375pt frame and converted with `.dw`, so
/// an icon keeps its proportion to the layout around it and stays square.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    this.size = AppSizes.iconLg,
    this.color = AppColors.iconDefault,
    this.semanticLabel,
    super.key,
  });

  final AppIcons icon;

  /// Design pixels. Defaults to `size/icon-lg`, which is what the design's
  /// icon components are drawn at.
  final double size;

  final Color color;

  /// What a screen reader says for the icon. Leave it `null` for a decorative
  /// icon beside a label that already says the same thing.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final double side = size.dw;
    final Widget glyph = SvgPicture.asset(
      icon.assetPath,
      width: side,
      height: side,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );

    if (!icon.isDirectional) return glyph;

    return Transform.flip(
      flipX: Directionality.of(context) == TextDirection.rtl,
      child: glyph,
    );
  }
}
