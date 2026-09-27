import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import '../atoms/icon_tile.dart';
import 'main_button.dart';

/// The design's G2 cards: nothing here yet, or this could not be loaded.
///
/// One of each per list or detail screen, in place of the content — never a
/// full-screen takeover, so the header and navigation stay usable.
class StateCard extends StatelessWidget {
  /// Nothing to show: an icon, a title, a line of explanation, and at most
  /// one way forward.
  const StateCard.empty({
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : _isError = false;

  /// The load failed. [body] is the reason, when there is one worth showing.
  const StateCard.error({
    required VoidCallback onRetry,
    this.body,
    super.key,
  })  : icon = AppIcons.alertTriangle,
        title = null,
        actionLabel = null,
        onAction = onRetry,
        _isError = true;

  final AppIcons icon;
  final String? title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool _isError;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String heading = title ?? context.l10n.stateErrorTitle;
    final String? label = _isError ? context.l10n.stateRetry : actionLabel;
    final VoidCallback? action = onAction;
    final String? explanation = body;

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.xl.dh,
      ),
      decoration: BoxDecoration(
        color: _isError ? AppColors.bgDangerSubtle : AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(
          color: _isError ? AppColors.borderDanger : AppColors.borderDefault,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_isError)
            AppIcon(icon, size: AppSizes.iconLg, color: AppColors.iconDanger)
          else
            IconTile(icon),
          SizedBox(height: AppSpacing.sm.dh),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: _isError ? AppColors.textDanger : AppColors.textPrimary,
            ),
          ),
          if (explanation != null) ...<Widget>[
            SizedBox(height: AppSpacing.xs2.dh),
            Text(
              explanation,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (label != null && action != null) ...<Widget>[
            SizedBox(height: AppSpacing.md.dh),
            MainButton(
              label: label,
              style: MainButtonStyle.secondary,
              tone: _isError ? MainButtonTone.danger : MainButtonTone.normal,
              onPressed: action,
            ),
          ],
        ],
      ),
    );
  }
}
