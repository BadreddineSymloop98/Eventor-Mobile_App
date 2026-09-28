import 'package:flutter/material.dart';

import '../../catalog/models/provider.dart';
import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_avatar.dart';
import '../atoms/app_icon.dart';

/// The provider behind a service or pack, on 12 and 20 — avatar, name,
/// "Category · 6 years in business", and how fast they reply when the API
/// knows. Opens their profile (13).
class ProviderMiniCard extends StatelessWidget {
  const ProviderMiniCard({required this.provider, required this.onTap, super.key});

  final ProviderSummary provider;
  final VoidCallback onTap;

  static const double _dot = 6;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final int? years = provider.yearsActive;
    final String? replyTime = provider.replyTime;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppElevation.sm,
          ),
          child: Row(
            children: <Widget>[
              AppAvatar(
                name: provider.businessName,
                photoUrl: provider.avatarUrl,
                size: AppAvatarSize.large,
              ),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      provider.businessName,
                      style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                    ),
                    Text(
                      <String>[
                        ?provider.category?.name.of(language),
                        if (years != null) context.l10n.yearsInBusiness(years),
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    if (replyTime != null)
                      Row(
                        children: <Widget>[
                          Container(
                            width: _dot.dw,
                            height: _dot.dw,
                            decoration: const BoxDecoration(
                              color: AppColors.statusAccepted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: AppSpacing.xs2.dw),
                          Text(
                            context.l10n.repliesIn(replyTime),
                            style: textTheme.labelSmall?.copyWith(color: AppColors.statusAccepted),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              AppIcon(AppIcons.chevronRight, size: AppSizes.iconMd, color: AppColors.iconDefault),
            ],
          ),
        ),
      ),
    );
  }
}
