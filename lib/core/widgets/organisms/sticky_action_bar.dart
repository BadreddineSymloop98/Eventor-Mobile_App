import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import '../molecules/main_button.dart';

/// The bar pinned to the bottom of 12, 13 and 20: the price (or the reply
/// time) on one side, the actions on the other.
///
/// Per §4.7: 12/16/24/16, a hairline on top, `elevation/md`. The bottom
/// system inset is added on top of the design's 24.
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({required this.leading, required this.actions, super.key});

  /// "Not taking new bookings" — what replaces the booking button when the
  /// provider paused bookings (13's drawn state, used on 12 and 20 too).
  /// Messaging still works.
  factory StickyActionBar.notAccepting({
    required VoidCallback onMessage,
    Key? key,
  }) =>
      StickyActionBar(
        key: key,
        leading: const _NotAcceptingNote(),
        actions: <Widget>[
          Builder(
            builder: (BuildContext context) => MainButton(
              label: context.l10n.sendMessage,
              onPressed: onMessage,
            ),
          ),
        ],
      );

  final Widget leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: const Border(top: BorderSide(color: AppColors.borderDefault)),
        boxShadow: AppElevation.md,
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        AppSpacing.sm.dh,
        AppSpacing.md.dw,
        AppSpacing.xl.dh + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: leading),
          for (final Widget action in actions) ...<Widget>[
            SizedBox(width: AppSpacing.xs.dw),
            action,
          ],
        ],
      ),
    );
  }
}

class _NotAcceptingNote extends StatelessWidget {
  const _NotAcceptingNote();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.notAcceptingTitle,
          style: textTheme.titleSmall?.copyWith(color: AppColors.statusPending),
        ),
        Text(
          context.l10n.notAcceptingBody,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// The square outlined message button beside the primary action.
class MessageIconButton extends StatelessWidget {
  const MessageIconButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final double side = AppSizes.controlMd.dh;
    return Semantics(
      button: true,
      label: context.l10n.messageProvider,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: side,
          height: side,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.borderBrand),
          ),
          child: AppIcon(AppIcons.message, size: AppSizes.iconMd, color: AppColors.iconBrand),
        ),
      ),
    );
  }
}
