import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';

/// The bell that opens Notifications (`16`), with the "something unread"
/// dot — Home's header (`11`) and anywhere else that needs the same 48
/// touch target.
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    required this.hasUnread,
    required this.onTap,
    super.key,
  });

  final bool hasUnread;
  final VoidCallback onTap;

  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hasUnread
          ? context.l10n.homeNotificationsUnread
          : context.l10n.homeNotificationsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: AppSizes.touchTarget.dw,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              const AppIcon(AppIcons.bell, color: AppColors.iconOnBrandAccent),
              if (hasUnread)
                PositionedDirectional(
                  top: AppSpacing.sm.dw,
                  end: AppSpacing.sm.dw,
                  child: Container(
                    width: _dot.dw,
                    height: _dot.dw,
                    decoration: const BoxDecoration(
                      color: AppColors.statusDeclined,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
