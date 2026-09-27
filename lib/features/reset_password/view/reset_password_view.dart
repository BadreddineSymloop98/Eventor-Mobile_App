import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/input_rules.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/validation_error.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/layout/photo_sheet_layout.dart';
import '../../../core/widgets/molecules/app_text_field.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/reset_password_view_model.dart';

/// `10a Reset password` — the new password, twice.
///
/// Success lands on Login, not Home: the reset revokes every session, this
/// device's too, so the user signs in with the new password.
class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key});

  static const String _backgroundImage =
      'assets/images/welcome_background.jpg';

  Future<void> _submit(BuildContext context) async {
    final ResetPasswordViewModel viewModel =
        context.read<ResetPasswordViewModel>();
    FocusScope.of(context).unfocus();

    final ResetOutcome? outcome = await viewModel.submit();
    if (!context.mounted) return;

    switch (outcome) {
      case ResetSucceeded():
        context.go(
          AppRoutes.loginWith(email: viewModel.args.email, afterReset: true),
        );
      case ResetCodeRefused(:final ResetCodeProblem problem):
        context.pop(problem);
      case null:
        final Failure? failure = viewModel.failure;
        if (failure != null) {
          showAppToast(
            context,
            context.l10n.forFailure(failure),
            tone: AppToastTone.error,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ResetPasswordViewModel viewModel =
        context.watch<ResetPasswordViewModel>();
    final AppLocalizations l10n = context.l10n;

    return PhotoSheetLayout(
      image: _backgroundImage,
      title: l10n.resetPasswordTitle,
      subtitle: l10n.resetPasswordSubtitle,
      sheet: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
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
          SizedBox(height: AppSpacing.md.dh),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MainButton(
                label: l10n.resetPasswordAction,
                canBeTapped: viewModel.canSubmit,
                isLoading: viewModel.isBusy,
                onPressed: () => _submit(context),
              ),
              SizedBox(height: AppSpacing.sm.dh),
              MainButton(
                label: l10n.backToLogIn,
                style: MainButtonStyle.ghost,
                onPressed: () => context.go(
                  AppRoutes.loginWith(email: viewModel.args.email),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "New password" and "Confirm password", as `10a` and `10f` both draw them.
class NewPasswordFields extends StatelessWidget {
  const NewPasswordFields({
    required this.passwordController,
    required this.confirmController,
    required this.confirmFocusNode,
    required this.minLength,
    required this.onPasswordSubmitted,
    required this.onConfirmSubmitted,
    this.passwordError,
    this.confirmError,
    super.key,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final FocusNode confirmFocusNode;
  final int minLength;
  final VoidCallback onPasswordSubmitted;
  final VoidCallback onConfirmSubmitted;
  final PasswordError? passwordError;
  final PasswordError? confirmError;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final PasswordError? password = passwordError;
    final PasswordError? confirm = confirmError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: passwordController,
          label: l10n.newPasswordLabel,
          obscureText: true,
          autofillHints: const <String>[AutofillHints.newPassword],
          inputFormatters: InputRules.passwordFormatters,
          textDirection: TextDirection.ltr,
          helperText: l10n.passwordHint(minLength),
          errorText: password == null ? null : l10n.forPasswordError(password),
          onSubmitted: (_) => onPasswordSubmitted(),
        ),
        SizedBox(height: AppSpacing.md.dh),
        AppTextField(
          controller: confirmController,
          focusNode: confirmFocusNode,
          label: l10n.confirmPasswordLabel,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.newPassword],
          inputFormatters: InputRules.passwordFormatters,
          textDirection: TextDirection.ltr,
          errorText: confirm == null ? null : l10n.forPasswordError(confirm),
          onSubmitted: (_) => onConfirmSubmitted(),
        ),
      ],
    );
  }
}
