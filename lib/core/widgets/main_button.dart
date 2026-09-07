import 'package:flutter/material.dart';

import '../constants/ui_helpers.dart';

/// How much weight a button carries.
enum MainButtonStyle {
  /// A filled button. The one action a screen is asking for.
  primary,

  /// Outlined, no fill. A real alternative to the primary action rather than
  /// a way out of the screen — "I already have an account" beside "Create
  /// an account".
  secondary,

  /// No fill and no border — just the label. For the secondary way out of a
  /// screen, like skipping onboarding.
  ghost,
}

/// What the button is sitting on, which decides which way its colours run.
enum MainButtonTone {
  /// On a light surface.
  normal,

  /// On a dark surface — a photograph or the brand fill. The design calls
  /// this "Tone=Inverse".
  inverse,
}

/// The app's button.
///
/// Built from [GestureDetector] + [Container] rather than a Material button,
/// so the pieces a Material button would provide — the button role for
/// screen readers, the disabled state and the tap target — are declared
/// explicitly here.
class MainButton extends StatelessWidget {
  const MainButton({
    required this.label,
    required this.onPressed,
    this.style = MainButtonStyle.primary,
    this.tone = MainButtonTone.normal,
    this.canBeTapped = true,
    this.isLoading = false,
    super.key,
  });

  /// Text shown inside the button.
  final String label;

  /// Tapped callback. When `null` the button renders and behaves as disabled.
  final VoidCallback? onPressed;

  final MainButtonStyle style;
  final MainButtonTone tone;

  /// Whether the button currently accepts taps.
  ///
  /// Defaults to `true`. Set it to `false` to grey the button out while an
  /// action is unavailable — an incomplete form, for instance — without
  /// having to strip [onPressed] at the call site.
  final bool canBeTapped;

  /// Whether the action this button started is still running.
  ///
  /// The label gives way to a spinner and taps stop landing, so the work
  /// cannot be started twice.
  final bool isLoading;

  /// Whether a tap does anything.
  bool get _isInteractive => canBeTapped && onPressed != null && !isLoading;

  /// Whether the button should be *drawn* as available.
  ///
  /// A spinning button is not interactive, but it must not look disabled —
  /// a greyed-out spinner reads as broken rather than as busy.
  bool get _isEnabled => isLoading || (canBeTapped && onPressed != null);
  bool get _isInverse => tone == MainButtonTone.inverse;
  bool get _isGhost => style == MainButtonStyle.ghost;
  bool get _isSecondary => style == MainButtonStyle.secondary;

  /// The outline, or `null` for the styles that have none.
  BoxBorder? _border(ColorScheme colorScheme) {
    if (!_isSecondary) return null;

    final Color color =
        _isInverse ? AppColors.borderOnBrand : AppColors.borderBrand;

    return Border.all(
      color: _isEnabled ? color : color.withValues(alpha: 0.4),
    );
  }

  /// The fill, or `null` for the styles that have none.
  Color? _background(ColorScheme colorScheme) {
    if (_isGhost || _isSecondary) return null;
    if (!_isEnabled) {
      // On a dark surface the usual grey disappears into the photograph, so
      // the disabled fill is a knocked-back white instead.
      return _isInverse
          ? AppColors.bgSurface.withValues(alpha: 0.3)
          : colorScheme.onSurface.withValues(alpha: 0.12);
    }
    return _isInverse ? AppColors.bgSurface : colorScheme.primary;
  }

  Color _foreground(ColorScheme colorScheme) {
    if (!_isEnabled) {
      return _isInverse
          ? AppColors.textOnBrand.withValues(alpha: 0.5)
          : colorScheme.onSurface.withValues(alpha: 0.38);
    }
    if (_isGhost || _isSecondary) {
      return _isInverse ? AppColors.textOnBrand : AppColors.textBrand;
    }
    return _isInverse ? AppColors.textBrand : colorScheme.onPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color foreground = _foreground(theme.colorScheme);

    return Semantics(
      button: true,
      enabled: _isInteractive,
      // While it spins there is no label to read, so one is supplied here;
      // otherwise the child Text already provides it and setting both makes
      // screen readers announce it twice.
      label: isLoading ? label : null,
      child: GestureDetector(
        onTap: _isInteractive ? onPressed : null,
        // Opaque so taps anywhere inside the padding register, not just on
        // the text.
        behavior: HitTestBehavior.opaque,
        child: Container(
          // The design binds every control to this height. It is 4dp under
          // Material's recommended tap target, which is the design's call —
          // it matches Apple's 44pt minimum and the buttons are wide, so the
          // area is comfortable even where the height is not.
          constraints: BoxConstraints(minHeight: AppSizes.controlMd.dh),
          // A ghost button is inset on its trailing edge only, so its label
          // lines up with the screen's own margin instead of floating in from
          // it. Directional, so it mirrors in Arabic.
          padding: _isGhost
              ? EdgeInsetsDirectional.only(
                  end: AppSpacing.xl.dw,
                  top: AppSpacing.xs.dh,
                  bottom: AppSpacing.xs.dh,
                )
              : EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.xl.dw,
                  vertical: AppSpacing.xs.dh,
                ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _background(theme.colorScheme),
            border: _border(theme.colorScheme),
            borderRadius: AppRadii.mdAll,
          ),
          child: isLoading
              ? SizedBox(
                  // Sized to the line the label would have occupied, so the
                  // button does not change height as it starts and stops.
                  width: AppSizes.iconMd.dw,
                  height: AppSizes.iconMd.dw,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: foreground),
                ),
        ),
      ),
    );
  }
}
