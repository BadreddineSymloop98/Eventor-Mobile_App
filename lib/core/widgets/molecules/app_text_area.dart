import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/ui_helpers.dart';

/// A multi-line field with its label above and, under it, a helper line and
/// a live `37/60` counter — B5's reason, B6's "Why the change?", the booking
/// note, the review and problem sheets.
///
/// The box takes the brand border while focused (B5a), like [AppTextField].
class AppTextArea extends StatefulWidget {
  const AppTextArea({
    required this.controller,
    required this.label,
    required this.maxLength,
    this.hintText,
    this.helperText,
    this.errorText,
    this.focusNode,
    this.enabled = true,
    this.minLines = 2,
    this.maxLines = 4,
    this.showCounter = true,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  /// The API's cap; typing stops there.
  final int maxLength;
  final String? hintText;

  /// Grey, beside the counter — "Studio Lumière will see this reason."
  final String? helperText;

  /// Red, in place of the helper.
  final String? errorText;
  final FocusNode? focusNode;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final bool showCounter;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextArea> createState() => _AppTextAreaState();
}

class _AppTextAreaState extends State<AppTextArea> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_redraw);
    widget.controller.addListener(_redraw);
  }

  @override
  void dispose() {
    _focus.removeListener(_redraw);
    widget.controller.removeListener(_redraw);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? error = widget.errorText;
    final String? helper = error ?? widget.helperText;
    final bool focused = _focus.hasFocus;
    final TextStyle? small = textTheme.labelSmall?.copyWith(
      color: error != null ? AppColors.textDanger : AppColors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          widget.label,
          style: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        ),
        SizedBox(height: AppSpacing.xs2.dh),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.bgSurface : AppColors.bgDisabled,
            borderRadius: AppRadii.mdAll,
            border: Border.all(
              color: error != null
                  ? AppColors.borderDanger
                  : focused
                      ? AppColors.borderBrand
                      : AppColors.borderDefault,
              width: error != null || focused ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(widget.maxLength),
            ],
            onChanged: widget.onChanged,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            cursorColor: AppColors.borderBrand,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: widget.hintText,
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        if (helper != null || widget.showCounter) ...<Widget>[
          SizedBox(height: AppSpacing.xs2.dh),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: Text(helper ?? '', style: small)),
              if (widget.showCounter) ...<Widget>[
                SizedBox(width: AppSpacing.xs.dw),
                Text(
                  '${widget.controller.text.characters.length}/${widget.maxLength}',
                  textDirection: TextDirection.ltr,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
