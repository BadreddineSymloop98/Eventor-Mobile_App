import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/input_rules.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/layout/photo_sheet_layout.dart';
import '../../../core/widgets/molecules/app_text_field.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/forgot_password_view_model.dart';

/// `09 Forgot password` — asks where to send a 6-digit reset code.
class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  static const String _backgroundImage =
      'assets/images/welcome_background.jpg';

  Future<void> _send(BuildContext context) async {
    final ForgotPasswordViewModel viewModel =
        context.read<ForgotPasswordViewModel>();
    FocusScope.of(context).unfocus();

    final String? email = await viewModel.sendCode();
    if (!context.mounted) return;

    if (email != null) {
      context.push(AppRoutes.resetCodeFor(email));
      return;
    }
    final Failure? failure = viewModel.failure;
    if (failure != null) {
      showAppToast(
        context,
        context.l10n.forFailure(failure),
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ForgotPasswordViewModel viewModel =
        context.watch<ForgotPasswordViewModel>();
    final AppLocalizations l10n = context.l10n;

    return PhotoSheetLayout(
      image: _backgroundImage,
      title: l10n.forgotPasswordTitle,
      subtitle: l10n.forgotPasswordSubtitle,
      sheet: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            controller: viewModel.emailController,
            label: l10n.emailLabel,
            hintText: l10n.emailPlaceholder,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            inputFormatters: InputRules.emailFormatters,
            textDirection: TextDirection.ltr,
            errorText: viewModel.emailError == null
                ? null
                : l10n.forEmailError(viewModel.emailError!),
            onSubmitted: (_) => _send(context),
          ),
          SizedBox(height: AppSpacing.md.dh),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MainButton(
                label: l10n.sendCode,
                canBeTapped: viewModel.canSubmit,
                isLoading: viewModel.isBusy,
                onPressed: () => _send(context),
              ),
              SizedBox(height: AppSpacing.sm.dh),
              MainButton(
                label: l10n.backToLogIn,
                style: MainButtonStyle.ghost,
                // The login form is still underneath.
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
