import 'package:flutter/material.dart';

import '../../../core/config/data_source.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/widgets/molecules/code_input.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/prompt_row.dart';
import '../../../l10n/app_localizations.dart';
import '../../../mock/mock_backend.dart';

/// What went wrong with an entered code — `10c` / `10d`.
enum CodeProblem { invalid, expired }

/// The sheet shared by the two code screens, `10b Confirm email` and
/// `10 Verify code`: an optional banner, the six boxes, Verify, and the
/// "Didn't get the code ? Resend" line with its countdown.
///
/// Stateless — the owning view model holds the code, the problem and the
/// countdown; this only draws them.
class CodeEntrySheet extends StatelessWidget {
  const CodeEntrySheet({
    required this.controller,
    required this.focusNode,
    required this.canSubmit,
    required this.isVerifying,
    required this.onVerify,
    required this.canResend,
    required this.resendClock,
    required this.isResending,
    required this.onResend,
    this.problem,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final CodeProblem? problem;
  final bool canSubmit;
  final bool isVerifying;
  final VoidCallback onVerify;
  final bool canResend;

  /// `m:ss` left before Resend is allowed.
  final String resendClock;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final CodeProblem? current = problem;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (current != null) ...<Widget>[
              switch (current) {
                CodeProblem.invalid => InlineBanner(
                    title: l10n.codeInvalidTitle,
                    message: l10n.codeInvalidBody,
                  ),
                CodeProblem.expired => InlineBanner(
                    title: l10n.codeExpiredTitle,
                    message: l10n.codeExpiredBody,
                  ),
              },
              SizedBox(height: AppSpacing.md.dh),
            ],
            Text(
              l10n.verificationCodeLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xs2.dh),
            CodeInput(
              controller: controller,
              focusNode: focusNode,
              length: InputRules.verificationCodeLength,
              hasError: current == CodeProblem.invalid,
              enabled: !isVerifying,
              // Submitting on the last digit saves a reach for the button,
              // which is the whole reason a code is six separate boxes.
              onCompleted: (_) => onVerify(),
            ),
            // In a mock build no email is ever sent, so the tester is told
            // the code instead. Never shown in a live build.
            if (DataSource.current.isMock) ...<Widget>[
              SizedBox(height: AppSpacing.xs.dh),
              Text(
                l10n.mockCodeHint(MockBackend.code),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: AppSpacing.md.dh),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MainButton(
              label: l10n.verifyAction,
              canBeTapped: canSubmit,
              isLoading: isVerifying,
              onPressed: onVerify,
            ),
            SizedBox(height: AppSpacing.sm.dh),
            // The design keeps the line and greys the link while the wait
            // runs, stating the time in the link itself: "Resend in 0:45".
            PromptRow(
              question: l10n.verifyNoCodePrompt,
              actionLabel: canResend ? l10n.resend : l10n.resendIn(resendClock),
              isLoading: isResending,
              onTap: canResend && !isVerifying ? onResend : null,
            ),
          ],
        ),
      ],
    );
  }
}
