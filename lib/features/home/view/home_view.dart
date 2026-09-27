import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/models/account.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/layout/content_container.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/organisms/app_top_bar.dart';
import '../../../l10n/app_localizations.dart';

/// Where a signed-in user lands.
///
/// Still a placeholder — the screens after sign-in are not built yet — but
/// it lets the flows be followed to their end: a provider sees where their
/// review stands and can reach their documents, and anyone can log out.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController session = context.watch<SessionController>();
    final AppUser? user = session.user;
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppTopBar(title: l10n.homeTitle, showBack: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPaddingAll,
          child: ContentContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.homeGreeting(user?.fullName ?? ''),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs.dh),
                Text(
                  l10n.homeComingSoon,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (user != null && user.isProvider) ...<Widget>[
                  SizedBox(height: AppSpacing.xl.dh),
                  _ProviderStatus(user: user),
                ],
                SizedBox(height: AppSpacing.xl2.dh),
                MainButton(
                  label: l10n.logOut,
                  style: MainButtonStyle.secondary,
                  tone: MainButtonTone.danger,
                  onPressed: session.signOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The provider's verification, until `21a` / `21b` replace it.
class _ProviderStatus extends StatelessWidget {
  const _ProviderStatus({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (user.verificationStatus == VerificationStatus.verified) {
      return const SizedBox.shrink();
    }
    final bool rejected =
        user.verificationStatus == VerificationStatus.rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InlineBanner(
          title: rejected
              ? l10n.homeProviderRejectedTitle
              : l10n.homeProviderPendingTitle,
          message: l10n.homeProviderPendingBody,
          tone: rejected ? InlineBannerTone.danger : InlineBannerTone.info,
        ),
        SizedBox(height: AppSpacing.sm.dh),
        MainButton(
          label: l10n.homeUploadDocuments,
          style: MainButtonStyle.secondary,
          onPressed: () => context.push(AppRoutes.documents),
        ),
      ],
    );
  }
}
