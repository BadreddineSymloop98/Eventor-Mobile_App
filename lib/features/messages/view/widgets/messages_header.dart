import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/messaging/conversation_filter.dart';
import '../../../../core/widgets/atoms/app_chip.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/molecules/notification_bell.dart';
import '../../../../l10n/app_localizations.dart';

/// 14's brand header: the title, the bell and the search field.
class MessagesHeader extends StatelessWidget {
  const MessagesHeader({
    required this.search,
    required this.onSearchChanged,
    required this.hasUnreadNotifications,
    required this.onBell,
    super.key,
  });

  static const double _searchHeight = 48;

  final TextEditingController search;
  final ValueChanged<String> onSearchChanged;
  final bool hasUnreadNotifications;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      color: AppColors.bgBrand,
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        MediaQuery.paddingOf(context).top + AppSpacing.md.dh,
        AppSpacing.md.dw,
        AppSpacing.lg.dh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.messagesTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textOnBrand,
                  ),
                ),
              ),
              NotificationBell(
                hasUnread: hasUnreadNotifications,
                onTap: onBell,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.dh),
          SizedBox(
            height: _searchHeight.dh,
            child: TextField(
              controller: search,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.messagesSearchHint,
                prefixIcon: Padding(
                  padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
                  child: const AppIcon(
                    AppIcons.search,
                    size: AppSizes.iconMd,
                    color: AppColors.iconDefault,
                  ),
                ),
                filled: true,
                fillColor: AppColors.bgSurface,
                contentPadding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md.dw,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: AppRadii.mdAll,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppRadii.mdAll,
                  borderSide: BorderSide(
                    color: AppColors.borderBrand,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// All / Unread / Bookings.
class MessagesFilterChips extends StatelessWidget {
  const MessagesFilterChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ConversationFilter selected;
  final ValueChanged<ConversationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    String label(ConversationFilter filter) => switch (filter) {
      ConversationFilter.all => l10n.messagesFilterAll,
      ConversationFilter.unread => l10n.messagesFilterUnread,
      ConversationFilter.booking => l10n.messagesFilterBookings,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        AppSpacing.md.dh,
        AppSpacing.md.dw,
        AppSpacing.xs2.dh,
      ),
      child: Row(
        children: <Widget>[
          for (final ConversationFilter filter
              in ConversationFilter.values) ...<Widget>[
            if (filter != ConversationFilter.values.first)
              SizedBox(width: AppSpacing.xs.dw),
            AppChip(
              label: label(filter),
              isSelected: filter == selected,
              onTap: () => onSelected(filter),
            ),
          ],
        ],
      ),
    );
  }
}
