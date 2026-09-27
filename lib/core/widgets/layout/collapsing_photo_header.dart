import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../molecules/back_icon_button.dart';
import '../molecules/language_switch.dart';

/// The header of the long forms (`08` Register, `08e` Documents), which
/// shrinks as the form scrolls under it.
///
/// Fully open it is the photograph, the heading and the line under it. As it
/// closes the photograph darkens away and the subtitle folds shut, until all
/// that is left is the top bar and "Create your account" — enough to say where
/// you are, and no more.
///
/// The top bar never leaves. Losing the way back, or the language switch, part
/// way down a sign-up form would be worse than losing the picture.
class CollapsingPhotoHeader extends StatelessWidget {
  const CollapsingPhotoHeader({
    required this.title,
    required this.subtitle,
    this.onBack,
    super.key,
  });

  final String title;

  /// The line under the heading. Folds away as the header closes.
  final String subtitle;

  /// Replaces the default pop.
  final VoidCallback? onBack;

  static const String _backgroundImage = 'assets/images/welcome_background.jpg';

  /// Design heights, before the status bar is added to them. 208 in the frame
  /// less the 32 that stands for the status bar.
  static const double _expandedDesignHeight = 176;

  /// Top bar, a gap, one line of heading, and the padding under it.
  static const double _collapsedDesignHeight = 108;

  @override
  Widget build(BuildContext context) {
    final double expanded = _expandedDesignHeight.dh;
    final double collapsed = _collapsedDesignHeight.dh;

    return SliverAppBar(
      pinned: true,
      // The bar is its own header; the route's back button would duplicate
      // the one already in the top bar.
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.bgBrand,
      expandedHeight: expanded,
      collapsedHeight: collapsed,
      toolbarHeight: collapsed,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double safeTop = MediaQuery.paddingOf(context).top;

          // How far shut the header is, 0 open and 1 closed. The sliver's own
          // height is what reports it — there is nothing else to ask.
          final double content = constraints.maxHeight - safeTop;
          final double progress =
              ((expanded - content) / (expanded - collapsed)).clamp(0.0, 1.0);

          return _HeaderContent(
            progress: progress,
            title: title,
            subtitle: subtitle,
            onBack: onBack,
          );
        },
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({
    required this.progress,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  /// 0 while the header is fully open, 1 once it is fully shut.
  final double progress;

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double openness = 1 - progress;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // The photograph fades rather than being cropped away, so the bar
        // settles on the flat brand colour instead of a sliver of image.
        Opacity(
          opacity: openness,
          child: Image.asset(
            CollapsingPhotoHeader._backgroundImage,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            excludeFromSemantics: true,
          ),
        ),
        Opacity(
          opacity: openness,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.scrimDeep.withValues(alpha: 0.1),
                  AppColors.scrimDeep.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md.dw,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _TopBar(onBack: onBack),
                // Takes up whatever room the header still has, so the copy
                // stays pinned to its bottom edge as it closes.
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.textOnBrand,
                  ),
                ),
                // Folds shut rather than merely fading, so it gives its height
                // back to the header instead of leaving a gap behind.
                ClipRect(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    heightFactor: openness,
                    child: Opacity(
                      opacity: openness,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          top: AppSpacing.xs.dh,
                        ),
                        child: Text(
                          subtitle,
                          // The header reserves room for the design's two
                          // lines. A longer rendering — Arabic, a large text
                          // scale — ellipsises instead of overflowing it.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textOnBrand.withValues(
                              alpha: 0.78,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl.dh),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Back on one side, the language switch on the other.
class _TopBar extends StatelessWidget {
  const _TopBar({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.controlMd.dh,
      // Mirrors with the language, like the rest of the screen.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          BackIconButton(color: AppColors.iconOnBrand, onPressed: onBack),
          const LanguageSwitch(),
        ],
      ),
    );
  }
}
