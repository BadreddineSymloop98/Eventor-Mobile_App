import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/ui_helpers.dart';
import '../localization/app_localizations_x.dart';

/// The app's text input, as the design draws it.
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
/// The error state reuses `status/declined` rather than a dedicated error
/// colour — the design is explicit that there is one red, kept consistent.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.focusNode,
    this.hintText,
    this.helperText,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.textDirection,
    this.autofillHints,
    this.inputFormatters,
    this.onSubmitted,
    super.key,
  });

  /// Height of the box the value sits in.
  static const double _fieldHeight = 52;

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
  /// [helperText], which states the rule. Keep the two from repeating each
  /// other: an example belongs here, a constraint belongs underneath.
  final String? hintText;

  /// Instruction under the field, shown only while this field holds the caret
  /// and there is no error to show instead.
  ///
  /// It describes the rule the value still has to meet, so the caller drops it
  /// to `null` once the value meets it — a rule already satisfied is not worth
  /// a line of red under the field.
  final String? helperText;

  /// Validation message, or `null` when the value is acceptable.
  final String? errorText;

  /// Whether the value is secret. When `true` the field starts obscured and
  /// offers a toggle; whether it is *currently* obscured is this widget's own
  /// state.
  final bool obscureText;

  /// Direction of the value itself, independent of the app's direction. The
  /// label and the message below always follow the app, never this.
  final TextDirection? textDirection;

  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;

  /// Rules applied as the user types, so invalid characters never make it into
  /// the value in the first place.
  final List<TextInputFormatter>? inputFormatters;

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

  /// The single line shown under the box, or `null` when there is nothing to
  /// say.
  ///
  /// An error is a verdict on a value already entered, so it stays on screen
  /// until that value changes. The instruction is guidance for the value being
  /// typed, so it comes and goes with the caret.
  String? get _message =>
      widget.errorText ?? (_isFocused ? widget.helperText : null);

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

  /// The box's outline. Red when wrong, brand when being typed into, and the
  /// default grey otherwise.
  Color get _borderColor {
    if (_hasError) return AppColors.statusDeclined;
    if (_isFocused) return AppColors.borderBrand;
    return AppColors.borderDefault;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
        Container(
          height: AppTextField._fieldHeight.dh,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadii.mdAll,
            border: Border.all(
              color: _borderColor,
              width: _isFocused || _hasError ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  obscureText: _isObscured,
                  textInputAction: widget.textInputAction,
                  textDirection: widget.textDirection,
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
                  autofillHints: widget.autofillHints,
                  inputFormatters: widget.inputFormatters,
                  onSubmitted: widget.onSubmitted,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  // The box is drawn by the Container above, so the field
                  // itself contributes no chrome at all.
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hintText,
                    // Lighter than the value, so an empty field never looks
                    // like a filled one.
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
              ),
              if (widget.obscureText) _buildVisibilityToggle(),
            ],
          ),
        ),
        if (_message != null) ...<Widget>[
          SizedBox(height: AppSpacing.xs2.dh),
          Text(
            _message!,
            // Red whether it is an error or an instruction. The instruction
            // states the rule the value has to meet, so it is the same
            // message the error will be — showing it in a quieter colour
            // first would only make the rule easier to miss.
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.statusDeclined,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isObscured = !_isObscured),
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: _isObscured
            ? context.l10n.showPassword
            : context.l10n.hidePassword,
        child: Icon(
          _isObscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: AppSizes.iconMd.dw,
          color: AppColors.iconDefault,
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
