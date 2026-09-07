import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/input_rules.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/main_button.dart';
import '../../../core/widgets/photo_sheet_layout.dart';
import '../../../core/widgets/prompt_row.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/login_view_model.dart';

/// The login form.
///
/// Shares its shape with the forgot-password screen — see [PhotoSheetLayout] —
/// and differs only in what sits on the sheet.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  static const String _backgroundImage =
      'assets/images/welcome_background.jpg';

  Future<void> _signIn(BuildContext context) async {
    final LoginViewModel viewModel = context.read<LoginViewModel>();
    final NavigatorState navigator = Navigator.of(context);

    FocusScope.of(context).unfocus();

    final bool succeeded = await viewModel.signIn();
    if (!succeeded || !context.mounted) return;

    await navigator.pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final LoginViewModel viewModel = context.watch<LoginViewModel>();
    final AppLocalizations l10n = context.l10n;

    return PhotoSheetLayout(
      image: _backgroundImage,
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      sheet: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: viewModel.emailController,
                  focusNode: viewModel.emailFocusNode,
                  label: l10n.emailLabel,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.email],
                  inputFormatters: InputRules.emailFormatters,
                  // Credentials stay Latin whatever the app's language is.
                  textDirection: TextDirection.ltr,
                  hintText: l10n.emailPlaceholder,
                  errorText: viewModel.emailError == null
                      ? null
                      : l10n.forEmailError(viewModel.emailError!),
                  onSubmitted: (_) => viewModel.moveFocusToPassword(),
                ),
                SizedBox(height: AppSpacing.md.dh),
                AppTextField(
                  controller: viewModel.passwordController,
                  focusNode: viewModel.passwordFocusNode,
                  label: l10n.passwordLabel,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  inputFormatters: InputRules.passwordFormatters,
                  textDirection: TextDirection.ltr,
                  errorText: viewModel.passwordError == null
                      ? null
                      : l10n.forPasswordError(viewModel.passwordError!),
                  onSubmitted: (_) => _signIn(context),
                ),
                SizedBox(height: AppSpacing.xs2.dh),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: MainButton(
                    label: l10n.forgotPassword,
                    style: MainButtonStyle.ghost,
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.forgotPassword),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MainButton(
                label: l10n.logIn,
                canBeTapped: viewModel.canSubmit,
                isLoading: viewModel.isBusy,
                onPressed: () => _signIn(context),
              ),
              SizedBox(height: AppSpacing.sm.dh),
              PromptRow(
                question: l10n.loginNewPrompt,
                actionLabel: l10n.createAccount,
                onTap: () => Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.roleSelection),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
