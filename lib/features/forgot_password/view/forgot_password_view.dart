import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/input_rules.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/main_button.dart';
import '../../../core/widgets/photo_sheet_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/forgot_password_view_model.dart';

/// Asks for the address a reset link should go to.
///
/// Shares its shape with the login screen — see [PhotoSheetLayout] — and
/// differs only in what sits on the sheet.
class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  static const String _backgroundImage =
      'assets/images/welcome_background.jpg';

  Future<void> _send(BuildContext context) async {
    final ForgotPasswordViewModel viewModel =
        context.read<ForgotPasswordViewModel>();
    final NavigatorState navigator = Navigator.of(context);

    FocusScope.of(context).unfocus();

    final bool succeeded = await viewModel.sendResetLink();
    if (!succeeded || !context.mounted) return;

    await navigator.pushNamed(
      AppRoutes.verifyCode,
      arguments: viewModel.emailController.text.trim(),
    );
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
            focusNode: viewModel.emailFocusNode,
            label: l10n.emailLabel,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            inputFormatters: InputRules.emailFormatters,
            // An address is Latin text even in an Arabic UI.
            textDirection: TextDirection.ltr,
            errorText: viewModel.emailError == null
                ? null
                : l10n.forEmailError(viewModel.emailError!),
            onSubmitted: (_) => _send(context),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MainButton(
                label: l10n.sendResetLink,
                canBeTapped: viewModel.canSubmit,
                isLoading: viewModel.isBusy,
                onPressed: () => _send(context),
              ),
              SizedBox(height: AppSpacing.sm.dh),
              Align(
                child: MainButton(
                  label: l10n.backToLogIn,
                  style: MainButtonStyle.ghost,
                  // Pops rather than pushing login again: this screen was
                  // opened from it, so the form is still underneath.
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
