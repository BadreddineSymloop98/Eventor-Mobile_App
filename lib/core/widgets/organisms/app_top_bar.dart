import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';
import '../molecules/back_icon_button.dart';

/// The plain white app bar of an inner screen — the design's `App Bar`.
///
/// Back chevron, title, and an optional trailing action, on white with a
/// hairline underneath. 12/16 padding, 12 between the pieces. It mirrors with
/// the language like every other top bar in the app.
///
/// Implements [PreferredSizeWidget] so it drops into `Scaffold.appBar`; the
/// status bar inset is added on top of the design's 48.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actionIcon,
    this.onAction,
    this.actionLabel,
    super.key,
  });

  static const double _height = 48;

  final String title;
  final bool showBack;

  /// Defaults to popping the route.
  final VoidCallback? onBack;

  final AppIcons? actionIcon;
  final VoidCallback? onAction;

  /// What the action does, for screen readers.
  final String? actionLabel;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final AppIcons? icon = actionIcon;

    return Material(
      color: AppColors.bgSurface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: _height,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
          ),
          padding: EdgeInsetsDirectional.symmetric(
            // The back button carries its own 48pt target, which already
            // contains most of the 16 inset.
            horizontal: AppSpacing.xs.dw,
          ),
          child: Row(
            children: <Widget>[
              if (showBack)
                BackIconButton(onPressed: onBack, color: AppColors.iconDefault)
              else
                SizedBox(width: AppSpacing.xs.dw),
              SizedBox(width: AppSpacing.xs2.dw),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ),
              if (icon != null)
                Semantics(
                  button: true,
                  label: actionLabel,
                  child: GestureDetector(
                    onTap: onAction,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox.square(
                      dimension: AppSizes.touchTarget.dw,
                      child: Center(child: AppIcon(icon)),
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
