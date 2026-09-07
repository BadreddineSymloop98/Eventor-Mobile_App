import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/input_rules.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/code_input.dart';
import '../../../core/widgets/main_button.dart';
import '../../../core/widgets/photo_sheet_layout.dart';
import '../../../core/widgets/prompt_row.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/verify_code_view_model.dart';

/// Where a one-time code is entered.
///
/// Shares its shape with login and forgot password — see [PhotoSheetLayout] —
/// and differs only in what sits on the sheet.
class VerifyCodeView extends StatelessWidget {
  const VerifyCodeView({super.key});

  static const String _backgroundImage =
      'assets/images/welcome_background.jpg';

  Future<void> _verify(BuildContext context) async {
    final VerifyCodeViewModel viewModel = context.read<VerifyCodeViewModel>();
    final NavigatorState navigator = Navigator.of(context);

    FocusScope.of(context).unfocus();

    final bool succeeded = await viewModel.verify();
    if (!succeeded || !context.mounted) return;

    // The end of the pre-auth flow. Everything behind it is dropped: there is
    // nothing here the user should be able to walk back into.
    await navigator.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _resend(BuildContext context) async {
    final VerifyCodeViewModel viewModel = context.read<VerifyCodeViewModel>();
    final AppLocalizations l10n = context.l10n;

    final bool sent = await viewModel.resend();
    if (!sent || !context.mounted) return;

    showAppToast(context, l10n.verifyCodeResent);
  }

  @override
  Widget build(BuildContext context) {
    final VerifyCodeViewModel viewModel = context.watch<VerifyCodeViewModel>();
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return PhotoSheetLayout(
      image: _backgroundImage,
      title: l10n.verifyCodeTitle,
      subtitle: l10n.verifyCodeSubtitle(
        viewModel.destination ?? l10n.verifyCodeDestinationFallback,
      ),
      sheet: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.verificationCodeLabel,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: AppSpacing.xs2.dh),
              CodeInput(
                controller: viewModel.codeController,
                focusNode: viewModel.codeFocusNode,
                length: InputRules.verificationCodeLength,
                // Submitting on the last digit saves a reach for the button,
                // which is the whole reason a code is six separate boxes.
                onCompleted: (_) => _verify(context),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MainButton(
                label: l10n.verifyAction,
                canBeTapped: viewModel.canSubmit,
                // Only its own work. A resend spins the resend line instead.
                isLoading: viewModel.isVerifying,
                onPressed: () => _verify(context),
              ),
              SizedBox(height: AppSpacing.sm.dh),
              // Until the wait runs out there is nothing to offer, so the
              // line states the wait instead of a link that would not work.
              if (viewModel.resendSecondsRemaining > 0)
                _ResendCountdown(
                  secondsRemaining: viewModel.resendSecondsRemaining,
                )
              else
                PromptRow(
                  question: l10n.verifyNoCodePrompt,
                  actionLabel: l10n.resend,
                  isLoading: viewModel.isResending,
                  onTap: () => _resend(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The wait before another code may be asked for, counting down in place.
///
/// It takes the same height as the [PromptRow] that replaces it at zero, so
/// the sheet does not shift as the two swap over.
class _ResendCountdown extends StatelessWidget {
  const _ResendCountdown({required this.secondsRemaining});

  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(minHeight: AppSizes.controlSm.dh),
      alignment: Alignment.center,
      child: Text(
        context.l10n.verifyResendCountdown(secondsRemaining),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
