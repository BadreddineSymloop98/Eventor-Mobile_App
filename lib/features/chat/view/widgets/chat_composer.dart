import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/messaging/picked_image.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../l10n/app_localizations.dart';

/// 15's composer: "+", the field and Send, with the picked photo's chip
/// above them.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.hint,
    required this.canAttach,
    required this.canSend,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
    required this.maxLength,
    this.attachment,
    super.key,
  });

  static const double _button = 40;
  static const double _thumb = 64;
  static const double _disabledOpacity = 0.4;

  final TextEditingController controller;
  final String hint;
  final bool canAttach;
  final bool canSend;
  final PickedImage? attachment;
  final VoidCallback onAttach;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onSend;

  /// The server's cap on a message body.
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final PickedImage? picked = attachment;

    return _ComposerFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (picked != null) ...<Widget>[
            Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: AppRadii.smAll,
                  child: Image.memory(
                    picked.bytes,
                    width: _thumb.dw,
                    height: _thumb.dw,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: AppSpacing.sm.dw),
                Expanded(
                  child: Text(
                    picked.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.chatRemoveAttachment,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onRemoveAttachment,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox.square(
                      dimension: AppSizes.touchTarget.dw,
                      child: const Center(
                        child: AppIcon(
                          AppIcons.close,
                          size: AppSizes.iconMd,
                          color: AppColors.iconDefault,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs.dh),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (canAttach) ...<Widget>[
                _RoundButton(
                  label: l10n.chatAttach,
                  color: AppColors.bgCanvas,
                  onTap: onAttach,
                  child: const AppIcon(
                    AppIcons.plus,
                    size: AppSizes.iconMd,
                    color: AppColors.iconDefault,
                  ),
                ),
                SizedBox(width: AppSpacing.xs.dw),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: maxLength,
                  // The cap is a safety net, not something to count down.
                  buildCounter: (
                    BuildContext context, {
                    required int currentLength,
                    required bool isFocused,
                    required int? maxLength,
                  }) => null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: textTheme.bodyMedium,
                  decoration: _fieldDecoration(hint),
                ),
              ),
              SizedBox(width: AppSpacing.xs.dw),
              Opacity(
                opacity: canSend ? 1 : _disabledOpacity,
                child: _RoundButton(
                  label: l10n.chatSend,
                  color: AppColors.bgBrand,
                  onTap: canSend ? onSend : null,
                  child: const AppIcon(
                    AppIcons.chevronRight,
                    size: AppSizes.iconMd,
                    color: AppColors.iconOnBrand,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What replaces the composer when nobody can write: one full-width field
/// carrying the notice (Figma `Composer · closed`).
class ClosedComposer extends StatelessWidget {
  const ClosedComposer({required this.notice, super.key});

  final String notice;

  @override
  Widget build(BuildContext context) {
    return _ComposerFrame(
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: 14.dw,
          vertical: 10.dh,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgCanvas,
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        child: Text(
          notice,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hint) {
  const OutlineInputBorder border = OutlineInputBorder(
    borderRadius: AppRadii.fullAll,
    borderSide: BorderSide(color: AppColors.borderDefault),
  );
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: AppColors.bgCanvas,
    contentPadding: EdgeInsetsDirectional.symmetric(
      horizontal: 14.dw,
      vertical: 10.dh,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.borderBrand),
    ),
  );
}

/// Surface, a hairline on top, 10/16/24/16 — the bottom inset only while
/// the keyboard is down (it sits on the keyboard otherwise).
class _ComposerFrame extends StatelessWidget {
  const _ComposerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        10.dh,
        AppSpacing.md.dw,
        (keyboardUp ? AppSpacing.sm.dh : AppSpacing.xl.dh) +
            (keyboardUp ? 0 : MediaQuery.paddingOf(context).bottom),
      ),
      child: child,
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.label,
    required this.color,
    required this.child,
    required this.onTap,
  });

  static const double _size = ChatComposer._button;

  final String label;
  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: _size.dw,
          height: _size.dw,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: child,
        ),
      ),
    );
  }
}
