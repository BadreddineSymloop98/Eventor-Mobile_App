import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/models/account.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/layout/content_container.dart';
import '../../../core/widgets/molecules/back_icon_button.dart';
import '../../../core/widgets/molecules/language_switch.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/role_card.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/role_selection_view_model.dart';

/// The fork in the sign-up: who is this person, and therefore what does the
/// rest of the app look like for them.
///
/// The first light screen in the flow — everything before it sits on a
/// photograph. It is also the first with any state of its own, which is why
/// it has a view model where the welcome screen does not.
class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({super.key});

  /// A soft shape behind the top of the screen, in the canvas tint. Purely
  /// decorative — it carries no content and is hidden from screen readers.
  static const String _headerDecoration = 'assets/icons/header.svg';

  /// 150 of 812 in the design frame.
  static const double _headerDesignHeight = 150;

  static EdgeInsets get _minimumInset =>
      EdgeInsets.symmetric(vertical: AppSpacing.md.dh);

  void _continue(BuildContext context) {
    final UserRole? role = context.read<RoleSelectionViewModel>().selectedRole;
    if (role == null) return;
    // The chosen role travels with the user to the register form, where it is
    // saved as part of the account rather than on its own.
    context.push(AppRoutes.registerFor(role));
  }

  static AppIcons _iconFor(UserRole role) => switch (role) {
        UserRole.client => AppIcons.user,
        UserRole.provider => AppIcons.briefcase,
      };

  static String _titleFor(UserRole role, AppLocalizations l10n) =>
      switch (role) {
        UserRole.client => l10n.roleClientTitle,
        UserRole.provider => l10n.roleProviderTitle,
      };

  static String _descriptionFor(UserRole role, AppLocalizations l10n) =>
      switch (role) {
        UserRole.client => l10n.roleClientDescription,
        UserRole.provider => l10n.roleProviderDescription,
      };

  @override
  Widget build(BuildContext context) {
    final RoleSelectionViewModel viewModel = context
        .watch<RoleSelectionViewModel>();
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bgSurface,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              _headerDecoration,
              height: _headerDesignHeight.dh,
              // The shape is drawn to span the full width whatever its aspect
              // ratio ends up being, matching the design's own stretch.
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
          SafeArea(
            minimum: _minimumInset,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _TopBar(),
                  // Centred in the space between the top bar and the button,
                  // rather than sitting directly under the bar. The scroll
                  // view takes its child's height while it fits — so the
                  // block is centred — and only fills and scrolls once the
                  // copy or the text scale makes it too tall.
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: ContentContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                l10n.roleSelectionTitle,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textBrand,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xs.dh),
                              Text(
                                l10n.roleSelectionSubtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xl2.dh),
                              for (final UserRole role
                                  in RoleSelectionViewModel.roles) ...<Widget>[
                                RoleCard(
                                  icon: _iconFor(role),
                                  title: _titleFor(role, l10n),
                                  description: _descriptionFor(role, l10n),
                                  isSelected: viewModel.isSelected(role),
                                  onTap: () => viewModel.selectRole(role),
                                ),
                                if (role != RoleSelectionViewModel.roles.last)
                                  SizedBox(height: AppSpacing.sm.dh),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl2.dh),
                  ContentContainer(
                    // Full width between the gutters, like the cards above.
                    // ContentContainer centres its child with loose
                    // constraints, and MainButton hugs its label unless it is
                    // stretched — so without this it shrinks to the text.
                    child: SizedBox(
                      width: double.infinity,
                      child: MainButton(
                        label: l10n.continueAction,
                        // Disabled until a role is picked. The screen warns
                        // the choice is permanent, so it must be a deliberate
                        // one.
                        canBeTapped: viewModel.canContinue,
                        onPressed: () => _continue(context),
                      ),
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

/// Back on one side, the language switch on the other.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.controlMd.dh,
      // Mirrors with the language, like the rest of the screen. Back belongs
      // on the side the reader came from, and its chevron points that way.
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          BackIconButton(),
          LanguageSwitch(),
        ],
      ),
    );
  }
}
