import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/formatting/chat_time_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/localization/messaging_labels.dart';
import '../../../core/messaging/models/chat_message.dart';
import '../../../core/messaging/models/chat_person.dart';
import '../../../core/messaging/models/conversation.dart';
import '../../../core/messaging/models/report_reason.dart';
import '../../../core/messaging/picked_image.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/services/photo_picker.dart';
import '../../../core/widgets/atoms/app_avatar.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/conversation_avatar.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/chat_view_model.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_sheets.dart';
import 'widgets/chat_top_bar.dart';
import 'widgets/message_bubble.dart';

/// Screen 15 — one conversation, or a draft to a provider (decision 2).
///
/// Also serves D4, the dispute chat: same anatomy, text only, no ⋯.
class ChatView extends StatefulWidget {
  const ChatView({this.pickPhoto = pickChatPhoto, super.key});

  /// Injected so tests can pick a photo without a platform channel.
  final PhotoPicker pickPhoto;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// How close to the oldest loaded message the next page is fetched.
  static const double _olderDistance = 400;

  /// Within this of the newest message counts as "at the bottom" (D9).
  static const double _bottomSlack = 48;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _back() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.messages);

  void _toast(String message, {AppToastTone tone = AppToastTone.error}) {
    if (mounted) showAppToast(context, message, tone: tone);
  }

  /// The provider behind the header, when there is one to open.
  String? _peerId(ChatViewModel viewModel) {
    final ChatDraftPeer? draft = viewModel.draft;
    if (draft != null) return draft.userId;
    final ConversationDetail? detail = viewModel.detail;
    final ChatPerson? other = detail?.other;
    if (detail?.kind != ConversationKind.direct || other == null) return null;
    return other.role == ChatRole.provider ? other.id : null;
  }

  Future<void> _send(ChatViewModel viewModel) async {
    final String text = _text.text;
    _text.clear();
    final SendOutcome outcome = await viewModel.send(text);
    if (outcome is SendIgnored && mounted) _text.text = text;
    await _handle(outcome);
  }

  Future<void> _retry(ChatViewModel viewModel, String localId) async =>
      _handle(await viewModel.retry(localId));

  Future<void> _handle(SendOutcome outcome) async {
    if (!mounted) return;
    final AppLocalizations l10n = context.l10n;
    switch (outcome) {
      case SendStarted(
        :final String conversationId,
        :final ChatOpening opening,
      ):
        context.pushReplacement(
          AppRoutes.chatFor(conversationId),
          extra: opening,
        );
      case SendStartRejected(:final failure, :final String text):
        _text.text = text;
        _toast(l10n.forFailure(failure));
      case SendPhotoRejected(:final ImageProblem problem):
        _photoProblem(problem);
      case SendSent() || SendIgnored() || SendFailed() || SendClosed():
        // The bubble and the composer already say what happened.
        break;
    }
  }

  void _photoProblem(ImageProblem problem) {
    final AppLocalizations l10n = context.l10n;
    final ChatViewModel viewModel = context.read<ChatViewModel>();
    _toast(switch (problem) {
      ImageProblem.tooLarge => l10n.photoTooLarge(viewModel.maxPhotoMb),
      ImageProblem.wrongType => l10n.photoWrongType,
    });
  }

  Future<void> _attach(ChatViewModel viewModel) async {
    if (viewModel.isDraft) {
      // The API needs text to create the chat; a photo can follow.
      _toast(context.l10n.chatPhotoNeedsText, tone: AppToastTone.info);
      return;
    }
    final PickedImage? image = await widget.pickPhoto();
    if (image == null || !mounted) return;
    final ImageProblem? problem = viewModel.attach(image);
    if (problem != null) _photoProblem(problem);
  }

  Future<void> _report(
    Future<ReportOutcome> Function(({ReportReason reason, String? note}) r)
    send,
  ) async {
    final ({ReportReason reason, String? note})? choice = await showReportSheet(
      context,
    );
    if (choice == null || !mounted) return;
    final ReportOutcome outcome = await send(choice);
    if (!mounted) return;
    final AppLocalizations l10n = context.l10n;
    switch (outcome) {
      case ReportSent(:final bool created):
        _toast(
          created ? l10n.reportSent : l10n.reportAlready,
          tone: AppToastTone.success,
        );
      case ReportFailed(:final failure):
        _toast(l10n.forFailure(failure));
    }
  }

  Future<void> _peerMenu(ChatViewModel viewModel, String name) async {
    final String? peerId = _peerId(viewModel);
    final PeerAction? action = await showPeerActions(
      context,
      name: name,
      canViewProfile: peerId != null,
    );
    if (!mounted) return;
    switch (action) {
      case PeerAction.viewProfile:
        if (peerId != null) context.push(AppRoutes.providerFor(peerId));
      case PeerAction.report:
        await _report(
          (({ReportReason reason, String? note}) r) =>
              viewModel.reportPeer(r.reason, r.note),
        );
      case null:
        break;
    }
  }

  Future<void> _messageMenu(
    ChatViewModel viewModel,
    ChatMessage message,
  ) async {
    final MessageAction? action = await showMessageActions(
      context,
      canCopy: message.body.trim().isNotEmpty,
      canReport: !message.mine,
    );
    if (!mounted) return;
    switch (action) {
      case MessageAction.copy:
        final String copied = context.l10n.chatCopied;
        await Clipboard.setData(ClipboardData(text: message.body));
        _toast(copied, tone: AppToastTone.success);
      case MessageAction.report:
        await _report(
          (({ReportReason reason, String? note}) r) =>
              viewModel.reportMessage(message, r.reason, r.note),
        );
      case null:
        break;
    }
  }

  void _jumpToBottom(ChatViewModel viewModel) {
    viewModel.setAtBottom(true);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ChatViewModel viewModel = context.watch<ChatViewModel>();
    final ConversationDetail? detail = viewModel.detail;
    final ChatDraftPeer? draft = viewModel.draft;
    final String? peerId = _peerId(viewModel);
    final String? replyTime = viewModel.replyTime;
    final String? groupProvider = detail?.groupProvider?.name;
    final ChatBooking? booking = detail?.booking;

    final String title =
        draft?.name ?? (detail == null ? '' : l10n.conversationTitle(detail));
    final String? subtitle = detail?.kind == ConversationKind.dispute
        ? (groupProvider == null ? null : l10n.chatGroupSubtitle(groupProvider))
        : (replyTime == null ? null : l10n.repliesIn(replyTime));
    final Widget avatar = draft != null
        ? AppAvatar(
            name: draft.name,
            photoUrl: viewModel.peerAvatarUrl,
            size: AppAvatarSize.chatHeader,
          )
        : detail != null
        ? ConversationAvatar(
            kind: detail.kind,
            other: detail.other,
            size: AppAvatarSize.chatHeader,
          )
        : const AppAvatar.anonymous(size: AppAvatarSize.chatHeader);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: <Widget>[
          ChatTopBar(
            avatar: avatar,
            title: title,
            subtitle: subtitle,
            onBack: _back,
            onPeerTap: peerId == null
                ? null
                : () => context.push(AppRoutes.providerFor(peerId)),
            onMore: viewModel.showsMenu
                ? () => _peerMenu(viewModel, title)
                : null,
          ),
          if (booking != null)
            BookingContextCard(
              booking: booking,
              onTap: () => showComingSoon(context, l10n.comingSoon),
            ),
          Expanded(child: _body(viewModel)),
          if (viewModel.loadState == ChatLoadState.ready) _composer(viewModel),
        ],
      ),
    );
  }

  Widget _body(ChatViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    switch (viewModel.loadState) {
      case ChatLoadState.loading:
        return const ChatSkeleton();
      case ChatLoadState.error:
        return SingleChildScrollView(
          padding: AppSpacing.screenPaddingAll,
          child: StateCard.error(onRetry: viewModel.load),
        );
      case ChatLoadState.unavailable:
        return SingleChildScrollView(
          padding: AppSpacing.screenPaddingAll,
          child: StateCard.empty(
            icon: AppIcons.message,
            title: l10n.chatUnavailable,
            actionLabel: l10n.backLabel,
            onAction: _back,
          ),
        );
      case ChatLoadState.ready:
        final ChatDraftPeer? draft = viewModel.draft;
        if (draft != null && viewModel.thread.isEmpty) {
          return Center(
            child: Padding(
              padding: AppSpacing.screenPaddingAll,
              child: Text(
                l10n.chatSayHello(draft.name),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return _thread(viewModel);
    }
  }

  Widget _thread(ChatViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    final String locale = Localizations.localeOf(context).languageCode;
    final List<ThreadItem> thread = viewModel.thread;
    final bool hasTop = viewModel.hasOlder || viewModel.olderFailed;
    final DateTime now = DateTime.now();

    Widget item(ThreadItem item) => switch (item) {
      DayItem(:final DateTime day) => DayPill(
        dayLabel(
          day,
          now: now,
          locale: locale,
          today: l10n.chatToday,
          yesterday: l10n.chatYesterday,
        ),
      ),
      SystemItem(:final ChatMessage message) => SystemPill(message.body),
      BubbleItem(:final ChatEntry entry, :final String? senderName) => _bubble(
        viewModel,
        entry,
        senderName,
      ),
    };

    return Stack(
      children: <Widget>[
        NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            final ScrollMetrics metrics = notification.metrics;
            if (metrics.extentAfter < _olderDistance.dh) viewModel.loadOlder();
            viewModel.setAtBottom(metrics.pixels <= _bottomSlack.dh);
            return false;
          },
          child: ListView.builder(
            controller: _scroll,
            // Newest at the bottom, and the list opens there.
            reverse: true,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md.dw,
              vertical: AppSpacing.sm.dh,
            ),
            itemCount: thread.length + (hasTop ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index == thread.length) return _olderRow(viewModel);
              final ThreadItem entry = thread[index];
              return Padding(
                key: ValueKey<String>(entry.key),
                padding: EdgeInsets.only(top: 10.dh),
                child: item(entry),
              );
            },
          ),
        ),
        if (viewModel.hasNewBelow)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.sm.dh,
            child: Center(
              child: NewMessagesPill(onTap: () => _jumpToBottom(viewModel)),
            ),
          ),
      ],
    );
  }

  Widget _olderRow(ChatViewModel viewModel) {
    if (viewModel.olderFailed) {
      return Column(
        children: <Widget>[
          Text(
            context.l10n.chatOlderFailed,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: viewModel.loadOlder,
            child: Text(context.l10n.stateRetry),
          ),
        ],
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.dh),
      child: const Center(child: AppSpinner(size: AppSizes.iconMd)),
    );
  }

  Widget _bubble(ChatViewModel viewModel, ChatEntry entry, String? senderName) {
    final ChatMessage message = entry.message;
    final bool hasMenu =
        !entry.isPending &&
        !message.isRemoved &&
        message.kind != MessageKind.system &&
        (message.body.trim().isNotEmpty || !message.mine);
    final String? image = message.imageLargeUrl ?? message.imageUrl;
    return MessageBubble(
      entry: entry,
      senderName: senderName,
      onLongPress: hasMenu ? () => _messageMenu(viewModel, message) : null,
      onRetry: () => _retry(viewModel, message.id),
      onPhotoTap: image == null
          ? null
          : () => showPhotoViewer(context, url: image),
      onPhotoReload: () => viewModel.reloadPhoto(message.id),
    );
  }

  Widget _composer(ChatViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    switch (viewModel.composerMode) {
      case ComposerMode.closed:
        return ClosedComposer(notice: l10n.chatClosed);
      case ComposerMode.otherInactive:
        return ClosedComposer(notice: l10n.chatOtherBlocked);
      case ComposerMode.open:
        final bool isDispute =
            viewModel.detail?.kind == ConversationKind.dispute;
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: _text,
          builder: (BuildContext context, TextEditingValue value, _) =>
              ChatComposer(
                controller: _text,
                hint: isDispute
                    ? l10n.chatComposerDisputeHint
                    : l10n.chatComposerHint,
                // A draft shows "+" to explain why a photo must wait.
                canAttach: viewModel.isDraft || viewModel.canAttach,
                canSend:
                    value.text.trim().isNotEmpty ||
                    viewModel.attachment != null,
                attachment: viewModel.attachment,
                onAttach: () => _attach(viewModel),
                onRemoveAttachment: viewModel.clearAttachment,
                onSend: () => _send(viewModel),
              ),
        );
    }
  }
}
