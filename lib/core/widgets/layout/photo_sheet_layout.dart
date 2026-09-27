import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../molecules/back_icon_button.dart';
import '../molecules/language_switch.dart';
import 'content_container.dart';
import 'photo_backdrop.dart';

/// The shape every credential screen shares: a photograph carrying the copy,
/// and a white sheet under it carrying the form.
///
/// Login, forgot password and verify code are all this, differing only in what
/// goes on the sheet. Extracted at the second use rather than the first, so
/// the shared part is described by two examples instead of guessed from one.
class PhotoSheetLayout extends StatelessWidget {
  const PhotoSheetLayout({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.sheet,
    this.onBack,
    this.showBack = true,
    super.key,
  });

  /// The design's split of the 812pt frame: 312 of photograph above the sheet,
  /// 500 of sheet below it.
  ///
  /// Held as flex rather than as a height so the two shrink together when the
  /// keyboard takes the bottom of the screen, instead of a fixed sheet
  /// overflowing the space left for it.
  static const int _photoFlex = 312;
  static const int _sheetFlex = 500;

  final String image;
  final String title;
  final String subtitle;

  /// What sits on the white panel. Laid out with the form at the top and the
  /// actions at the bottom, so pass a [Column] with two children.
  final Widget sheet;

  /// Replaces the default pop — `10b` goes to Login instead of back into a
  /// form whose account already exists.
  final VoidCallback? onBack;

  /// `false` for a screen with nothing behind it, like an invite link opened
  /// from an email.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgBrand,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PhotoBackdrop(asset: image),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: _photoFlex,
                child: SafeArea(
                  bottom: false,
                  minimum: EdgeInsets.only(top: AppSpacing.md.dh),
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md.dw,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: AppSizes.controlMd.dh,
                          child: Row(
                            children: <Widget>[
                              if (showBack)
                                BackIconButton(
                                  color: AppColors.iconOnBrand,
                                  onPressed: onBack,
                                ),
                              const Spacer(),
                              const LanguageSwitch(),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          title,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(color: AppColors.textOnBrand),
                        ),
                        SizedBox(height: AppSpacing.xs.dh),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                AppColors.textOnBrand.withValues(alpha: 0.78),
                          ),
                        ),
                        // The gap under the copy is the first thing to give
                        // when the keyboard takes the screen. Fixed, it makes
                        // the header overflow its own flex share; flexible,
                        // it simply closes up.
                        Flexible(
                          child: SizedBox(height: AppSpacing.xl.dh),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: _sheetFlex,
                child: _Sheet(child: ContentContainer(child: sheet)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The white panel the form sits on.
///
/// Raised off the photograph with the design's largest elevation and rounded
/// only at the top, so it reads as having been drawn up from the bottom edge.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(AppRadii.md),
          topEnd: Radius.circular(AppRadii.md),
        ),
        boxShadow: AppElevation.lg,
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: AppSpacing.md.dh),
        // The sheet loses height to the keyboard, and its contents have to go
        // somewhere. Scrolling is that somewhere: without it the form is
        // squashed against the actions and a focused field can end up under
        // the keyboard with no way to reach it.
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                // Fill the sheet when there is room, so the actions stay
                // pinned to the bottom edge as the design draws them, and
                // only start scrolling once there is not.
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: AppSpacing.md.dw,
                      end: AppSpacing.md.dw,
                      top: AppSpacing.xl2.dh,
                      bottom: AppSpacing.xl2.dh,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
