import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_spinner.dart';

/// A question and the answer that acts on it, on one line under a screen's
/// main button — "Already have an account ? Log in".
///
/// Both halves are set at the same size on purpose. The line is one sentence,
/// and only colour and weight say which half is tappable; sizing the action
/// larger would break the sentence into two competing pieces.
///
/// This is not a [MainButton]: a ghost button carries a button's metrics and
/// its own label size, which is exactly what pulls the two halves apart.
class PromptRow extends StatelessWidget {
  const PromptRow({
    required this.question,
    required this.actionLabel,
    required this.onTap,
    this.isLoading = false,
    super.key,
  });

  /// The half that only reads.
  final String question;

  /// The half that acts.
  final String actionLabel;

  /// Tapped callback, or `null` while the action is unavailable — the label
  /// then reads as part of the sentence rather than as something to press.
  final VoidCallback? onTap;

  /// Whether the action this row started is still running.
  ///
  /// The label gives way to a spinner in its place, so the progress shows on
  /// the control that was actually tapped.
  final bool isLoading;

  bool get _isInteractive => onTap != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // The one size both halves are set at.
    final TextStyle? base = theme.textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Text(
            question,
            style: base?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        SizedBox(width: AppSpacing.xs2.dw),
        // Deliberately not flexible: the action is a word or two and should
        // sit right beside its question. Giving it a share of the row's width
        // would push the two halves to opposite ends of the line. When space
        // runs short the question above wraps instead.
        Semantics(
          button: _isInteractive,
          // While it spins there is no label to read, so one is supplied here;
          // otherwise the child Text already provides it.
          label: isLoading ? actionLabel : null,
          child: GestureDetector(
            onTap: _isInteractive ? onTap : null,
            // Opaque so the padded area takes the tap, not just the glyphs.
            behavior: HitTestBehavior.opaque,
            child: Container(
              // A finger-sized target around a short word, without setting
              // the word itself any larger than its question.
              constraints: BoxConstraints(minHeight: AppSizes.controlSm.dh),
              alignment: Alignment.center,
              child: isLoading
                  ? const AppSpinner(size: AppSizes.iconSm)
                  : Text(
                      actionLabel,
                      style: base?.copyWith(
                        color: _isInteractive
                            ? AppColors.textBrand
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
