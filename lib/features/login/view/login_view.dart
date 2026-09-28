import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Only DateFormat: intl exports its own TextDirection, which would shadow
// Flutter's.
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../../core/constants/input_rules.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/layout/photo_sheet_layout.dart';
import '../../../core/widgets/molecules/app_text_field.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/prompt_row.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/login_view_model.dart';

/// The login form — `07`, with `07b` wrong password, `07c` unverified email,
/// `07d` locked out, and the blocked / expired notices, all as a banner above
/// the fields.
///
/// Shares its shape with the rest of the credential screens — see
/// [PhotoSheetLayout].
class LoginView extends StatefulWidget {
  const LoginView({this.announceReset = false, super.key});

  /// Shows "Password updated" once on arrival, after `10a`.
  final bool announceReset;

  static const String _backgroundImage =
      'assets/images/welcome_background.jpg';

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  void initState() {
    super.initState();
    if (widget.announceReset) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAppToast(context, context.l10n.passwordResetDone);
      });
    }
  }

  Future<void> _signIn() async {
    final LoginViewModel viewModel = context.read<LoginViewModel>();
    FocusScope.of(context).unfocus();

    await viewModel.signIn();
    if (!mounted) return;
    _reportUnhandledFailure(viewModel);
  }

  Future<void> _sendNewCode() async {
    final LoginViewModel viewModel = context.read<LoginViewModel>();
    final VerifyEmailArgs? args = await viewModel.sendNewCode();
    if (!mounted) return;
    if (args == null) {
      _reportUnhandledFailure(viewModel);
      return;
    }
    context.push(AppRoutes.verifyEmail, extra: args);
  }

  /// Anything the view model did not turn into a banner — no connection, an
  /// unexpected server answer — shows as a toast.
  void _reportUnhandledFailure(LoginViewModel viewModel) {
    final Failure? failure = viewModel.failure;
    if (failure == null) return;
    showAppToast(
      context,
      context.l10n.forFailure(failure),
      tone: AppToastTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LoginViewModel viewModel = context.watch<LoginViewModel>();
    final AppLocalizations l10n = context.l10n;
    // Login is the signed-out landing once Welcome has been seen, and where a
    // finished reset or an ended session drops the user — with nothing under
    // it. Asked of this route, not the router, so a screen pushed on top does
    // not make it look poppable.
    final bool hasScreenBehind = ModalRoute.of(context)?.canPop ?? false;

    return PhotoSheetLayout(
      image: LoginView._backgroundImage,
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      showBack: hasScreenBehind,
      sheet: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (viewModel.problem != null) ...<Widget>[
                  _ProblemBanner(
                    viewModel: viewModel,
                    onSendNewCode: _sendNewCode,
                  ),
                  SizedBox(height: AppSpacing.md.dh),
                ],
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
                  onSubmitted: (_) => _signIn(),
                ),
                SizedBox(height: AppSpacing.xs2.dh),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: MainButton(
                    label: l10n.forgotPassword,
                    style: MainButtonStyle.ghost,
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md.dh),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MainButton(
                label: viewModel.isLocked
                    ? l10n.loginTryAgainAt(_clock(context, viewModel))
                    : l10n.logIn,
                canBeTapped: viewModel.canSubmit,
                isLoading: viewModel.isBusy,
                onPressed: _signIn,
              ),
              SizedBox(height: AppSpacing.sm.dh),
              PromptRow(
                question: l10n.loginNewPrompt,
                actionLabel: l10n.createAccount,
                // Replaces rather than pushes: the two forms are alternatives,
                // so the stack must not grow as the user flips between them.
                // Except when Login is the landing — replacing it would leave
                // role selection's Back with nowhere to go.
                onTap: () => hasScreenBehind
                    ? context.pushReplacement(AppRoutes.roleSelection)
                    : context.push(AppRoutes.roleSelection),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The clock time the lock ends, in the device's own 12/24-hour style.
String _clock(BuildContext context, LoginViewModel viewModel) {
  final DateTime? until = viewModel.lockedUntil;
  if (until == null) return '';
  final String locale = Localizations.localeOf(context).toLanguageTag();
  return MediaQuery.alwaysUse24HourFormatOf(context)
      ? DateFormat.Hm(locale).format(until)
      : DateFormat.jm(locale).format(until);
}

class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.viewModel, required this.onSendNewCode});

  final LoginViewModel viewModel;
  final VoidCallback onSendNewCode;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return switch (viewModel.problem!) {
      LoginProblem.wrongCredentials => InlineBanner(
          title: l10n.loginWrongTitle,
          message: l10n.loginWrongBody,
        ),
      LoginProblem.unverified => InlineBanner(
          title: l10n.loginUnverifiedTitle,
          message: l10n.loginUnverifiedBody(
            viewModel.unverifiedEmail ?? viewModel.emailController.text,
          ),
          actionLabel: l10n.loginSendNewCode,
          onAction: viewModel.isSendingCode ? null : onSendNewCode,
        ),
      LoginProblem.locked => InlineBanner(
          title: l10n.loginLockedTitle,
          message: l10n.loginLockedBody(_clock(context, viewModel)),
        ),
      LoginProblem.blocked => InlineBanner(
          title: l10n.loginBlockedTitle,
          message: <String>[
            ?viewModel.serverMessage,
            if (viewModel.blockedUntil case final DateTime until)
              l10n.loginBlockedUntil(
                dayMonthYear(until, Localizations.localeOf(context).languageCode),
              ),
          ].join('\n'),
        ),
      LoginProblem.notAllowed => InlineBanner(
          title: l10n.loginNotAllowedTitle,
          message: viewModel.serverMessage,
        ),
      LoginProblem.sessionExpired => InlineBanner(
          title: l10n.sessionExpiredTitle,
          message: l10n.sessionExpiredBody,
          tone: InlineBannerTone.info,
        ),
    };
  }
}
