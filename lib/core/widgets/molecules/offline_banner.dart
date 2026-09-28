import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';

/// The design's accent-subtle callout for a stale list — 14 and 16 while
/// offline, showing what was last cached.
///
/// A plain [Row] rather than one built with `Directional*` pieces: the
/// design's own AR layout for this banner had swapped the icon and the
/// action (spec §6), and a plain row already orders itself by the ambient
/// text direction, which is the corrected order.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.body, required this.onRetry, super.key});

  /// The explanation under the title — what "offline" means on this screen.
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md.dw,
          vertical: AppSpacing.sm.dh,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgAccentSubtle,
          borderRadius: AppRadii.mdAll,
          border: Border.all(color: AppColors.borderAccent),
        ),
        child: Row(
          children: <Widget>[
            const AppIcon(
              AppIcons.alertTriangle,
              size: AppSizes.iconMd,
              color: AppColors.iconAccent,
            ),
            SizedBox(width: AppSpacing.sm.dw),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    context.l10n.offlineTitle,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs2.dh),
                  Text(
                    body,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm.dw),
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: onRetry,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  context.l10n.offlineRetry,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textBrand,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
