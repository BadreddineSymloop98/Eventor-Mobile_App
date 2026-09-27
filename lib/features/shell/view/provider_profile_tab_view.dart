import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/models/account.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/atoms/app_avatar.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/layout/content_container.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/organisms/app_top_bar.dart';
import '../../../core/widgets/organisms/info_card.dart';
import '../../../l10n/app_localizations.dart';

/// The provider's Profile tab until their profile screens are built: who is
/// signed in, their documents, and Log out.
class ProviderProfileTabView extends StatelessWidget {
  const ProviderProfileTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppUser? user = context.watch<SessionController>().user;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppTopBar(title: l10n.navProfile, showBack: false),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPaddingAll,
        child: ContentContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (user != null)
                Row(
                  children: <Widget>[
                    AppAvatar(name: user.fullName, size: AppAvatarSize.large),
                    SizedBox(width: AppSpacing.sm.dw),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            user.fullName,
                            style: textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
                          ),
                          Text(
                            user.email,
                            textDirection: TextDirection.ltr,
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              SizedBox(height: AppSpacing.xl.dh),
              InfoCard(
                rows: <InfoRow>[
                  InfoRow(
                    icon: AppIcons.document,
                    text: l10n.profileDocuments,
                    trailing: AppIcon(
                      AppIcons.chevronRight,
                      size: AppSizes.iconMd,
                      color: AppColors.iconDefault,
                    ),
                    // A refused document is fixed on 08d; otherwise 08e shows
                    // where each one stands and takes what is missing.
                    onTap: () => context.push(
                      user?.verificationStatus == VerificationStatus.rejected
                          ? AppRoutes.resubmitDocuments
                          : AppRoutes.documents,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm.dh),
              Text(
                l10n.profileMoreSoon,
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: AppSpacing.xl2.dh),
              MainButton(
                label: l10n.logOut,
                style: MainButtonStyle.secondary,
                tone: MainButtonTone.danger,
                onPressed: () => context.read<SessionController>().signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
