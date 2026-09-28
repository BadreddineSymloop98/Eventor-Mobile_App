import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';

/// `−  [ 185 ]  +` — a count that can be typed as well as stepped: B1's and
/// B9's guests. The buttons move it by one; an empty field is `null`.
///
/// [max] is not enforced while typing — a number over it stays, so the form
/// can say why it is refused ([hasError]) — but + stops at it. Borders follow
/// `AppTextField`: brand while focused, `statusDeclined` on an error.
class QuantityInput extends StatefulWidget {
  const QuantityInput({
    required this.value,
    required this.onChanged,
    required this.max,
    this.min = 1,
    this.hasError = false,
    this.label,
    super.key,
  });

  final int? value;

  /// `null` disables the field and both buttons.
  final ValueChanged<int?>? onChanged;
  final int min;
  final int max;
  final bool hasError;

  /// What is being counted, for screen readers — "Guests".
  final String? label;

  @override
  State<QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  static const double _emphasisBorder = 1.5;

  late final TextEditingController _controller = TextEditingController(
    text: _text(widget.value),
  );
  final FocusNode _focusNode = FocusNode();

  static String _text(int? value) => value == null ? '' : '$value';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(QuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Stepped with a button, or reset from outside: show the new count. While
    // typing the text already matches, so the cursor is left where it is.
    if (int.tryParse(_controller.text) != widget.value) {
      final String text = _text(widget.value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ValueChanged<int?>? change = widget.onChanged;
    final int? value = widget.value;
    final bool focused = _focusNode.hasFocus;

    Widget button(String glyph, String semantics, int? next) {
      final bool enabled = change != null && next != null;
      return Semantics(
        button: true,
        enabled: enabled,
        label: semantics,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: enabled ? () => change(next) : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: AppSizes.touchTarget.dw,
            height: AppSizes.touchTarget.dw,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: AppRadii.lgAll,
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              glyph,
              style: textTheme.titleMedium?.copyWith(
                color: enabled ? AppColors.textBrand : AppColors.textDisabled,
              ),
            ),
          ),
        ),
      );
    }

    // − stops at the minimum (an empty field has nothing to take from); +
    // starts an empty field at the minimum and stops at the cap.
    final int? down = value != null && value > widget.min ? value - 1 : null;
    final int? up = value == null
        ? widget.min
        : value < widget.max
        ? value + 1
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        button('−', context.l10n.stepperLess, down),
        SizedBox(width: AppSpacing.xs.dw),
        Container(
          width: (AppSizes.touchTarget + AppSpacing.md).dw,
          height: AppSizes.touchTarget.dw,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs2.dw),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadii.mdAll,
            border: Border.all(
              color: widget.hasError
                  ? AppColors.statusDeclined
                  : focused
                  ? AppColors.borderBrand
                  : AppColors.borderDefault,
              width: widget.hasError || focused ? _emphasisBorder : 1,
            ),
          ),
          // Read with what it counts, like the stepper it replaces.
          child: Semantics(
            label: widget.label,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: change != null,
              onChanged: (String text) => change?.call(int.tryParse(text)),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                // No leading zero: a count starts at one, and "007" is 7.
                TextInputFormatter.withFunction(
                  (TextEditingValue old, TextEditingValue next) =>
                      next.text.startsWith('0') ? old : next,
                ),
                // One digit past the cap, so an over-the-cap count can still be
                // typed and explained rather than silently stopped.
                LengthLimitingTextInputFormatter('${widget.max}'.length + 1),
              ],
              style: textTheme.labelLarge?.copyWith(color: AppColors.textBrand),
              cursorColor: AppColors.borderBrand,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '—',
                hintStyle: textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.xs.dw),
        button('+', context.l10n.stepperMore, up),
      ],
    );
  }
}
