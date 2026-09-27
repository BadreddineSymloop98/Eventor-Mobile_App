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
import '../view_model/verify_email_view_model.dart';

/// `10b Confirm email` — with `10c` (wrong code) and `10d` (expired) shown
/// as a banner over the boxes.
///
/// Back goes to Login with the address filled in, not back to the form: the
/// account already exists, so resubmitting the form would only say the email
/// is taken. Logging in later brings the user straight back here (`07c`).
class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({super.key});

  static const String _backgroundImage =
      'assets/images/welcome_background.jpg';

  Future<void> _verify(BuildContext context) async {
    final VerifyEmailViewModel viewModel = context.read<VerifyEmailViewModel>();
    FocusScope.of(context).unfocus();
    await viewModel.verify();
    if (context.mounted) _reportUnhandled(context, viewModel);
  }

  Future<void> _resend(BuildContext context) async {
    final VerifyEmailViewModel viewModel = context.read<VerifyEmailViewModel>();
    await viewModel.resend();
    if (!context.mounted) return;
    if (viewModel.takeCodeSent()) {
      showAppToast(context, context.l10n.verifyCodeResent);
    } else {
      _reportUnhandled(context, viewModel);
    }
  }

  void _reportUnhandled(BuildContext context, VerifyEmailViewModel viewModel) {
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
    final VerifyEmailViewModel viewModel = context.watch<VerifyEmailViewModel>();
    final AppLocalizations l10n = context.l10n;

    return PopScope(
      // The system back gesture follows the same rule as the chevron.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) context.go(AppRoutes.loginWith(email: viewModel.email));
      },
      child: PhotoSheetLayout(
        image: _backgroundImage,
        title: l10n.verifyEmailTitle,
        subtitle: l10n.verifyEmailSubtitle(viewModel.email),
        onBack: () => context.go(AppRoutes.loginWith(email: viewModel.email)),
        sheet: CodeEntrySheet(
          controller: viewModel.codeController,
          focusNode: viewModel.codeFocusNode,
          problem: viewModel.problem,
          canSubmit: viewModel.canSubmit,
          isVerifying: viewModel.isBusy && !viewModel.isResending,
          onVerify: () => _verify(context),
          canResend: viewModel.canResend,
          resendClock: viewModel.resendClock,
          isResending: viewModel.isResending,
          onResend: () => _resend(context),
        ),
      ),
    );
  }
}
