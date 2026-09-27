import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/failure.dart';
import '../../../core/messaging/chat_poller.dart';
import '../../../core/messaging/messaging_repository.dart';
import '../../../core/messaging/models/chat_message.dart';
import '../../../core/messaging/models/chat_person.dart';
import '../../../core/messaging/models/conversation.dart';
import '../../../core/messaging/models/report_reason.dart';
import '../../../core/messaging/picked_image.dart';
import '../../shell/shell_badges.dart';
import 'chat_thread.dart';

export 'chat_thread.dart';

enum ChatLoadState { loading, ready, error, unavailable }

/// What sits where the composer goes.
enum ComposerMode {
  open,

  /// Eventor closed the chat, or this account may not write in it — from
  /// `canWrite: false` at load, or a CLOSED / READ_ONLY answer to a send.
  closed,

  /// The other account is blocked or deleted (D12).
  otherInactive,
}

/// The provider a draft chat is for (decision 2): no conversation exists
/// until the first message creates it.
class ChatDraftPeer {
  const ChatDraftPeer({required this.userId, required this.name});

  final String userId;
  final String name;
}

/// What a draft hands the chat it just created, so that screen opens with
/// the header and the first message already there instead of a skeleton.
class ChatOpening {
  const ChatOpening({required this.detail, this.page});

  final ConversationDetail detail;

  /// `null` when the first page could not be fetched; the chat loads it.
  final MessagePage? page;
}

/// How a send ended, for the view to act on.
sealed class SendOutcome {
  const SendOutcome();
}

class SendSent extends SendOutcome {
  const SendSent();
}

/// Nothing to send, the chat is closed, or a draft is already starting.
class SendIgnored extends SendOutcome {
  const SendIgnored();
}

/// The bubble now says "Not sent · Tap to retry".
class SendFailed extends SendOutcome {
  const SendFailed(this.failure);

  final Failure failure;
}

/// The server said the chat is closed; the composer has switched over.
class SendClosed extends SendOutcome {
  const SendClosed();
}

class SendPhotoRejected extends SendOutcome {
  const SendPhotoRejected(this.problem);

  final ImageProblem problem;
}

/// The draft's first message was refused for who it was addressed to; the
/// text goes back in the composer.
class SendStartRejected extends SendOutcome {
  const SendStartRejected(this.failure, this.text);

  final Failure failure;
  final String text;
}

/// The draft became a real conversation; the view swaps the route.
class SendStarted extends SendOutcome {
  const SendStarted(this.conversationId, this.opening);

  final String conversationId;
  final ChatOpening opening;
}

sealed class ReportOutcome {
  const ReportOutcome();
}

class ReportSent extends ReportOutcome {
  const ReportSent({required this.created});

  /// `false` when this account had already reported the same thing.
  final bool created;
}

class ReportFailed extends ReportOutcome {
  const ReportFailed(this.failure);

  final Failure failure;
}

/// Screen 15: one conversation, or a draft addressed to a provider.
///
/// Messages the server returned are kept by id, so a poll, an older page
/// and a send's answer can all land in any order and still leave one bubble
/// per message. Our own messages show at once as pending entries (D8) and
/// are swapped for the server's copy when it answers.
///
/// While the chat is open, [ChatUpdates] ticks every few seconds and the
/// newest page is merged in (decision 1).
class ChatViewModel extends BaseViewModel {
  ChatViewModel({
    required this._messaging,
    required this._catalog,
    required this._badges,
    required this._config,
    required this._updates,
    String? conversationId,
    ChatDraftPeer? draft,
    ChatOpening? opening,
    this._now = DateTime.now,
  }) : assert(
         (conversationId != null || opening != null) != (draft != null),
         'A chat has a conversation or a draft peer, not both.',
       ),
       _id = opening?.detail.id ?? conversationId,
       _draft = opening == null ? draft : null {
    if (opening != null) {
      _open(opening.detail, opening.page);
    } else if (_draft != null) {
      _loadState = ChatLoadState.ready;
      _loadPeer();
    } else {
      load();
    }
  }

  /// The first message is capped by the API at 4000; the send route has no
  /// cap of its own, so the same one applies to every message (D7).
  static const int maxTextLength = 4000;

  /// The report note's API limit (D16).
  static const int maxNoteLength = 2000;

  final MessagingRepository _messaging;
  final CatalogRepository _catalog;
  final ShellBadges _badges;
  final AppConfig _config;
  final ChatUpdates _updates;
  final DateTime Function() _now;

  final String? _id;
  final ChatDraftPeer? _draft;

  ConversationDetail? _detail;
  ChatLoadState _loadState = ChatLoadState.loading;

  final Map<String, ChatMessage> _confirmed = <String, ChatMessage>{};
  final List<ChatEntry> _pending = <ChatEntry>[];
  List<ThreadItem> _thread = const <ThreadItem>[];

  bool _hasOlder = false;
  String? _nextBefore;
  bool _isLoadingOlder = false;
  bool _olderFailed = false;

  bool _atBottom = true;
  bool _hasNewBelow = false;

  /// Set when a send was refused because the chat closed after it loaded.
  bool _closedBySend = false;

  String? _replyTime;
  String? _peerAvatarUrl;
  PickedImage? _attachment;

  int _localSeq = 0;
  bool _polling = false;
  bool _starting = false;
  bool _isClosing = false;

  ChatLoadState get loadState => _loadState;
  ConversationDetail? get detail => _detail;
  ChatDraftPeer? get draft => _draft;
  bool get isDraft => _draft != null;

  /// "Usually replies in …" (D4). `null` hides the line.
  String? get replyTime => _replyTime;

  /// The provider's photo, for a draft's top bar.
  String? get peerAvatarUrl => _peerAvatarUrl;

  List<ThreadItem> get thread => _thread;
  bool get hasOlder => _hasOlder;
  bool get isLoadingOlder => _isLoadingOlder;
  bool get olderFailed => _olderFailed;

  /// A poll brought messages while the user was reading further up (D9).
  bool get hasNewBelow => _hasNewBelow;

  PickedImage? get attachment => _attachment;

  /// The photo size limit, for the view's "larger than N MB" toast.
  int get maxPhotoMb => _config.maxPhotoMb;

  ComposerMode get composerMode {
    if (_closedBySend) return ComposerMode.closed;
    final ConversationDetail? detail = _detail;
    if (detail == null) return ComposerMode.open;
    final ChatPerson? other = detail.other;
    if (other == null || other.blocked) return ComposerMode.otherInactive;
    if (!detail.canWrite || detail.isClosed) return ComposerMode.closed;
    return ComposerMode.open;
  }

  /// The ⋯ menu reports the other person, so it has nobody to act on in a
  /// support or dispute chat, or when the account is gone.
  bool get showsMenu {
    final ConversationDetail? detail = _detail;
    if (detail == null) return isDraft;
    return detail.kind == ConversationKind.direct && detail.other != null;
  }

  /// Dispute chats write through a text-only route; a draft's first message
  /// must be text (the API requires a body).
  bool get canAttach =>
      !isDraft &&
      _detail != null &&
      _detail?.kind != ConversationKind.dispute &&
      composerMode == ComposerMode.open;

  // ------------------------------------------------------------- reading

  Future<void> load() async {
    final String? id = _id;
    if (id == null) return;
    clearFailure();
    _loadState = ChatLoadState.loading;
    notifyListeners();
    final ConversationDetail detail;
    final MessagePage page;
    try {
      final List<Object?> results = await Future.wait<Object?>(
        <Future<Object?>>[_messaging.conversation(id), _messaging.messages(id)],
      );
      detail = results[0]! as ConversationDetail;
      page = results[1]! as MessagePage;
    } on Failure catch (failure) {
      if (_isGone(failure)) {
        _loadState = ChatLoadState.unavailable;
        notifyListeners();
      } else {
        _loadState = ChatLoadState.error;
        setFailure(failure);
      }
      return;
    }
    if (_isClosing) return;
    _open(detail, page);
  }

  /// Not yours, or not there any more — "no longer available", not an error.
  static bool _isGone(Failure failure) =>
      failure is ApiFailure &&
      (failure.code == ApiErrorCode.notAParticipant ||
          failure.code == ApiErrorCode.conversationNotFound);

  void _open(ConversationDetail detail, MessagePage? page) {
    _detail = detail;
    _confirmed.clear();
    if (page != null) {
      for (final ChatMessage m in page.items) {
        _confirmed[m.id] = m;
      }
      _hasOlder = page.hasMore;
      _nextBefore = page.nextBefore;
    }
    _loadState = ChatLoadState.ready;
    _rebuild();
    notifyListeners();
    if (page == null) unawaited(_loadFirstPage());
    unawaited(_markRead());
    // A retried load opens the chat again; one poller is enough.
    if (!_polling) {
      _polling = true;
      _updates.start(_poll);
    }
    unawaited(_loadPeer());
  }

  /// The page a draft's hand-over could not bring along.
  Future<void> _loadFirstPage() async {
    final String? id = _id;
    if (id == null) return;
    try {
      final MessagePage page = await _messaging.messages(id);
      if (_isClosing) return;
      for (final ChatMessage m in page.items) {
        _confirmed[m.id] = m;
      }
      _hasOlder = page.hasMore;
      _nextBefore = page.nextBefore;
      _rebuild();
      notifyListeners();
    } on Failure {
      // The poller fetches the same page within seconds; only the older-page
      // cursor waits for the next open.
    }
  }

  /// D4: the provider's reply time (and photo, for a draft), from 13's data.
  Future<void> _loadPeer() async {
    final ConversationDetail? detail = _detail;
    final String? userId =
        _draft?.userId ??
        (detail != null &&
                detail.kind == ConversationKind.direct &&
                detail.other?.role == ChatRole.provider
            ? detail.other?.id
            : null);
    if (userId == null) return;
    try {
      final ProviderDetail provider = await _catalog.provider(userId);
      if (_isClosing) return;
      _replyTime = provider.replyTime;
      _peerAvatarUrl = provider.avatarUrl;
      notifyListeners();
    } on Failure {
      // The line is optional: a provider id that is not a catalog id (an
      // open backend question) or any other failure simply hides it.
    }
  }

  Future<void> _markRead() async {
    final String? id = _id;
    if (id == null) return;
    try {
      await _messaging.markRead(id);
    } on Failure {
      // Not worth a toast on 15: the next poll that brings a message
      // marks the chat read again.
      return;
    }
    if (_isClosing) return;
    await _badges.refresh();
  }

  Future<void> _poll() async {
    final String? id = _id;
    if (id == null || _loadState != ChatLoadState.ready || _isClosing) return;
    // Only what was here when the request left can have been deleted: a
    // send answered while the poll was out is newer than its snapshot.
    final Set<String> known = _confirmed.keys.toSet();
    final MessagePage page;
    try {
      page = await _messaging.messages(id);
    } on Failure {
      // Silent: the next tick tries again.
      return;
    }
    if (_isClosing) return;
    final bool newReceived = page.items.any(
      (ChatMessage m) => !m.mine && !_confirmed.containsKey(m.id),
    );
    _mergeNewest(page, known);
    if (newReceived && !_atBottom) _hasNewBelow = true;
    _rebuild();
    notifyListeners();
    if (newReceived) unawaited(_markRead());
  }

  void _mergeNewest(MessagePage page, Set<String> known) {
    if (page.items.isNotEmpty) {
      // A message inside the window this page covers but missing from it
      // was deleted by an admin — the API just leaves it out.
      final DateTime from = page.items.first.createdAt;
      final Set<String> ids = <String>{
        for (final ChatMessage m in page.items) m.id,
      };
      _confirmed.removeWhere(
        (String id, ChatMessage m) =>
            known.contains(id) &&
            m.createdAt.isAfter(from) &&
            !ids.contains(id),
      );
    }
    for (final ChatMessage m in page.items) {
      _confirmed[m.id] = m;
    }
  }

  Future<void> loadOlder() async {
    final String? id = _id;
    final String? before = _nextBefore;
    if (id == null || before == null || !_hasOlder || _isLoadingOlder) return;
    _isLoadingOlder = true;
    _olderFailed = false;
    notifyListeners();
    try {
      final MessagePage page = await _messaging.messages(id, before: before);
      if (_isClosing) return;
      for (final ChatMessage m in page.items) {
        _confirmed[m.id] = m;
      }
      _hasOlder = page.hasMore;
      _nextBefore = page.nextBefore;
      _rebuild();
    } on Failure {
      _olderFailed = true;
    }
    _isLoadingOlder = false;
    notifyListeners();
  }

  /// D15: signed image URLs expire. Fetches the page that ends with
  /// [messageId] — the one before the next newer message — so its fresh
  /// URLs replace the stale ones by id.
  Future<void> reloadPhoto(String messageId) async {
    final String? id = _id;
    if (id == null) return;
    final List<ChatMessage> ordered = _ordered();
    final int index = ordered.indexWhere((ChatMessage m) => m.id == messageId);
    if (index < 0) return;
    final String? before = index + 1 < ordered.length
        ? ordered[index + 1].id
        : null;
    try {
      final MessagePage page = await _messaging.messages(id, before: before);
      if (_isClosing) return;
      for (final ChatMessage m in page.items) {
        _confirmed[m.id] = m;
      }
      _rebuild();
      notifyListeners();
    } on Failure {
      // The tile keeps offering the reload.
    }
  }

  void setAtBottom(bool atBottom) {
    _atBottom = atBottom;
    if (atBottom && _hasNewBelow) {
      _hasNewBelow = false;
      notifyListeners();
    }
  }

  List<ChatMessage> _ordered() {
    final List<ChatMessage> ordered = _confirmed.values.toList()
      ..sort((ChatMessage a, ChatMessage b) {
        final int byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    return ordered;
  }

  void _rebuild() {
    final ConversationDetail? detail = _detail;
    _thread = buildThread(
      chronological: <ChatEntry>[
        for (final ChatMessage m in _ordered()) ChatEntry(message: m),
        ..._pending,
      ],
      isGroup: detail?.isGroup ?? false,
      senderName: (String? senderId) => detail?.participant(senderId)?.name,
    );
  }

  // ------------------------------------------------------------- writing

  /// Keeps [image] for the next send when it passes the upload limits.
  ImageProblem? attach(PickedImage image) {
    final ImageProblem? problem = image.validate(
      maxMb: _config.maxPhotoMb,
      types: _config.imageTypes,
    );
    if (problem == null) {
      _attachment = image;
      notifyListeners();
    }
    return problem;
  }

  void clearAttachment() {
    if (_attachment == null) return;
    _attachment = null;
    notifyListeners();
  }

  Future<SendOutcome> send(String text) async {
    final String body = text.trim();
    // A draft or a dispute chat takes text only, whatever was attached.
    final PickedImage? image = canAttach ? _attachment : null;
    if (composerMode != ComposerMode.open) return const SendIgnored();
    if (body.isEmpty && image == null) return const SendIgnored();
    if (isDraft ? _starting : _loadState != ChatLoadState.ready) {
      return const SendIgnored();
    }
    final ChatEntry entry = ChatEntry(
      message: ChatMessage(
        id: 'local-${_localSeq++}',
        conversationId: _id ?? '',
        kind: image == null ? MessageKind.text : MessageKind.attachment,
        senderId: null,
        mine: true,
        body: body,
        masked: false,
        imageUrl: null,
        imageLargeUrl: null,
        createdAt: _now(),
      ),
      state: EntryState.sending,
      localImage: image,
    );
    if (image != null) _attachment = null;
    _pending.add(entry);
    _rebuild();
    notifyListeners();
    return _deliver(entry);
  }

  /// Sends a "Not sent" bubble again.
  Future<SendOutcome> retry(String localId) async {
    final int index = _pending.indexWhere(
      (ChatEntry e) => e.message.id == localId && e.state == EntryState.failed,
    );
    if (index < 0 || composerMode != ComposerMode.open) {
      return const SendIgnored();
    }
    if (isDraft && _starting) return const SendIgnored();
    final ChatEntry entry = _pending[index].copyWith(state: EntryState.sending);
    _pending[index] = entry;
    _rebuild();
    notifyListeners();
    return _deliver(entry);
  }

  Future<SendOutcome> _deliver(ChatEntry entry) async {
    if (isDraft) return _start(entry);
    final String id = _id!;
    final ConversationDetail? detail = _detail;
    final ChatMessage message = entry.message;
    final PickedImage? image = entry.localImage;
    final String? disputeId = detail?.disputeId;
    try {
      final ChatMessage sent;
      if (image != null) {
        sent = await _messaging.sendPhoto(
          id,
          image,
          caption: message.body.isEmpty ? null : message.body,
        );
      } else if (detail?.kind == ConversationKind.dispute &&
          disputeId != null) {
        sent = await _messaging.sendDisputeText(disputeId, message.body);
      } else {
        sent = await _messaging.sendText(id, message.body);
      }
      if (_isClosing) return const SendSent();
      _pending.removeWhere((ChatEntry e) => e.message.id == message.id);
      // By id: a poll may already have brought this very message.
      _confirmed[sent.id] = sent;
      _rebuild();
      notifyListeners();
      return const SendSent();
    } on Failure catch (failure) {
      return _fail(entry, failure);
    }
  }

  Future<SendOutcome> _start(ChatEntry entry) async {
    final ChatDraftPeer draft = _draft!;
    final String body = entry.message.body;
    _starting = true;
    bool started = false;
    try {
      final ConversationDetail detail = await _messaging.start(
        draft.userId,
        body,
      );
      MessagePage? page;
      try {
        page = await _messaging.messages(detail.id);
      } on Failure {
        // The new chat loads its own first page.
        page = null;
      }
      // The draft is spent: the view swaps to the new chat, and a send in
      // the moment before that must not start a second one.
      started = true;
      return SendStarted(detail.id, ChatOpening(detail: detail, page: page));
    } on Failure catch (failure) {
      final bool badRecipient =
          failure is ApiFailure &&
          (failure.code == ApiErrorCode.recipientInvalid ||
              failure.code == ApiErrorCode.userNotFound);
      if (!badRecipient) return _fail(entry, failure);
      _pending.removeWhere((ChatEntry e) => e.message.id == entry.message.id);
      _rebuild();
      notifyListeners();
      return SendStartRejected(failure, body);
    } finally {
      if (!started) _starting = false;
    }
  }

  SendOutcome _fail(ChatEntry entry, Failure failure) {
    final int index = _pending.indexWhere(
      (ChatEntry e) => e.message.id == entry.message.id,
    );
    if (index >= 0) {
      _pending[index] = _pending[index].copyWith(state: EntryState.failed);
    }
    SendOutcome outcome = SendFailed(failure);
    if (failure is ApiFailure) {
      switch (failure.code) {
        case ApiErrorCode.conversationClosed:
        case ApiErrorCode.conversationReadOnly:
          _closedBySend = true;
          outcome = const SendClosed();
        case ApiErrorCode.fileTooLarge:
          outcome = const SendPhotoRejected(ImageProblem.tooLarge);
        case ApiErrorCode.fileTypeNotAllowed:
          outcome = const SendPhotoRejected(ImageProblem.wrongType);
      }
    }
    _rebuild();
    notifyListeners();
    return outcome;
  }

  Future<ReportOutcome> reportMessage(
    ChatMessage message,
    ReportReason reason,
    String? note,
  ) =>
      _report(() => _messaging.reportMessage(message.id, reason, _clean(note)));

  /// Reports the other person — the API has no way to report a
  /// conversation.
  Future<ReportOutcome> reportPeer(ReportReason reason, String? note) {
    final String? userId = _draft?.userId ?? _detail?.other?.id;
    if (userId == null) {
      return Future<ReportOutcome>.value(
        const ReportFailed(UnexpectedFailure()),
      );
    }
    return _report(() => _messaging.reportUser(userId, reason, _clean(note)));
  }

  Future<ReportOutcome> _report(Future<bool> Function() call) async {
    try {
      return ReportSent(created: await call());
    } on Failure catch (failure) {
      return ReportFailed(failure);
    }
  }

  static String? _clean(String? note) {
    final String trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    _isClosing = true;
    _updates.stop();
    super.dispose();
  }
}
