import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import 'app_icon.dart';

/// "Verified provider" — on 12, 13 and a provider's cards. Gold on its pale
/// wash, as the design draws it, so it reads as a distinction rather than a
/// status.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs.dw,
        vertical: AppSpacing.xs2.dh,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgAccentSubtle,
        borderRadius: AppRadii.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(
            AppIcons.check,
            size: AppSizes.iconSm,
            color: AppColors.iconAccent,
          ),
          SizedBox(width: AppSpacing.xs2.dw),
          Text(
            context.l10n.verifiedProvider,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textAccent,
                ),
          ),
        ],
      ),
    );
  }
}
