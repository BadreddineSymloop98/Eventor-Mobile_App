import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/formatting/chat_time_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/localization/messaging_labels.dart';
import '../../../../core/messaging/models/conversation.dart';
import '../../../../core/widgets/atoms/app_avatar.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/skeleton.dart';
import '../../../../core/widgets/molecules/conversation_avatar.dart';
import '../../../../l10n/app_localizations.dart';

/// One conversation on 14: avatar, name, last message, time and the unread
/// count.
class ConversationTile extends StatelessWidget {
  const ConversationTile({required this.row, required this.onTap, super.key});

  static const double _badge = 20;

  final ConversationRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String locale = Localizations.localeOf(context).languageCode;
    final bool unread = row.unreadCount > 0;
    final Color previewColor = unread
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final TextStyle? previewStyle = textTheme.bodySmall?.copyWith(
      color: previewColor,
    );
    final DateTime? at = row.lastMessageAt;

    final Widget preview = switch (row.previewKind) {
      PreviewKind.text => Text(
        row.lastMessageMine
            ? l10n.messagesPreviewMine(row.lastMessage ?? '')
            : row.lastMessage ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: previewStyle,
      ),
      PreviewKind.photo => Row(
        children: <Widget>[
          AppIcon(AppIcons.image, size: AppSizes.iconSm, color: previewColor),
          SizedBox(width: AppSpacing.xs2.dw),
          Flexible(
            child: Text(
              row.lastMessageMine ? l10n.messagesPreviewMine(l10n.chatPhoto) : l10n.chatPhoto,
              style: previewStyle,
            ),
          ),
        ],
      ),
      PreviewKind.removed => Text(
        l10n.chatRemoved,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: previewStyle,
      ),
      PreviewKind.none => Text('', style: previewStyle),
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md.dw,
          vertical: 14.dh,
        ),
        child: Row(
          children: <Widget>[
            ConversationAvatar(
              kind: row.kind,
              other: row.other,
              size: AppAvatarSize.list,
            ),
            SizedBox(width: AppSpacing.sm.dw),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.conversationTitle(row),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.dh),
                  preview,
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm.dw),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (at != null)
                  Text(
                    listTime(
                      at,
                      now: DateTime.now(),
                      locale: locale,
                      yesterday: l10n.chatYesterday,
                    ),
                    // A time is its own left-to-right run in an Arabic row.
                    textDirection: TextDirection.ltr,
                    style: textTheme.labelSmall?.copyWith(
                      color: unread
                          ? AppColors.textBrand
                          : AppColors.textSecondary,
                    ),
                  ),
                SizedBox(height: 6.dh),
                if (unread)
                  Semantics(
                    label: l10n.messagesUnreadCount(row.unreadCount),
                    excludeSemantics: true,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: _badge.dw,
                        minHeight: _badge.dw,
                      ),
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.xs2.dw,
                      ),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.bgBrand,
                        borderRadius: AppRadii.fullAll,
                      ),
                      child: Text(
                        '${row.unreadCount}',
                        textDirection: TextDirection.ltr,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textOnBrand,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox.square(dimension: _badge.dw),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// G1's list-row skeleton: three rows the size of real ones.
class ConversationTileSkeleton extends StatelessWidget {
  const ConversationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final double avatar = AppSizes.avatarList.dw;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: 14.dh,
      ),
      child: Row(
        children: <Widget>[
          Skeleton(height: avatar, width: avatar, radius: AppRadii.fullAll),
          SizedBox(width: AppSpacing.sm.dw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Skeleton(height: 14.dh, width: 140.dw),
                SizedBox(height: AppSpacing.xs.dh),
                Skeleton(height: 12.dh),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
