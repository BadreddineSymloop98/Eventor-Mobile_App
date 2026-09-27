import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/messaging/models/conversation.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/offline_banner.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/divided_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/shell_badges.dart';
import '../../shell/view/client_shell.dart';
import '../view_model/messages_view_model.dart';
import 'widgets/conversation_row.dart';
import 'widgets/messages_header.dart';

/// Screen 14 — the Messages tab.
///
/// The list refreshes when the tab comes back into view from a chat, when
/// the app returns to the foreground, and on pull; it never polls (the
/// chat screen is the only one on a timer).
class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  /// The tab's index in the client shell.
  static const int branch = 3;

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late final AppLifecycleListener _lifecycle;

  static const double _loadMoreDistance = 300;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<MessagesViewModel>().refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh(MessagesViewModel viewModel) async {
    final Failure? failure = await viewModel.refresh();
    // Offline is already on screen as the banner; anything else is news.
    if (failure != null && !viewModel.isOffline && mounted) {
      showAppToast(
        context,
        context.l10n.forFailure(failure),
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _open(MessagesViewModel viewModel, ConversationRow row) async {
    await context.push(AppRoutes.chatFor(row.id));
    // Reading the chat changed its unread count and maybe its last message.
    if (mounted) await viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final MessagesViewModel viewModel = context.watch<MessagesViewModel>();
    final bool hasUnread = context.watch<ShellBadges>().unreadNotifications > 0;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: ScrollToTopOnReselect(
        branch: MessagesView.branch,
        controller: _scroll,
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () => _refresh(viewModel),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification.metrics.extentAfter < _loadMoreDistance.dh) {
                viewModel.loadMore();
              }
              return false;
            },
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: AppSpacing.xl.dh),
              children: <Widget>[
                MessagesHeader(
                  search: _search,
                  onSearchChanged: viewModel.setQuery,
                  hasUnreadNotifications: hasUnread,
                  onBell: () => context.push(AppRoutes.notifications),
                ),
                MessagesFilterChips(
                  selected: viewModel.filter,
                  onSelected: viewModel.setFilter,
                ),
                Padding(
                  padding: AppSpacing.screenPaddingAll,
                  child: _MessagesBody(
                    viewModel: viewModel,
                    onOpen: (ConversationRow row) => _open(viewModel, row),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessagesBody extends StatelessWidget {
  const _MessagesBody({required this.viewModel, required this.onOpen});

  final MessagesViewModel viewModel;
  final ValueChanged<ConversationRow> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<ConversationRow> rows = viewModel.items;

    if (viewModel.isFirstLoad) {
      return const DividedCard(
        children: <Widget>[
          ConversationTileSkeleton(),
          ConversationTileSkeleton(),
          ConversationTileSkeleton(),
        ],
      );
    }
    if (rows.isEmpty) {
      if (viewModel.hasError) return StateCard.error(onRetry: viewModel.load);
      return switch (viewModel.empty) {
        MessagesEmpty.all => StateCard.empty(
          icon: AppIcons.message,
          title: l10n.messagesEmptyTitle,
          body: l10n.messagesEmptyBody,
          actionLabel: l10n.messagesEmptyAction,
          onAction: () => context.go(AppRoutes.search),
        ),
        MessagesEmpty.unread => StateCard.empty(
          icon: AppIcons.message,
          title: l10n.messagesUnreadEmpty,
        ),
        MessagesEmpty.bookings => StateCard.empty(
          icon: AppIcons.message,
          title: l10n.messagesBookingsEmpty,
        ),
        MessagesEmpty.search => StateCard.empty(
          icon: AppIcons.search,
          // The user's own words, shown as typed.
          title: l10n.messagesNoMatch(viewModel.query),
        ),
        MessagesEmpty.none => const SizedBox.shrink(),
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (viewModel.isOffline) ...<Widget>[
          OfflineBanner(
            body: l10n.offlineMessagesBody,
            onRetry: viewModel.refresh,
          ),
          SizedBox(height: AppSpacing.sm.dh),
        ],
        DividedCard(
          children: <Widget>[
            for (final ConversationRow row in rows)
              ConversationTile(row: row, onTap: () => onOpen(row)),
          ],
        ),
        if (viewModel.isLoadingMore)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.md.dh),
            child: const Center(child: AppSpinner(size: AppSizes.iconMd)),
          )
        else if (viewModel.loadMoreFailed)
          Center(
            child: TextButton(
              onPressed: viewModel.loadMore,
              child: Text(l10n.stateRetry),
            ),
          ),
      ],
    );
  }
}
