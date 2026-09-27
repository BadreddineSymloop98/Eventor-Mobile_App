import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_spinner.dart';

/// How much weight a button carries — the design's `Style`.
enum MainButtonStyle {
  /// A filled button. The one action a screen is asking for.
  primary,

  /// Outlined. A real alternative to the primary action rather than a way out
  /// of the screen — "I already have an account" beside "Create an account".
  secondary,

  /// No fill and no border — just the label. For the secondary way out of a
  /// screen, like skipping onboarding.
  ghost,
}

/// What the button is sitting on, or what it does — the design's `Tone`.
enum MainButtonTone {
  /// On a light surface.
  normal,

  /// On a dark surface — a photograph or the brand fill. "Tone=Inverse".
  inverse,

  /// A destructive action: delete, cancel a booking, sign out everywhere. The
  /// design is explicit that this is the *only* correct way to draw one —
  /// never a hand-applied red.
  danger,
}

/// The app's button — the design's `Button`, all 45 variants.
///
/// Style × tone × state, where the state is worked out here rather than passed
/// in: *pressed* while a finger is down, *focus* while it holds keyboard
/// focus, *loading* from [isLoading], *disabled* when it cannot be tapped.
///
/// There is no ripple. Every state is a colour the design specifies —
/// `bg/brand-pressed`, `bg/surface-pressed`, `bg/danger-pressed`, the subtle
/// washes — so the press shows as a change of fill, exactly as drawn.
class MainButton extends StatefulWidget {
  const MainButton({
    required this.label,
    required this.onPressed,
    this.style = MainButtonStyle.primary,
    this.tone = MainButtonTone.normal,
    this.icon,
    this.canBeTapped = true,
    this.isLoading = false,
    this.flushStart = false,
    super.key,
  });

  /// Text shown inside the button.
  final String label;

  /// Tapped callback. When `null` the button renders and behaves as disabled.
  final VoidCallback? onPressed;

  final MainButtonStyle style;
  final MainButtonTone tone;

  /// Optional leading glyph — the design's `Show icon` / `Icon` properties.
  final AppIcons? icon;

  /// Whether the button currently accepts taps.
  ///
  /// Set it to `false` to grey the button out while an action is unavailable —
  /// an incomplete form, for instance — without having to strip [onPressed] at
  /// the call site.
  final bool canBeTapped;

  /// Whether the action this button started is still running.
  ///
  /// A spinner appears beside the label — the design keeps the label — and
  /// taps stop landing, so the work cannot be started twice. The colours stay
  /// the enabled ones: a greyed-out spinner reads as broken rather than busy.
  final bool isLoading;

  /// Drops the leading padding so the *label* lines up with the screen's
  /// margin rather than the button's box. For a ghost button sitting at the
  /// edge of a top bar, like Skip — measured to the glyph, not the box.
  final bool flushStart;

  @override
  State<MainButton> createState() => _MainButtonState();
}

class _MainButtonState extends State<MainButton> {
  /// The wash drawn over a photograph when an inverse outlined or ghost button
  /// is pressed. The design draws these as solid white under a white label —
  /// which would hide the label — so the value was set to 16% white instead.
  static const double _inversePressedAlpha = 0.16;

  bool _isPressed = false;
  bool _isFocused = false;

  bool get _isEnabled => widget.canBeTapped && widget.onPressed != null;

  /// Whether a tap does anything.
  bool get _isInteractive => _isEnabled && !widget.isLoading;

  /// Whether it is *drawn* as available — see [MainButton.isLoading].
  bool get _looksEnabled => _isEnabled || widget.isLoading;

  bool get _isPrimary => widget.style == MainButtonStyle.primary;
  bool get _isSecondary => widget.style == MainButtonStyle.secondary;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  void _activate() {
    if (!_isInteractive) return;
    HapticFeedback.selectionClick();
    widget.onPressed?.call();
  }

  Color? get _background {
    final MainButtonTone tone = widget.tone;
    final bool pressed = _isPressed && _isInteractive;

    if (!_looksEnabled) {
      if (_isPrimary) return AppColors.bgDisabled;
      if (_isSecondary && tone != MainButtonTone.inverse) {
        return AppColors.bgSurface;
      }
      return null;
    }

    if (_isPrimary) {
      return switch (tone) {
        MainButtonTone.normal =>
          pressed ? AppColors.bgBrandPressed : AppColors.bgBrand,
        MainButtonTone.inverse =>
          pressed ? AppColors.bgSurfacePressed : AppColors.bgSurface,
        MainButtonTone.danger =>
          pressed ? AppColors.bgDangerPressed : AppColors.bgDanger,
      };
    }

    // Secondary and ghost share their pressed wash; only secondary has a
    // resting fill, and only on a light surface.
    if (pressed) {
      return switch (tone) {
        MainButtonTone.normal => AppColors.bgBrandSubtle,
        MainButtonTone.inverse =>
          AppColors.bgSurface.withValues(alpha: _inversePressedAlpha),
        MainButtonTone.danger => AppColors.bgDangerSubtle,
      };
    }
    if (_isSecondary && widget.tone != MainButtonTone.inverse) {
      return AppColors.bgSurface;
    }
    return null;
  }

  Color? get _border {
    if (!_isSecondary) return null;
    if (!_looksEnabled) return AppColors.borderDefault;
    return switch (widget.tone) {
      MainButtonTone.normal => AppColors.borderBrand,
      MainButtonTone.inverse => AppColors.borderOnBrand,
      MainButtonTone.danger => AppColors.borderDanger,
    };
  }

  Color get _foreground {
    final MainButtonTone tone = widget.tone;

    if (!_looksEnabled) {
      // On a photograph the usual grey would vanish, so an inverse outlined or
      // ghost button fades to the lighter disabled grey instead.
      return tone == MainButtonTone.inverse && !_isPrimary
          ? AppColors.textDisabled
          : AppColors.textSecondary;
    }

    if (_isPrimary) {
      return switch (tone) {
        MainButtonTone.normal => AppColors.textOnBrand,
        MainButtonTone.inverse => AppColors.textBrand,
        MainButtonTone.danger => AppColors.textOnDanger,
      };
    }
    return switch (tone) {
      MainButtonTone.normal => AppColors.textBrand,
      MainButtonTone.inverse => AppColors.textOnBrand,
      MainButtonTone.danger => AppColors.textDanger,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = _foreground;
    final Color? border = _border;
    final AppIcons? icon = widget.icon;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.isLoading) ...<Widget>[
          AppSpinner(color: foreground),
          SizedBox(width: AppSpacing.xs.dw),
        ] else if (icon != null) ...<Widget>[
          AppIcon(icon, size: AppSizes.iconMd, color: foreground),
          SizedBox(width: AppSpacing.xs.dw),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _isInteractive,
      // The child Text already carries the label; setting it here too would
      // make screen readers announce it twice.
      child: FocusableActionDetector(
        enabled: _isInteractive,
        mouseCursor: _isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (bool value) =>
            setState(() => _isFocused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _isInteractive ? (_) => _setPressed(true) : null,
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: _isInteractive ? _activate : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            // The design binds every button to this height. It is 4 under
            // Material's recommended tap target, which is the design's call —
            // it matches Apple's 44pt minimum and the buttons are wide.
            constraints: BoxConstraints(minHeight: AppSizes.controlMd.dh),
            padding: EdgeInsetsDirectional.only(
              start: widget.flushStart ? 0 : AppSpacing.xl.dw,
              end: AppSpacing.xl.dw,
              top: AppSpacing.xs.dh,
              bottom: AppSpacing.xs.dh,
            ),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: AppRadii.mdAll,
              border: border == null ? null : Border.all(color: border),
              boxShadow: _isFocused && _isInteractive
                  ? AppElevation.focusRing
                  : null,
            ),
            // Width factor 1: the button hugs its label unless its parent
            // stretches it (a full-width column). A plain `alignment` would
            // make it fill any loose width — a link-sized ghost button inside
            // an `Align` would span the whole row.
            child: Align(
              alignment: widget.flushStart
                  ? AlignmentDirectional.centerStart
                  : Alignment.center,
              widthFactor: 1,
              heightFactor: 1,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
