import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/chat_time_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/notifications/models/app_notification.dart';
import '../../../core/notifications/notification_icon.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/offline_banner.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/divided_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../messages/view/widgets/conversation_row.dart';
import '../view_model/notifications_view_model.dart';

/// Screen 16 — pushed from the bell, full screen, no tab bar.
///
/// The Arabic header is mirrored like every other screen (D2), though the
/// Figma frame is not.
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  static const double _loadMoreDistance = 300;

  Future<void> _open(BuildContext context, AppNotification n) async {
    final NotificationsViewModel viewModel = context
        .read<NotificationsViewModel>();
    final AppLocalizations l10n = context.l10n;
    // Not awaited: the tap opens its target at once; the dot already flipped.
    unawaited(
      viewModel.markRead(n.id).then((Failure? failure) {
        if (failure != null && context.mounted) {
          showAppToast(
            context,
            l10n.forFailure(failure),
            tone: AppToastTone.error,
          );
        }
      }),
    );
    switch (n.target) {
      case ChatTarget(:final String conversationId):
        await context.push(AppRoutes.chatFor(conversationId));
      case UnsupportedTarget():
        showComingSoon(context, context.l10n.comingSoon);
    }
  }

  Future<void> _markAll(BuildContext context) async {
    final NotificationsViewModel viewModel = context
        .read<NotificationsViewModel>();
    final Failure? failure = await viewModel.markAllRead();
    if (failure != null && context.mounted) {
      showAppToast(
        context,
        context.l10n.forFailure(failure),
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _refresh(BuildContext context) async {
    final NotificationsViewModel viewModel = context
        .read<NotificationsViewModel>();
    final Failure? failure = await viewModel.refresh();
    if (failure != null && !viewModel.isOffline && context.mounted) {
      showAppToast(
        context,
        context.l10n.forFailure(failure),
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final NotificationsViewModel viewModel = context
        .watch<NotificationsViewModel>();

    final List<Widget> content;
    if (viewModel.isFirstLoad) {
      content = <Widget>[
        const DividedCard(
          children: <Widget>[
            ConversationTileSkeleton(),
            ConversationTileSkeleton(),
            ConversationTileSkeleton(),
            ConversationTileSkeleton(),
          ],
        ),
      ];
    } else if (viewModel.sections.isEmpty && viewModel.hasError) {
      content = <Widget>[StateCard.error(onRetry: viewModel.load)];
    } else if (viewModel.isEmpty) {
      content = <Widget>[
        StateCard.empty(
          icon: AppIcons.bell,
          title: l10n.notificationsEmptyTitle,
          body: l10n.notificationsEmptyBody,
        ),
      ];
    } else {
      content = <Widget>[
        if (viewModel.isOffline) ...<Widget>[
          OfflineBanner(
            body: l10n.offlineNotificationsBody,
            onRetry: () => _refresh(context),
          ),
          SizedBox(height: AppSpacing.lg.dh),
        ],
        for (final NotificationSection section
            in viewModel.sections) ...<Widget>[
          _GroupLabel(section.group),
          SizedBox(height: 10.dh),
          DividedCard(
            children: <Widget>[
              for (final AppNotification n in section.items)
                _NotificationItem(n, onTap: () => _open(context, n)),
            ],
          ),
          SizedBox(height: AppSpacing.lg.dh),
        ],
      ];
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        children: <Widget>[
          _Header(
            canMarkAll: viewModel.canMarkAll,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
            onMarkAll: () => _markAll(context),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brand,
              onRefresh: () => _refresh(context),
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification.metrics.extentAfter < _loadMoreDistance.dh) {
                    viewModel.loadMore();
                  }
                  return false;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md.dw,
                    AppSpacing.lg.dh,
                    AppSpacing.md.dw,
                    AppSpacing.xl.dh,
                  ),
                  children: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.canMarkAll,
    required this.onBack,
    required this.onMarkAll,
  });

  final bool canMarkAll;
  final VoidCallback onBack;
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      color: AppColors.bgBrand,
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs2.dw,
        MediaQuery.paddingOf(context).top + AppSpacing.md.dh,
        AppSpacing.md.dw,
        AppSpacing.lg.dh,
      ),
      child: Row(
        children: <Widget>[
          Semantics(
            button: true,
            label: l10n.backLabel,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: SizedBox.square(
                dimension: AppSizes.touchTarget.dw,
                child: const Center(
                  child: AppIcon(
                    AppIcons.chevronLeft,
                    color: AppColors.iconOnBrand,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.notificationsTitle,
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.textOnBrand,
              ),
            ),
          ),
          if (canMarkAll)
            GestureDetector(
              onTap: onMarkAll,
              behavior: HitTestBehavior.opaque,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: AppSizes.touchTarget.dh),
                child: Center(
                  child: Text(
                    l10n.notificationsMarkAll,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textOnBrandAccent,
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

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.group);

  final NotificationGroup group;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final String label = switch (group) {
      NotificationGroup.today => l10n.notificationsToday,
      NotificationGroup.thisWeek => l10n.notificationsThisWeek,
      NotificationGroup.earlier => l10n.notificationsEarlier,
    };
    return Text(
      // Arabic has no capitals.
      locale.languageCode == 'ar' ? label : label.toUpperCase(),
      style: AppTextStyles.overlineForLocale(locale)
          .copyWith(color: AppColors.textSecondary),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem(this.notification, {required this.onTap});

  static const double _tile = 40;
  static const double _dot = 8;

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String locale = Localizations.localeOf(context).languageCode;
    final bool unread = !notification.read;

    return Semantics(
      button: true,
      label: unread
          ? '${notification.title}, ${l10n.notificationUnread}'
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.dw),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: _tile.dw,
                height: _tile.dw,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.bgBrandSubtle,
                  borderRadius: AppRadii.mdAll,
                ),
                child: AppIcon(
                  notificationIcon(notification.type),
                  size: AppSizes.iconMd,
                  color: AppColors.iconBrand,
                ),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      notification.title,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.dh),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2.dh),
                    Text(
                      listTime(
                        notification.createdAt,
                        now: DateTime.now(),
                        locale: locale,
                        yesterday: l10n.chatYesterday,
                      ),
                      textDirection: TextDirection.ltr,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              Container(
                width: _dot.dw,
                height: _dot.dw,
                decoration: BoxDecoration(
                  color: unread ? AppColors.bgBrand : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
