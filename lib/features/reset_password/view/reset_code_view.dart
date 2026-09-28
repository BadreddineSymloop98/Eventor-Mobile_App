import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/layout/photo_sheet_layout.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/view/code_entry_sheet.dart';
import '../view_model/reset_code_view_model.dart';

/// `10 Verify code` in the password reset — "Check your email".
class ResetCodeView extends StatelessWidget {
  const ResetCodeView({super.key});

  static const String _backgroundImage =
      'assets/images/welcome_background.jpg';

  Future<void> _continue(BuildContext context) async {
    final ResetCodeViewModel viewModel = context.read<ResetCodeViewModel>();
    FocusScope.of(context).unfocus();
    final ResetPasswordArgs? args = await viewModel.verify();
    if (!context.mounted) return;
    if (args == null) {
      _reportUnhandled(context, viewModel);
      return;
    }

    // `10a` answers with the problem when the server refuses the code.
    final ResetCodeProblem? problem = await context.push<ResetCodeProblem>(
      AppRoutes.resetPassword,
      extra: args,
    );
    if (problem != null) viewModel.reportProblem(problem);
  }

  Future<void> _resend(BuildContext context) async {
    final ResetCodeViewModel viewModel = context.read<ResetCodeViewModel>();
    await viewModel.resend();
    if (!context.mounted) return;
    if (viewModel.takeCodeSent()) {
      showAppToast(context, context.l10n.verifyCodeResent);
      return;
    }
    _reportUnhandled(context, viewModel);
  }

  /// A refusal that is not about the code — offline, too many tries.
  void _reportUnhandled(BuildContext context, ResetCodeViewModel viewModel) {
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
    final ResetCodeViewModel viewModel = context.watch<ResetCodeViewModel>();
    final AppLocalizations l10n = context.l10n;

    return PhotoSheetLayout(
      image: _backgroundImage,
      title: l10n.resetCodeTitle,
      subtitle: l10n.resetCodeSubtitle(viewModel.email),
      sheet: CodeEntrySheet(
        controller: viewModel.codeController,
        focusNode: viewModel.codeFocusNode,
        problem: viewModel.problem,
        canSubmit: viewModel.canSubmit,
        isVerifying: viewModel.isBusy && !viewModel.isResending,
        onVerify: () => _continue(context),
        canResend: viewModel.canResend,
        resendClock: viewModel.resendClock,
        isResending: viewModel.isResending,
        onResend: () => _resend(context),
      ),
    );
  }
}
