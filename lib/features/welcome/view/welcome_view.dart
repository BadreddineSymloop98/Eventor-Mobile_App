import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/layout/content_container.dart';
import '../../../core/widgets/molecules/language_switch.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/layout/photo_backdrop.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/welcome_view_model.dart';

/// Where onboarding leads, and where anyone without a session lands until
/// they have been through it once.
///
/// It asks one question — do you have an account or not. Its view model only
/// remembers that the question was answered, after which a signed-out launch
/// opens on Login instead.
///
/// Every dimension is a share of the window: design measurements go through
/// `.dw` / `.dh`, which convert them from the 375×812 frame.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  static const String _backgroundImage =
      'assets/images/welcome_background.jpg';

  static const String _logoImage = 'assets/images/logo.png';

  /// Smaller than the splash's 200: this screen has to make room for the copy
  /// and both buttons.
  static const double _logoDesignSize = 150;

  /// Breathing room where the device reports no system inset of its own. The
  /// design's 32pt frame inset is the system's — see the note on the splash.
  static EdgeInsets get _minimumInset =>
      EdgeInsets.symmetric(vertical: AppSpacing.md.dh);

  void _createAccount(BuildContext context) =>
      _leaveFor(context, AppRoutes.roleSelection);

  void _logIn(BuildContext context) => _leaveFor(context, AppRoutes.login);

  Future<void> _leaveFor(BuildContext context, String route) async {
    await context.read<WelcomeViewModel>().markAsSeen();
    if (!context.mounted) return;
    // Pushed rather than gone to, so Back returns here and the user can pick
    // the other door — this time round, even though the next launch skips it.
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bgBrand,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const PhotoBackdrop(asset: _backgroundImage),
          SafeArea(
            minimum: _minimumInset,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // No Skip and no Back — this screen is the start of the auth
                  // flow, so the switch is alone.
                  SizedBox(
                    height: AppSizes.controlMd.dh,
                    child: const Align(
                      // Directional, so it mirrors with the language like the
                      // rest of the screen.
                      alignment: AlignmentDirectional.centerEnd,
                      child: LanguageSwitch(),
                    ),
                  ),
                  ContentContainer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Image.asset(
                          _logoImage,
                          width: _logoDesignSize.dw,
                          height: _logoDesignSize.dw,
                          fit: BoxFit.contain,
                          semanticLabel: l10n.appName,
                        ),
                        SizedBox(height: AppSpacing.xl.dh),
                        Text(
                          l10n.welcomeTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.textOnBrand,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs.dh),
                        Text(
                          l10n.welcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                AppColors.textOnBrand.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ContentContainer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        MainButton(
                          label: l10n.createAccount,
                          tone: MainButtonTone.inverse,
                          onPressed: () => _createAccount(context),
                        ),
                        SizedBox(height: AppSpacing.sm.dh),
                        MainButton(
                          label: l10n.welcomeHaveAccount,
                          style: MainButtonStyle.secondary,
                          tone: MainButtonTone.inverse,
                          onPressed: () => _logIn(context),
                        ),
                      ],
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
