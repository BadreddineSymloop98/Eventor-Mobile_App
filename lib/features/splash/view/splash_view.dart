import 'package:flutter/material.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/widgets/layout/photo_backdrop.dart';
import '../../../l10n/app_localizations.dart';

/// The splash screen: the logo over a photograph of a venue.
///
/// The first screen the app shows. It holds the brand while `AppStartup`
/// loads the config and restores the session; the router's redirect then
/// replaces it with wherever the user belongs. It navigates nowhere itself.
///
/// Every dimension is a share of the window: the design measurements go
/// through `.dw` / `.dh`, which convert them from its 375×812 frame. Type is
/// the exception and stays in fixed points, so that a percentage-sized font
/// cannot override the reader's accessibility text-scale setting.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  /// Breathing room where the device reports no system inset.
  ///
  /// The design's 32pt frame inset is the system's own — status bar at the
  /// top, home indicator at the bottom — so it is taken from the device
  /// rather than added on top of it. Same rule as the onboarding screen, so
  /// the two agree about how much air sits above and below their content.
  static EdgeInsets get _minimumInset =>
      EdgeInsets.symmetric(vertical: AppSpacing.md.dh);

  /// Empty space where the other screens put their top bar; the splash has
  /// none, so the gap is held open to keep the logo in the same place it sits
  /// everywhere else.
  static double get _topSpacer => AppSizes.controlMd.dh;

  /// The logo is square, so both axes come from the width.
  static const double _logoDesignSize = 200;

  static const String _backgroundImage =
      'assets/images/splash_background.jpg';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      // The photograph runs under the status bar, so the scaffold's own
      // background only shows through before the image has decoded.
      backgroundColor: AppColors.bgBrand,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PhotoBackdrop(
            asset: SplashView._backgroundImage,
            tone: PhotoScrimTone.brand,
          ),
          SafeArea(
            minimum: SplashView._minimumInset,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
              ),
              child: Column(
                // The design spaces the three blocks evenly: the gap above
                // the logo and the gap below it are both 224 in the frame.
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: SplashView._topSpacer),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/logo.png',
                        width: SplashView._logoDesignSize.dw,
                        height: SplashView._logoDesignSize.dw,
                        fit: BoxFit.contain,
                        semanticLabel: l10n.appName,
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                      Text(
                        l10n.splashTagline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textOnBrand.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l10n.splashByline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textOnBrand.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

