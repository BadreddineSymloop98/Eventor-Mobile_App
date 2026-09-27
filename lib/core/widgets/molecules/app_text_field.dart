import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';

/// The app's text input — the design's `Input`, in all five of its states.
///
/// The label sits *above* the box rather than floating inside it, so it stays
/// readable while the field is being typed into, and the box itself is a plain
/// 52pt rounded rectangle. That is a different shape from Material's
/// `InputDecorator`, which is why this wraps a bare [TextField] and draws the
/// chrome itself.
///
/// It still wraps a real [TextField], so IME, selection handles, the
/// copy/paste toolbar, autofill and password managers all keep working.
///
/// States, as the design draws them:
///
/// * **Default** — white box, 1pt grey border.
/// * **Placeholder** — the same, with the hint in `text/secondary`.
/// * **Focus** — 1.5pt brand border plus the focus ring.
/// * **Error** — 1.5pt `status/declined` border, and the message under the
///   box in the same red.
/// * **Disabled** — grey fill, value in `text/secondary`.
///
/// The line under the box is grey helper text while the value is fine and the
/// red error once it is not — the error replaces the helper, never joins it.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.focusNode,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.textDirection,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  /// Height of the box the value sits in — `size/control-lg`.
  static const double _fieldHeight = AppSizes.controlLg;

  /// Border width while focused or wrong. The design uses 1.5 rather than 2.
  static const double _emphasisBorder = 1.5;

  final TextEditingController controller;

  /// Sits above the box, always visible.
  final String label;

  /// Focus for this field.
  ///
  /// The caller owns and disposes any node it passes; when this is `null` the
  /// widget makes and disposes its own.
  final FocusNode? focusNode;

  /// Shown inside the empty box, in place of the value.
  ///
  /// It shows the *shape* of an acceptable value — `name@example.com`, a phone
  /// written the way it is dialled — which is a different job from
  /// [helperText], which states the rule.
  final String? hintText;

  /// Guidance under the field, in grey. Replaced by [errorText] when there is
  /// one.
  final String? helperText;

  /// Validation message, or `null` when the value is acceptable.
  final String? errorText;

  /// `false` draws the design's Disabled state and stops input.
  final bool enabled;

  /// Whether the value is secret. When `true` the field starts obscured and
  /// offers a show/hide toggle; whether it is *currently* obscured is this
  /// widget's own state.
  final bool obscureText;

  /// Direction of the value itself, independent of the app's direction. The
  /// label and the message below always follow the app, never this.
  final TextDirection? textDirection;

  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<String>? autofillHints;

  /// Rules applied as the user types, so invalid characters never make it into
  /// the value in the first place.
  final List<TextInputFormatter>? inputFormatters;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _isObscured;
  late FocusNode _focusNode;

  /// Set only when this widget created the node, so it disposes just its own.
  FocusNode? _ownedFocusNode;

  bool _isFocused = false;

  bool get _hasError => widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    _focusNode = widget.focusNode ?? (_ownedFocusNode = FocusNode());
    _focusNode.addListener(_onFocusChanged);
    _isFocused = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.obscureText != widget.obscureText) {
      _isObscured = widget.obscureText;
    }

    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);

      if (widget.focusNode != null) {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
        _focusNode = widget.focusNode!;
      } else {
        _focusNode = _ownedFocusNode = FocusNode();
      }

      _focusNode.addListener(_onFocusChanged);
      _onFocusChanged();
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus == _isFocused) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  Color get _borderColor {
    if (!widget.enabled) return AppColors.borderDefault;
    if (_hasError) return AppColors.statusDeclined;
    if (_isFocused) return AppColors.borderBrand;
    return AppColors.borderDefault;
  }

  double get _borderWidth =>
      widget.enabled && (_isFocused || _hasError)
          ? AppTextField._emphasisBorder
          : 1;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? message = widget.errorText ?? widget.helperText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.xs2.dh),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: AppTextField._fieldHeight.dh,
          padding: EdgeInsetsDirectional.only(
            start: AppSpacing.md.dw,
            // The eye toggle carries its own tap target, so the box does not
            // pad beside it as well.
            end: widget.obscureText ? AppSpacing.xs2.dw : AppSpacing.md.dw,
          ),
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.bgSurface : AppColors.bgDisabled,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: _borderColor, width: _borderWidth),
            boxShadow: _isFocused && !_hasError && widget.enabled
                ? AppElevation.focusRing
                : null,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  obscureText: _isObscured,
                  enableSuggestions: !widget.obscureText,
                  autocorrect: !widget.obscureText,
                  textInputAction: widget.textInputAction,
                  textDirection: widget.textDirection,
                  textCapitalization: widget.textCapitalization,
                  // Which way the value *reads* and which side it *starts on*
                  // are different questions. An address or a phone number is
                  // a Latin run and has to be laid out left to right, but it
                  // still belongs on the edge the rest of the form starts
                  // from — otherwise an Arabic form has some fields flush
                  // right and others flush left. `TextAlign.start` cannot say
                  // this: it resolves against the field's own direction, not
                  // the screen's.
                  textAlign: Directionality.of(context) == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                  autofillHints: widget.enabled ? widget.autofillHints : null,
                  inputFormatters: widget.inputFormatters,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  cursorColor: AppColors.borderBrand,
                  // The box is drawn by the container above, so the field
                  // itself contributes no chrome at all.
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hintText,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              if (widget.obscureText) _buildVisibilityToggle(),
            ],
          ),
        ),
        if (message != null) ...<Widget>[
          SizedBox(height: AppSpacing.xs2.dh),
          Text(
            message,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _hasError
                  ? AppColors.statusDeclined
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return Semantics(
      button: true,
      label: _isObscured
          ? context.l10n.showPassword
          : context.l10n.hidePassword,
      child: GestureDetector(
        onTap: widget.enabled
            ? () => setState(() => _isObscured = !_isObscured)
            : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: AppSizes.touchTarget.dw,
          height: AppSizes.touchTarget.dw,
          child: Center(
            child: AppIcon(
              _isObscured ? AppIcons.eye : AppIcons.eyeOff,
              size: AppSizes.iconMd,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }
}
