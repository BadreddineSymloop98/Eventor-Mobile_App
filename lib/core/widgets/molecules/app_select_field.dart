import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';

/// A field whose value is picked from a list rather than typed — the design's
/// `Select`.
///
/// Same anatomy as `AppTextField` — label above, 52pt box, grey helper or red
/// error below — with the value and a chevron inside the box. Tapping it calls
/// [onTap], which is expected to open a `showSelectionSheet` and write the
/// result back; the field itself holds no state.
class AppSelectField extends StatelessWidget {
  const AppSelectField({
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder,
    this.helperText,
    this.errorText,
    super.key,
  });

  final String label;

  /// What is chosen, already formatted — or `null` for nothing yet, which
  /// shows [placeholder] in the design's Placeholder state.
  final String? value;

  final String? placeholder;
  final String? helperText;
  final String? errorText;

  /// `null` renders the field disabled.
  final VoidCallback? onTap;

  bool get _hasError => errorText != null;
  bool get _isEnabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? message = errorText ?? helperText;
    final String? shown = value ?? placeholder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.xs2.dh),
        Semantics(
          button: true,
          enabled: _isEnabled,
          label: label,
          value: value,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: AppSizes.controlLg.dh,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
              ),
              decoration: BoxDecoration(
                color: _isEnabled ? AppColors.bgSurface : AppColors.bgDisabled,
                borderRadius: AppRadii.mdAll,
                border: Border.all(
                  color: _hasError
                      ? AppColors.statusDeclined
                      : AppColors.borderDefault,
                  width: _hasError ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      shown ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: value == null || !_isEnabled
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs.dw),
                  const AppIcon(AppIcons.chevronDown, size: AppSizes.iconMd),
                ],
              ),
            ),
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
}
