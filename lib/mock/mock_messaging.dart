import 'dart:async';
import 'dart:convert';

import '../core/config/app_config.dart';
import '../core/errors/failure.dart';
import '../core/messaging/conversation_filter.dart';
import '../core/messaging/messaging_repository.dart';
import '../core/messaging/models/chat_message.dart';
import '../core/messaging/models/conversation.dart';
import '../core/messaging/models/report_reason.dart';
import '../core/messaging/picked_image.dart';
import '../core/network/api_page.dart';
import '../core/notifications/models/app_notification.dart';
import '../core/notifications/notifications_repository.dart';
import 'mock_backend.dart';
import 'mock_catalog_data.dart';
import 'mock_messaging_data.dart';

ApiFailure _failure(int status, String code, String message) =>
    ApiFailure(statusCode: status, code: code, message: message);

String _iso(DateTime time) => time.toUtc().toIso8601String();

/// One conversation in memory: its detail JSON, mutated in place as
/// messages arrive, and its thread, oldest first.
class _Thread {
  _Thread(this.json, this.messages);

  final Map<String, Object?> json;
  final List<Map<String, Object?>> messages;

  /// D3: set on the first send of this run, so a conversation answers once.
  bool replyScheduled = false;

  String get id => json['id']! as String;
  String get kind => json['kind']! as String;
  Map<String, Object?>? get other => json['other'] as Map<String, Object?>?;
  int get unreadCount => (json['unreadCount']! as num).toInt();
  DateTime? get lastMessageAt {
    final String? at = json['lastMessageAt'] as String?;
    return at == null ? null : DateTime.parse(at);
  }

  /// Support and dispute rows are found by the support name, since their
  /// `other` is always the support agent.
  String get searchName =>
      kind == 'direct' ? (other?['name'] as String? ?? '') : mockSupportName;

  void append(Map<String, Object?> message) {
    messages.add(message);
    json['lastMessage'] = message['body'];
    json['lastMessageAt'] = message['createdAt'];
  }
}

/// One account's inbox — its conversations, notifications and the reports
/// it has filed.
class _Inbox {
  _Inbox(this.threads, this.notifications);

  final List<_Thread> threads;

  /// `mockNotificationSeeds` rows, `read` flipped in place.
  final List<Map<String, Object?>> notifications;

  /// `<targetType>:<targetId>` — one open report per target, as live.
  final Set<String> reports = <String>{};
}

/// The in-app messaging backend behind [MockMessagingRepository] and
/// [MockNotificationsRepository], and the source of the mock home feed's two
/// unread counts.
///
/// Each signed-in account gets its own inbox, keyed by email and seeded from
/// `mock_messaging_data.dart` the first time that account touches it. It is
/// kept in memory only — unlike [MockBackend]'s accounts, nothing here is
/// saved, so a restart re-seeds every inbox from scratch (sent messages,
/// reads and reports are forgotten).
///
/// It follows the live API's rules and error codes — closed and read-only
/// chats, photo limits, phone masking, the `before` cursor, idempotent
/// `start` and reports — and adds one mock-only kindness (spec D3): the
/// first send in a direct chat during a run is answered once, after
/// [replyDelay], so the chat's 5 s poll has something to show.
class MockMessagingStore {
  MockMessagingStore(
    this._backend, {
    this.replyDelay = const Duration(seconds: 4),
    required this._languageCode,
    this._config = const AppConfig(),
  });

  final MockBackend _backend;
  final String Function() _languageCode;

  /// Photo limits (`maxPhotoMb`, `imageTypes`), as `GET /app/config` states.
  final AppConfig _config;

  /// How long a mock provider takes to answer (D3).
  final Duration replyDelay;

  static const int _conversationPageSize = 20;
  static const int _notificationPageSize = 20;
  static const int _messagePageSize = 30;
  static const int _maxBodyLength = 4000;

  /// The masking rule: a run of 9+ digits, spaces allowed inside.
  static final RegExp _phonePattern = RegExp(r'\+?\d[\d\s]{7,}\d');
  static const String _phoneHidden = '[phone hidden]';

  final Map<String, _Inbox> _inboxes = <String, _Inbox>{};
  final Set<Timer> _timers = <Timer>{};
  int _sequence = 0;

  bool get _isArabic => _languageCode() == 'ar';

  /// Chats with at least one unread message — the Messages tab badge (D5).
  int unreadConversations() =>
      _inbox().threads.where((_Thread thread) => thread.unreadCount > 0).length;

  int unreadNotifications() => _inbox().notifications
      .where((Map<String, Object?> n) => n['read'] != true)
      .length;

  /// Cancels any mock reply still waiting — for tests, which should not
  /// leave timers behind them.
  void dispose() {
    for (final Timer timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  _Inbox _inbox() {
    final MockAccount account = _backend.requireSession();
    return _inboxes.putIfAbsent(account.email, () {
      final List<MockThreadSeed> seeds = mockConversationSeeds(
        now: _backend.now,
        meId: account.id,
        meName: account.fullName,
      );
      return _Inbox(<_Thread>[
        for (final MockThreadSeed seed in seeds)
          _Thread(seed.conversation, seed.messages),
      ], mockNotificationSeeds(_backend.now));
    });
  }

  String _meId() => _backend.requireSession().id;

  _Thread _thread(String id) {
    for (final _Thread thread in _inbox().threads) {
      if (thread.id == id) return thread;
    }
    throw _failure(
      404,
      ApiErrorCode.conversationNotFound,
      'Conversation not found.',
    );
  }

  // ------------------------------------------------------------ JSON out

  Map<String, Object?>? _booking(Map<String, Object?>? booking) {
    if (booking == null) return null;
    return <String, Object?>{
      'id': booking['id'],
      'reference': booking['reference'],
      'status': booking['status'],
      'eventDate': booking['eventDate'],
      'title': _isArabic ? booking['titleAr'] : booking['titleEn'],
      'total': booking['total'],
    };
  }

  Map<String, Object?> _rowJson(_Thread thread) => <String, Object?>{
    'id': thread.json['id'],
    'kind': thread.json['kind'],
    'status': thread.json['status'],
    'other': thread.json['other'],
    'lastMessage': _lastMessage(thread),
    'lastMessageAt': thread.json['lastMessageAt'],
    'unreadCount': thread.json['unreadCount'],
    'booking': _booking(thread.json['booking'] as Map<String, Object?>?),
    'canWrite': thread.json['canWrite'],
  };

  Map<String, Object?> _detailJson(_Thread thread) => <String, Object?>{
    ..._rowJson(thread),
    'participants': thread.json['participants'],
    'contactUnmasked': thread.json['contactUnmasked'],
    'disputeId': thread.json['disputeId'],
    // The reason stays internal to the server; only the fact is sent.
    'closedByModeration': thread.json['closedReason'] != null,
    'createdAt': thread.json['createdAt'],
  };

  static const String _removedBody = '[removed by Eventor]';

  /// `{body, kind, mine}`, as the live API has sent it since 2026-09-27.
  Map<String, Object?>? _lastMessage(_Thread thread) {
    final String? body = thread.json['lastMessage'] as String?;
    final Map<String, Object?>? last =
        thread.messages.isEmpty ? null : thread.messages.last;
    if (body == null && last == null) return null;
    return <String, Object?>{
      'body': body ?? last?['body'] ?? '',
      'kind': last?['kind'] ?? 'text',
      'mine': last?['mine'] ?? false,
    };
  }

  // --------------------------------------------------------- conversations

  ApiPage<Map<String, Object?>> _conversations(
    ConversationFilter filter,
    String? q,
    int page,
  ) {
    final String query = (q ?? '').trim().toLowerCase();
    final List<_Thread> found =
        _inbox().threads
            .where(
              (_Thread t) => switch (filter) {
                ConversationFilter.all => true,
                ConversationFilter.unread => t.unreadCount > 0,
                ConversationFilter.booking => t.json['booking'] != null,
              },
            )
            .where(
              (_Thread t) =>
                  query.isEmpty || t.searchName.toLowerCase().contains(query),
            )
            .toList()
          ..sort((_Thread a, _Thread b) {
            final DateTime? at = a.lastMessageAt;
            final DateTime? bt = b.lastMessageAt;
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });

    final int start = (page - 1) * _conversationPageSize;
    return ApiPage<Map<String, Object?>>(
      items: start >= found.length
          ? <Map<String, Object?>>[]
          : found
                .sublist(
                  start,
                  (start + _conversationPageSize).clamp(0, found.length),
                )
                .map(_rowJson)
                .toList(),
      page: page,
      totalPages: (found.length / _conversationPageSize).ceil(),
      total: found.length,
    );
  }

  Map<String, Object?> _messages(String conversationId, String? before) {
    final _Thread thread = _thread(conversationId);
    int end = thread.messages.length;
    if (before != null) {
      end = thread.messages.indexWhere(
        (Map<String, Object?> m) => m['id'] == before,
      );
      if (end == -1) {
        throw _failure(404, ApiErrorCode.messageNotFound, 'Message not found.');
      }
    }
    final int start = (end - _messagePageSize).clamp(0, end);
    final List<Map<String, Object?>> items = thread.messages.sublist(
      start,
      end,
    );
    final bool hasMore = start > 0;
    return <String, Object?>{
      // The server flags a message an admin removed (since 2026-09-27).
      'data': <Map<String, Object?>>[
        for (final Map<String, Object?> m in items)
          <String, Object?>{...m, 'removed': m['body'] == _removedBody},
      ],
      'meta': <String, Object?>{
        'limit': _messagePageSize,
        'hasMore': hasMore,
        'nextBefore': hasMore ? items.first['id'] : null,
      },
    };
  }

  // --------------------------------------------------------------- sending

  void _checkWritable(_Thread thread) {
    if (thread.json['status'] == 'closed') {
      throw _failure(
        409,
        ApiErrorCode.conversationClosed,
        'This conversation was closed by Eventor.',
      );
    }
    final Map<String, Object?>? other = thread.other;
    if (thread.json['canWrite'] != true ||
        other == null ||
        other['blocked'] == true) {
      throw _failure(
        403,
        ApiErrorCode.conversationReadOnly,
        'This conversation is read-only.',
      );
    }
  }

  String _checkBody(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty || trimmed.length > _maxBodyLength) {
      throw _failure(
        400,
        ApiErrorCode.validationFailed,
        'Some fields are invalid.',
      );
    }
    return trimmed;
  }

  /// The masked text and whether anything was hidden. A pair that shares an
  /// accepted booking ([_Thread] `contactUnmasked`) is never masked.
  (String, bool) _mask(_Thread thread, String body) {
    if (thread.json['contactUnmasked'] == true) return (body, false);
    // A dispute is read by an admin: never masked, whichever route sent it.
    if (thread.json['disputeId'] != null) return (body, false);
    final String masked = body.replaceAll(_phonePattern, _phoneHidden);
    return (masked, masked != body);
  }

  Map<String, Object?> _newMessage(
    _Thread thread, {
    required String? senderId,
    required bool mine,
    required String body,
    String kind = 'text',
    bool masked = false,
    String? imageUrl,
  }) => <String, Object?>{
    'id': 'mock-message-${++_sequence}',
    'conversationId': thread.id,
    'kind': kind,
    'senderId': senderId,
    'mine': mine,
    'body': body,
    'masked': masked,
    'imageUrl': imageUrl,
    'imageLargeUrl': imageUrl,
    'createdAt': _iso(_backend.now),
  };

  Map<String, Object?> _sendText(_Thread thread, String body) {
    _checkWritable(thread);
    final (String text, bool masked) = _mask(thread, _checkBody(body));
    final Map<String, Object?> message = _newMessage(
      thread,
      senderId: _meId(),
      mine: true,
      body: text,
      masked: masked,
    );
    thread.append(message);
    _scheduleReply(thread);
    return message;
  }

  Map<String, Object?> _sendPhoto(
    _Thread thread,
    PickedImage image,
    String? caption,
  ) {
    _checkWritable(thread);
    final String extension = image.extension.toLowerCase() == 'jpg'
        ? 'jpeg'
        : image.extension.toLowerCase();
    if (!_config.imageTypes.contains(extension)) {
      throw _failure(
        415,
        ApiErrorCode.fileTypeNotAllowed,
        'This file type is not allowed.',
      );
    }
    if (image.bytes.length > _config.maxPhotoMb * 1024 * 1024) {
      throw _failure(413, ApiErrorCode.fileTooLarge, 'This file is too large.');
    }
    final (String text, bool masked) = _mask(thread, caption?.trim() ?? '');
    // Held inline: there is no file server behind the mock.
    final Map<String, Object?> message = _newMessage(
      thread,
      senderId: _meId(),
      mine: true,
      body: text,
      kind: 'attachment',
      masked: masked,
      imageUrl: 'data:image/$extension;base64,${base64Encode(image.bytes)}',
    );
    thread.append(message);
    _scheduleReply(thread);
    return message;
  }

  /// D3 — once per direct conversation per run.
  void _scheduleReply(_Thread thread) {
    if (thread.kind != 'direct' || thread.replyScheduled) return;
    final String? otherId = thread.other?['id'] as String?;
    if (otherId == null) return;
    thread.replyScheduled = true;
    late final Timer timer;
    timer = Timer(replyDelay, () {
      _timers.remove(timer);
      thread.append(
        _newMessage(
          thread,
          senderId: otherId,
          mine: false,
          body: _isArabic
              ? 'شكرًا على رسالتك — سأعود إليك قريبًا.'
              : "Thanks for your message — I'll get back to you shortly.",
        ),
      );
      thread.json['unreadCount'] = thread.unreadCount + 1;
    });
    _timers.add(timer);
  }

  Map<String, Object?> _sendDisputeText(String disputeId, String body) {
    for (final _Thread thread in _inbox().threads) {
      if (thread.json['disputeId'] != disputeId) continue;
      if (thread.json['status'] == 'closed') {
        throw _failure(
          409,
          ApiErrorCode.conversationClosed,
          'This conversation was closed by Eventor.',
        );
      }
      // Never masked — an admin is reading the dispute.
      final Map<String, Object?> message = _newMessage(
        thread,
        senderId: _meId(),
        mine: true,
        body: _checkBody(body),
      );
      thread.append(message);
      return message;
    }
    throw _failure(404, 'DISPUTE_NOT_FOUND', 'Dispute not found.');
  }

  Map<String, Object?> _start(String userId, String body) {
    final _Inbox inbox = _inbox();
    for (final _Thread thread in inbox.threads) {
      if (thread.kind == 'direct' && thread.other?['id'] == userId) {
        _sendText(thread, body);
        return _detailJson(thread);
      }
    }

    Map<String, Object?>? provider;
    for (final Map<String, Object?> p in mockCatalogProviders) {
      if (p['id'] == userId) provider = p;
    }
    if (provider == null) {
      throw _failure(404, ApiErrorCode.userNotFound, 'User not found.');
    }
    _checkBody(body);

    final MockAccount account = _backend.requireSession();
    final Map<String, Object?> other = <String, Object?>{
      'id': userId,
      'name': provider['businessName'],
      'avatarUrl': null,
      'role': 'provider',
      'blocked': false,
    };
    final _Thread thread = _Thread(<String, Object?>{
      'id': 'mock-chat-new-${++_sequence}',
      'kind': 'direct',
      'status': 'open',
      'other': other,
      'lastMessage': null,
      'lastMessageAt': null,
      'unreadCount': 0,
      'booking': null,
      'canWrite': true,
      'participants': <Map<String, Object?>>[
        <String, Object?>{
          'id': account.id,
          'name': account.fullName,
          'avatarUrl': null,
          'role': 'client',
          'blocked': false,
        },
        other,
      ],
      'contactUnmasked': false,
      'disputeId': null,
      'closedReason': null,
      'createdAt': _iso(_backend.now),
    }, <Map<String, Object?>>[]);
    inbox.threads.add(thread);
    _sendText(thread, body);
    return _detailJson(thread);
  }

  void _markRead(String conversationId) {
    _thread(conversationId).json['unreadCount'] = 0;
  }

  // --------------------------------------------------------------- reports

  bool _report(String targetType, String targetId) =>
      _inbox().reports.add('$targetType:$targetId');

  void _requireMessage(String messageId) {
    for (final _Thread thread in _inbox().threads) {
      if (thread.messages.any(
        (Map<String, Object?> m) => m['id'] == messageId,
      )) {
        return;
      }
    }
    throw _failure(404, ApiErrorCode.messageNotFound, 'Message not found.');
  }

  void _requireUser(String userId) {
    final bool known =
        mockCatalogProviders.any(
          (Map<String, Object?> p) => p['id'] == userId,
        ) ||
        _inbox().threads.any(
          (_Thread t) => (t.json['participants']! as List<Object?>).any(
            (Object? p) => (p as Map<String, Object?>?)?['id'] == userId,
          ),
        );
    if (!known) {
      throw _failure(404, ApiErrorCode.userNotFound, 'User not found.');
    }
  }

  // --------------------------------------------------------- notifications

  /// Algiers-day buckets, from the backend's clock: today, the six days
  /// before it, then everything older.
  String _group(DateTime createdAt) {
    final DateTime now = _backend.now;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );
    if (!day.isBefore(today)) return 'today';
    if (day.isAfter(today.subtract(const Duration(days: 7)))) {
      return 'this_week';
    }
    return 'earlier';
  }

  Map<String, Object?> _notificationJson(Map<String, Object?> seed) {
    final DateTime createdAt = seed['createdAt']! as DateTime;
    return <String, Object?>{
      'id': seed['id'],
      'type': seed['type'],
      'title': _isArabic ? seed['titleAr'] : seed['titleEn'],
      'body': _isArabic ? seed['bodyAr'] : seed['bodyEn'],
      'data': seed['data'],
      'group': _group(createdAt),
      'read': seed['read'],
      'readAt': null,
      'createdAt': _iso(createdAt),
    };
  }

  ApiPage<Map<String, Object?>> _notifications(int page) {
    final List<Map<String, Object?>> all = _inbox().notifications;
    final int start = (page - 1) * _notificationPageSize;
    return ApiPage<Map<String, Object?>>(
      items: start >= all.length
          ? <Map<String, Object?>>[]
          : all
                .sublist(
                  start,
                  (start + _notificationPageSize).clamp(0, all.length),
                )
                .map(_notificationJson)
                .toList(),
      page: page,
      totalPages: (all.length / _notificationPageSize).ceil(),
      total: all.length,
    );
  }

  int _markNotificationsRead(bool Function(Map<String, Object?> n) which) {
    for (final Map<String, Object?> n in _inbox().notifications) {
      if (which(n)) n['read'] = true;
    }
    return unreadNotifications();
  }
}

/// [MessagingRepository] on the in-app [MockMessagingStore]. Every call
/// waits the backend's latency and needs a session, like the live one.
class MockMessagingRepository implements MessagingRepository {
  MockMessagingRepository(this._store, this._backend);

  final MockMessagingStore _store;
  final MockBackend _backend;

  Future<void> _call() async {
    await _backend.delay();
    _backend.requireSession();
  }

  @override
  Future<ApiPage<ConversationRow>> conversations({
    ConversationFilter filter = ConversationFilter.all,
    String? q,
    int page = 1,
  }) async {
    await _call();
    return _store._conversations(filter, q, page).map(ConversationRow.fromJson);
  }

  @override
  Future<ConversationDetail> conversation(String id) async {
    await _call();
    return ConversationDetail.fromJson(_store._detailJson(_store._thread(id)));
  }

  @override
  Future<MessagePage> messages(String conversationId, {String? before}) async {
    await _call();
    return MessagePage.fromEnvelope(_store._messages(conversationId, before));
  }

  @override
  Future<ChatMessage> sendText(String conversationId, String body) async {
    await _call();
    return ChatMessage.fromJson(
      _store._sendText(_store._thread(conversationId), body),
    );
  }

  @override
  Future<ChatMessage> sendPhoto(
    String conversationId,
    PickedImage image, {
    String? caption,
  }) async {
    await _call();
    return ChatMessage.fromJson(
      _store._sendPhoto(_store._thread(conversationId), image, caption),
    );
  }

  @override
  Future<ChatMessage> sendDisputeText(String disputeId, String body) async {
    await _call();
    return ChatMessage.fromJson(_store._sendDisputeText(disputeId, body));
  }

  @override
  Future<ConversationDetail> start(String userId, String body) async {
    await _call();
    return ConversationDetail.fromJson(_store._start(userId, body));
  }

  @override
  Future<void> markRead(String conversationId) async {
    await _call();
    _store._markRead(conversationId);
  }

  @override
  Future<bool> reportMessage(
    String messageId,
    ReportReason reason,
    String? note,
  ) async {
    await _call();
    _store._requireMessage(messageId);
    return _store._report('message', messageId);
  }

  @override
  Future<bool> reportUser(
    String userId,
    ReportReason reason,
    String? note,
  ) async {
    await _call();
    _store._requireUser(userId);
    return _store._report('user', userId);
  }

  @override
  Future<ConversationRow?> findWith(String userId) async {
    // As live: the direct chat with that user, found by id, however far
    // down the list it is.
    await _call();
    for (final _Thread thread in _store._inbox().threads) {
      if (thread.kind == 'direct' && thread.other?['id'] == userId) {
        return ConversationRow.fromJson(_store._rowJson(thread));
      }
    }
    return null;
  }
}

/// [NotificationsRepository] on the in-app [MockMessagingStore].
class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository(this._store, this._backend);

  final MockMessagingStore _store;
  final MockBackend _backend;

  Future<void> _call() async {
    await _backend.delay();
    _backend.requireSession();
  }

  @override
  Future<ApiPage<AppNotification>> list({int page = 1}) async {
    await _call();
    return _store._notifications(page).map(AppNotification.fromJson);
  }

  @override
  Future<int> markRead(List<String> ids) async {
    await _call();
    return _store._markNotificationsRead(
      (Map<String, Object?> n) => ids.contains(n['id']),
    );
  }

  @override
  Future<int> markAllRead() async {
    await _call();
    return _store._markNotificationsRead((Map<String, Object?> _) => true);
  }

  @override
  Future<void> delete(String id) async {
    await _call();
    // Idempotent, as the repository contract says.
    _store._inbox().notifications.removeWhere(
      (Map<String, Object?> n) => n['id'] == id,
    );
  }

  @override
  Future<({int notifications, int conversations})> counts() async {
    await _call();
    return (
      notifications: _store.unreadNotifications(),
      conversations: _store.unreadConversations(),
    );
  }
}
