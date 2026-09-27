import 'package:flutter/material.dart';

import '../../constants/input_rules.dart';
import '../../constants/ui_helpers.dart';

/// A row of single-digit boxes for entering a verification code.
///
/// The boxes are only a drawing. Underneath them sits one ordinary, invisible
/// [TextField] holding the whole code, which is what makes paste, the
/// keyboard's own suggestions and the platform's SMS autofill work — none of
/// which survive being split across six separate fields.
///
/// Always laid out left to right. A code is a number, and the box the next
/// digit lands in should not move because the interface language did.
class CodeInput extends StatefulWidget {
  const CodeInput({
    required this.controller,
    this.focusNode,
    this.length = InputRules.verificationCodeLength,
    this.onCompleted,
    this.hasError = false,
    this.enabled = true,
    super.key,
  });

  /// Design size of one box.
  static const double _boxWidth = 48;
  static const double _boxHeight = 52;

  final TextEditingController controller;
  final FocusNode? focusNode;

  /// How many digits the code has.
  final int length;

  /// Called once the last box is filled, so the caller can submit without the
  /// user having to reach for the button.
  final ValueChanged<String>? onCompleted;

  /// Outlines every box in the danger colour — the design's wrong-code state
  /// (10c). Cleared by the caller as soon as the code is edited.
  final bool hasError;

  /// `false` stops input, for while a code is being checked.
  final bool enabled;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  late FocusNode _focusNode;
  FocusNode? _ownedFocusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? (_ownedFocusNode = FocusNode());
    _focusNode.addListener(_onChanged);
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onSubmittedDigit(String value) {
    if (value.length == widget.length) widget.onCompleted?.call(value);
  }

  /// The box the next digit will land in, or `null` once the code is full.
  int? get _activeIndex {
    final int filled = widget.controller.text.length;
    if (!_focusNode.hasFocus || filled >= widget.length) return null;
    return filled;
  }

  @override
  Widget build(BuildContext context) {
    final String code = widget.controller.text;

    return Stack(
      children: <Widget>[
        // Left to right whatever the app's language, so digit one is always
        // the leftmost box.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(
              widget.length,
              (int index) => _DigitBox(
                digit: index < code.length ? code[index] : null,
                isActive: index == _activeIndex,
                hasError: widget.hasError,
              ),
            ),
          ),
        ),
        // The real field, laid over the boxes and invisible. It carries the
        // whole code; the boxes above are painted from its value.
        Positioned.fill(
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            inputFormatters: InputRules.verificationCodeFormatters,
            autofillHints: const <String>[AutofillHints.oneTimeCode],
            onChanged: _onSubmittedDigit,
            textInputAction: TextInputAction.done,
            // Invisible, but still a real field: selection is disabled so the
            // caret cannot be dragged into the middle of the code.
            showCursor: false,
            enableInteractiveSelection: false,
            cursorColor: Colors.transparent,
            style: const TextStyle(color: Colors.transparent, height: 0.01),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              // Blocks the long-press toolbar, which would otherwise appear
              // over boxes that look like they hold nothing.
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.removeListener(_onChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }
}

/// One box, holding one digit or waiting for it.
class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.digit,
    required this.isActive,
    required this.hasError,
  });

  final String? digit;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CodeInput._boxWidth.dw,
      height: CodeInput._boxHeight.dh,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        // The box waiting for the next digit is outlined in brand at 2px —
        // the design's way of showing where typing will land, since there is
        // no caret to see.
        // A wrong code outlines every box in danger at 1px (10c); it
        // outranks the active box, since the whole code is what was wrong.
        border: Border.all(
          color: hasError
              ? AppColors.borderDanger
              : isActive
                  ? AppColors.borderBrand
                  : AppColors.borderDefault,
          width: isActive && !hasError ? 2 : 1,
        ),
      ),
      child: Text(
        digit ?? '',
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
