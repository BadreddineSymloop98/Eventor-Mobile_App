import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';

/// The pale purple note with a glyph at its start — B5's policy note, B6's
/// hold notice, B9's "why this day is greyed out".
class NoteCallout extends StatelessWidget {
  const NoteCallout({
    required this.text,
    this.icon = AppIcons.check,
    super.key,
  });

  final String text;
  final AppIcons icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.sm.dh,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgBrandSubtle,
        borderRadius: AppRadii.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(icon, size: AppSizes.iconMd, color: AppColors.iconBrand),
          SizedBox(width: AppSpacing.xs.dw),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
