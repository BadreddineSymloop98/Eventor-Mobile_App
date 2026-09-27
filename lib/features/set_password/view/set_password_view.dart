import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/layout/photo_sheet_layout.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../reset_password/view/reset_password_view.dart';
import '../view_model/set_password_view_model.dart';

/// `10f Set password` and `10g Link expired` — opened from an admin's invite
/// email, usually as the very first screen of the app, so it has no Back.
///
/// Where the design's `10g` offers "Request a new link", there is no endpoint
/// for one — only an admin can re-send — so it becomes "Contact support",
/// shown only while the server publishes a support address. Without one, the
/// way out is "Back to log in", so the screen is never a dead end.
class SetPasswordView extends StatelessWidget {
  const SetPasswordView({super.key});

  static const String _backgroundImage =
      'assets/images/welcome_background.jpg';

  Future<void> _submit(BuildContext context) async {
    final SetPasswordViewModel viewModel = context.read<SetPasswordViewModel>();
    FocusScope.of(context).unfocus();
    await viewModel.submit();
    if (!context.mounted) return;
    final Failure? failure = viewModel.failure;
    if (failure != null) {
      showAppToast(
        context,
        context.l10n.forFailure(failure),
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _contactSupport(BuildContext context, String address) async {
    final Uri mail = Uri(
      scheme: 'mailto',
      path: address,
      queryParameters: <String, String>{
        'subject': context.l10n.supportEmailSubject,
      },
    );
    await launchUrl(mail);
  }

  @override
  Widget build(BuildContext context) {
    final SetPasswordViewModel viewModel = context.watch<SetPasswordViewModel>();
    final AppLocalizations l10n = context.l10n;
    final InviteProblem? problem = viewModel.problem;
    final String? support = viewModel.supportEmail;

    return PhotoSheetLayout(
      image: _backgroundImage,
      title: l10n.setPasswordTitle,
      subtitle: l10n.setPasswordSubtitle,
      showBack: false,
      sheet: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (problem != null) ...<Widget>[
                switch (problem) {
                  InviteProblem.expired => InlineBanner(
                      title: l10n.inviteExpiredTitle,
                      message: l10n.inviteExpiredBody,
                    ),
                  InviteProblem.invalid => InlineBanner(
                      title: l10n.inviteInvalidTitle,
                      message: l10n.inviteInvalidBody,
                    ),
                },
                SizedBox(height: AppSpacing.md.dh),
              ],
              // A dead link has nothing to type into; the fields are only
              // offered while the link can still be used.
              if (problem == null)
                AutofillGroup(
                  child: NewPasswordFields(
                    passwordController: viewModel.passwordController,
                    confirmController: viewModel.confirmController,
                    confirmFocusNode: viewModel.confirmFocusNode,
                    passwordError: viewModel.passwordError,
                    confirmError: viewModel.confirmError,
                    minLength: viewModel.minPasswordLength,
                    onPasswordSubmitted: viewModel.moveFocusToConfirm,
                    onConfirmSubmitted: () => _submit(context),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md.dh),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (problem == null)
                MainButton(
                  label: l10n.setPasswordAction,
                  canBeTapped: viewModel.canSubmit,
                  isLoading: viewModel.isBusy,
                  onPressed: () => _submit(context),
                )
              else if (support != null)
                MainButton(
                  label: l10n.contactSupport,
                  onPressed: () => _contactSupport(context, support),
                ),
              if (problem == null && support != null) ...<Widget>[
                SizedBox(height: AppSpacing.sm.dh),
                MainButton(
                  label: l10n.needHelpContactSupport,
                  style: MainButtonStyle.ghost,
                  onPressed: () => _contactSupport(context, support),
                ),
              ],
              if (problem != null) ...<Widget>[
                SizedBox(height: AppSpacing.sm.dh),
                MainButton(
                  label: l10n.backToLogIn,
                  style: support == null
                      ? MainButtonStyle.primary
                      : MainButtonStyle.ghost,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
