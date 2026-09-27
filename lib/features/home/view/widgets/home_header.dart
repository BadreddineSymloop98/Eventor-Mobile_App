import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/models/account.dart';
import '../../../../core/widgets/atoms/app_avatar.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/molecules/notification_bell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../view_model/home_view_model.dart';

/// The purple head of 11: who you are, your city, and the way into search.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.greeting,
    required this.fullName,
    required this.city,
    required this.hasUnread,
    required this.isChangingCity,
    required this.onBell,
    required this.onCity,
    required this.onSearch,
    required this.onFilters,
    super.key,
  });

  final Greeting greeting;
  final String fullName;
  final Wilaya? city;
  final bool hasUnread;
  final bool isChangingCity;
  final VoidCallback onBell;
  final VoidCallback onCity;
  final VoidCallback onSearch;
  final VoidCallback onFilters;

  static const double _searchHeight = 52;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final Wilaya? current = city;

    return Container(
      color: AppColors.bgBrand,
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        MediaQuery.paddingOf(context).top + AppSpacing.md.dh,
        AppSpacing.md.dw,
        AppSpacing.xl.dh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(name: fullName),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      switch (greeting) {
                        Greeting.morning => l10n.greetingMorning,
                        Greeting.afternoon => l10n.greetingAfternoon,
                        Greeting.evening => l10n.greetingEvening,
                      },
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textOnBrand.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.textOnBrand,
                      ),
                    ),
                  ],
                ),
              ),
              NotificationBell(hasUnread: hasUnread, onTap: onBell),
            ],
          ),
          SizedBox(height: AppSpacing.md.dh),
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: isChangingCity ? null : onCity,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm.dw,
                  vertical: AppSpacing.xs.dh,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadii.fullAll,
                  border: Border.all(color: AppColors.borderOnBrand),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppIcon(AppIcons.mapPin, size: AppSizes.iconMd, color: AppColors.iconOnBrand),
                    SizedBox(width: AppSpacing.xs.dw),
                    Text(
                      current?.nameFor(language) ?? l10n.chooseCity,
                      style: textTheme.labelLarge?.copyWith(color: AppColors.textOnBrand),
                    ),
                    SizedBox(width: AppSpacing.xs.dw),
                    AppIcon(AppIcons.chevronDown, size: AppSizes.iconMd, color: AppColors.iconOnBrand),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md.dh),
          Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: onSearch,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: _searchHeight.dh,
                      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: AppRadii.mdAll,
                      ),
                      child: Row(
                        children: <Widget>[
                          AppIcon(AppIcons.search, size: AppSizes.iconMd, color: AppColors.iconDefault),
                          SizedBox(width: AppSpacing.xs.dw),
                          Expanded(
                            child: Text(
                              l10n.homeSearchHint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.xs.dw),
              Semantics(
                button: true,
                label: l10n.homeFiltersLabel,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onFilters,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: _searchHeight.dh,
                    height: _searchHeight.dh,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: AppRadii.mdAll,
                    ),
                    child: AppIcon(AppIcons.filter, color: AppColors.iconBrand),
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
