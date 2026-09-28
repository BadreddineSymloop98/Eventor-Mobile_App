import 'dart:async';

import 'package:eventor/core/catalog/catalog_repository.dart';
import 'package:eventor/core/catalog/favourites_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/catalog/service_query.dart';
import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/messaging/chat_poller.dart';
import 'package:eventor/core/messaging/conversation_filter.dart';
import 'package:eventor/core/messaging/messaging_repository.dart';
import 'package:eventor/core/messaging/models/chat_message.dart';
import 'package:eventor/core/messaging/models/conversation.dart';
import 'package:eventor/core/messaging/models/report_reason.dart';
import 'package:eventor/core/messaging/picked_image.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/network/api_client.dart';
import 'package:eventor/core/notifications/models/app_notification.dart';
import 'package:eventor/core/notifications/notifications_repository.dart';
import 'package:eventor/core/reference/reference_repository.dart';
import 'package:eventor/core/session/token_store.dart';
import 'package:eventor/features/auth/data/auth_repository.dart';
import 'package:eventor/features/auth/data/documents_repository.dart';
import 'package:flutter/foundation.dart';

import 'fixtures.dart';

/// An [ApiFailure] as the server would send it, for scripting fakes.
ApiFailure apiFailure(
  String code, {
  int statusCode = 422,
  String message = 'Server says no.',
  Map<String, Object?>? details,
}) {
  return ApiFailure(
    statusCode: statusCode,
    code: code,
    message: message,
    details: details,
  );
}

/// A signed-in account for tests.
AppUser testUser({
  UserRole role = UserRole.client,
  VerificationStatus? verificationStatus,
  String fullName = 'Amina Benali',
  String email = 'amina@example.com',
  Wilaya? wilaya,
}) {
  return AppUser(
    id: 'user-1',
    role: role,
    isBlocked: false,
    verificationStatus:
        verificationStatus ??
        (role == UserRole.provider
            ? VerificationStatus.pending
            : VerificationStatus.notRequired),
    fullName: fullName,
    email: email,
    emailVerified: true,
    language: 'en',
    wilaya: wilaya,
  );
}

/// [AuthRepository] with every answer scripted.
///
/// Each call records what it was given and then returns the matching
/// `…Result`, or throws the matching `…Error` when one is set. Leave both
/// alone and the call succeeds with a sensible default.
class FakeAuthRepository implements AuthRepository {
  // What the calls were given.
  final List<RegistrationRequest> registrations = <RegistrationRequest>[];
  final List<({String email, String code})> verifications =
      <({String email, String code})>[];
  final List<String> resends = <String>[];
  final List<({String email, String password})> logins =
      <({String email, String password})>[];
  final List<String> forgotten = <String>[];
  final List<({String email, String code})> resetChecks =
      <({String email, String code})>[];
  final List<({String email, String code, String password})> resets =
      <({String email, String code, String password})>[];
  final List<({String token, String password})> setPasswords =
      <({String token, String password})>[];
  int logoutCalls = 0;
  final List<int> wilayaUpdates = <int>[];

  // What they answer.
  Failure? registerError;
  Failure? verifyError;
  Failure? resendError;
  Failure? loginError;
  Failure? forgotError;
  Failure? verifyResetError;
  Failure? resetError;
  Failure? setPasswordError;
  Failure? updateWilayaError;

  AppUser user = testUser();
  AppUser? restoredUser;
  int resendAfterSeconds = 60;

  /// When set, calls wait on it — for asserting the busy state mid-flight.
  Completer<void>? gate;

  Future<void> _wait() async {
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
  }

  @override
  Future<CodeSent> register(RegistrationRequest request) async {
    registrations.add(request);
    await _wait();
    if (registerError != null) throw registerError!;
    return CodeSent(
      email: request.email,
      resendAfterSeconds: resendAfterSeconds,
    );
  }

  @override
  Future<AppUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    verifications.add((email: email, code: code));
    await _wait();
    if (verifyError != null) throw verifyError!;
    return user;
  }

  @override
  Future<CodeSent> resendVerification(String email) async {
    resends.add(email);
    await _wait();
    if (resendError != null) throw resendError!;
    return CodeSent(email: email, resendAfterSeconds: resendAfterSeconds);
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    logins.add((email: email, password: password));
    await _wait();
    if (loginError != null) throw loginError!;
    return user;
  }

  @override
  Future<void> forgotPassword(String email) async {
    forgotten.add(email);
    await _wait();
    if (forgotError != null) throw forgotError!;
  }

  @override
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    resetChecks.add((email: email, code: code));
    await _wait();
    if (verifyResetError != null) throw verifyResetError!;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    resets.add((email: email, code: code, password: password));
    await _wait();
    if (resetError != null) throw resetError!;
  }

  @override
  Future<AppUser> setPassword({
    required String token,
    required String password,
  }) async {
    setPasswords.add((token: token, password: password));
    await _wait();
    if (setPasswordError != null) throw setPasswordError!;
    return user;
  }

  @override
  Future<AppUser?> restoreSession() async => restoredUser;

  @override
  Future<AppUser> currentUser() async => user;

  @override
  Future<AppUser> updateWilaya(int wilayaCode) async {
    wilayaUpdates.add(wilayaCode);
    await _wait();
    final Failure? error = updateWilayaError;
    if (error != null) throw error;
    return user = testUser(
      role: user.role,
      fullName: user.fullName,
      email: user.email,
      wilaya: Wilaya(
        code: wilayaCode,
        nameEn: 'Wilaya $wilayaCode',
        nameAr: 'ولاية $wilayaCode',
      ),
    );
  }

  @override
  Future<void> logout() async => logoutCalls++;
}

/// [ReferenceRepository] serving a short fixed list, or failing.
class FakeReferenceRepository implements ReferenceRepository {
  static const List<Wilaya> sampleWilayas = <Wilaya>[
    Wilaya(code: 9, nameEn: 'Blida', nameAr: 'البليدة'),
    Wilaya(code: 16, nameEn: 'Alger', nameAr: 'الجزائر'),
    Wilaya(code: 42, nameEn: 'Tipaza', nameAr: 'تيبازة'),
  ];

  static const List<ServiceCategory> sampleCategories = <ServiceCategory>[
    ServiceCategory(id: 'cat-photo', nameEn: 'Photography', nameAr: 'التصوير'),
    ServiceCategory(id: 'cat-venue', nameEn: 'Venues', nameAr: 'القاعات'),
  ];

  bool fail = false;

  /// What [wilayas] answers.
  List<Wilaya> wilayaList = sampleWilayas;

  @override
  Future<List<Wilaya>> wilayas() async {
    if (fail) throw const NetworkFailure();
    return wilayaList;
  }

  @override
  Future<List<ServiceCategory>> categories() async {
    if (fail) throw const NetworkFailure();
    return sampleCategories;
  }

  /// What [communes] answers, for any wilaya.
  List<Commune> communeList = const <Commune>[
    Commune(id: 'com-hydra', wilayaCode: 16, nameEn: 'Hydra', nameAr: 'حيدرة'),
  ];

  @override
  Future<List<Commune>> communes(int wilayaCode) async {
    if (fail) throw const NetworkFailure();
    return communeList;
  }
}

/// [DocumentsRepository] that keeps the three documents in memory.
class FakeDocumentsRepository implements DocumentsRepository {
  final Map<ProviderDocumentType, ProviderDocumentStatus> statuses =
      <ProviderDocumentType, ProviderDocumentStatus>{
        for (final ProviderDocumentType type in ProviderDocumentType.values)
          type: ProviderDocumentStatus.missing,
      };

  final List<ProviderDocumentType> uploads = <ProviderDocumentType>[];
  Failure? uploadError;
  Failure? fetchError;

  ProviderDocuments _snapshot() => ProviderDocuments(
    verificationStatus: VerificationStatus.pending,
    maxFileSizeMb: 5,
    acceptedTypes: const <String>['pdf', 'jpeg', 'png'],
    documents: <ProviderDocument>[
      for (final MapEntry<ProviderDocumentType, ProviderDocumentStatus> e
          in statuses.entries)
        ProviderDocument(type: e.key, status: e.value),
    ],
  );

  @override
  Future<ProviderDocuments> fetch() async {
    if (fetchError != null) throw fetchError!;
    return _snapshot();
  }

  @override
  Future<ProviderDocuments> upload({
    required ProviderDocumentType type,
    required String path,
    required String fileName,
    ValueChanged<double>? onProgress,
  }) async {
    uploads.add(type);
    if (uploadError != null) throw uploadError!;
    statuses[type] = ProviderDocumentStatus.pending;
    return _snapshot();
  }
}

/// [AppConfigRepository] that never touches the network.
class FakeConfigRepository extends AppConfigRepository {
  FakeConfigRepository([this.config = const AppConfig()])
    : super(ApiClient(tokens: TokenStore(), languageCode: () => 'en'));

  AppConfig config;

  @override
  AppConfig get current => config;

  @override
  Future<AppConfig> load() async => config;
}

/// [FavouritesRepository] that records every call.
class FakeFavouritesRepository implements FavouritesRepository {
  /// `add:service:s-1`, `remove:pack:k-1`, `removeById:fav-1`, `list:…`.
  final List<String> calls = <String>[];

  /// What [list] returns, newest first.
  List<Favourite> items = fixtureList('favourites_page.json')
      .map(Favourite.fromJson)
      .toList();

  /// Thrown by the next call only.
  Failure? failNext;

  /// Thrown by every call while set — a network that is down.
  Failure? failAll;

  /// When set, calls wait on it — for asserting the in-flight state.
  Completer<void>? gate;

  Future<void> _enter(String call) async {
    calls.add(call);
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
    final Failure? always = failAll;
    if (always != null) throw always;
    final Failure? failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
  }

  @override
  Future<ApiPage<Favourite>> list({
    FavouriteKind? kind,
    String? categoryId,
    int page = 1,
  }) async {
    await _enter('list:${kind?.apiValue}:$categoryId:$page');
    final List<Favourite> found = items
        .where((Favourite f) => kind == null || f.kind == kind)
        .where(
          (Favourite f) => categoryId == null || f.category?.id == categoryId,
        )
        .toList();
    return ApiPage<Favourite>(
      items: page == 1 ? found : <Favourite>[],
      page: page,
      totalPages: found.isEmpty ? 0 : 1,
      total: found.length,
    );
  }

  @override
  Future<Favourite> add(FavouriteTarget target) async {
    await _enter('add:$target');
    return items.first;
  }

  @override
  Future<void> remove(FavouriteTarget target) => _enter('remove:$target');

  @override
  Future<void> removeById(String favouriteId) async {
    await _enter('removeById:$favouriteId');
    items = items.where((Favourite f) => f.id != favouriteId).toList();
  }
}

/// [CatalogRepository] answering from the saved live fixtures, with every
/// answer replaceable and every failure injectable.
class FakeCatalogRepository implements CatalogRepository {
  HomeFeed homeFeed = HomeFeed.fromJson(fixtureData('home.json'));
  List<CategoryWithCount> categoryList = fixtureList('categories.json')
      .map(CategoryWithCount.fromJson)
      .toList();

  /// Paged 20 at a time by [services].
  List<ServiceCard> serviceItems = fixtureList('services_page.json')
      .map(ServiceCard.fromJson)
      .toList();
  ServiceDetail serviceDetail = ServiceDetail.fromJson(
    fixtureData('service_detail.json'),
  );
  ProviderDetail providerDetail = ProviderDetail.fromJson(
    fixtureData('provider_detail.json'),
  );
  List<PackCard> packItems = fixtureList('packs_page.json')
      .map(PackCard.fromJson)
      .toList();
  PackDetail packDetail = PackDetail.fromJson(fixtureData('pack_detail.json'));

  /// Every day from here on is available, except the 10th of each month
  /// (busy) and the 20th (blocked).
  DateTime firstBookable = DateTime(2026, 1, 1);

  // Failures, per call.
  Failure? homeError;
  Failure? servicesError;
  Failure? serviceError;
  Failure? providerError;
  Failure? packsError;
  Failure? packError;
  Failure? availabilityError;

  // What the calls were given.
  final List<({ServiceQuery query, int page, int limit})> servicePages =
      <({ServiceQuery query, int page, int limit})>[];
  final List<({EventType? eventType, PackOrder order, int page})> packQueries =
      <({EventType? eventType, PackOrder order, int page})>[];
  final List<DateTime> availabilityMonths = <DateTime>[];
  int homeCalls = 0;

  /// When set, calls wait on it — for asserting loading states.
  Completer<void>? gate;

  Future<void> _wait() async {
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
  }

  static ApiPage<T> _page<T>(List<T> items, int page, int limit) {
    final int start = (page - 1) * limit;
    return ApiPage<T>(
      items: start >= items.length
          ? <T>[]
          : items.sublist(start, (start + limit).clamp(0, items.length)),
      page: page,
      totalPages: (items.length / limit).ceil(),
      total: items.length,
    );
  }

  Availability _month(DateTime month) {
    final int days = DateTime(month.year, month.month + 1, 0).day;
    DayState stateOf(int d) {
      final DateTime date = DateTime(month.year, month.month, d);
      if (date.isBefore(firstBookable)) return DayState.blocked;
      if (d == 10) return DayState.busy;
      if (d == 20) return DayState.blocked;
      return DayState.available;
    }

    return Availability(
      month: monthParam(month),
      minNoticeDays: 1,
      firstBookableDate: firstBookable,
      days: <AvailabilityDay>[
        for (int d = 1; d <= days; d++)
          AvailabilityDay(
            date: DateTime(month.year, month.month, d),
            state: stateOf(d),
          ),
      ],
    );
  }

  @override
  Future<HomeFeed> home() async {
    homeCalls++;
    await _wait();
    if (homeError != null) throw homeError!;
    return homeFeed;
  }

  @override
  Future<List<CategoryWithCount>> categories() async {
    await _wait();
    return categoryList;
  }

  @override
  Future<ApiPage<ServiceCard>> services(
    ServiceQuery query, {
    int page = 1,
    int limit = 20,
  }) async {
    servicePages.add((query: query, page: page, limit: limit));
    await _wait();
    if (servicesError != null) throw servicesError!;
    return _page(serviceItems, page, limit);
  }

  @override
  Future<ServiceDetail> service(String id) async {
    await _wait();
    if (serviceError != null) throw serviceError!;
    return serviceDetail;
  }

  @override
  Future<Availability> serviceAvailability(String id, DateTime month) async {
    availabilityMonths.add(month);
    await _wait();
    if (availabilityError != null) throw availabilityError!;
    return _month(month);
  }

  @override
  Future<ProviderDetail> provider(String id) async {
    await _wait();
    if (providerError != null) throw providerError!;
    return providerDetail;
  }

  @override
  Future<ApiPage<PackCard>> packs({
    EventType? eventType,
    PackOrder order = PackOrder.savings,
    int page = 1,
  }) async {
    packQueries.add((eventType: eventType, order: order, page: page));
    await _wait();
    if (packsError != null) throw packsError!;
    return _page(
      packItems
          .where((PackCard p) => eventType == null || p.eventType == eventType)
          .toList(),
      page,
      20,
    );
  }

  @override
  Future<PackDetail> pack(String id) async {
    await _wait();
    if (packError != null) throw packError!;
    return packDetail;
  }

  @override
  Future<Availability> packAvailability(String id, DateTime month) async {
    availabilityMonths.add(month);
    await _wait();
    if (availabilityError != null) throw availabilityError!;
    return _month(month);
  }
}

/// [MessagingRepository] answering from the saved messaging fixtures, with
/// every answer replaceable and every failure injectable.
class FakeMessagingRepository implements MessagingRepository {
  /// What the calls were given — `conversations:all:null:1`,
  /// `conversation:c-lumiere`, `messages:c-lumiere:null`,
  /// `sendText:c-lumiere:hi`, `sendPhoto:c-lumiere:a.jpg:cap`,
  /// `sendDisputeText:d-2041:hi`, `start:p-lumiere:hi`,
  /// `markRead:c-lumiere`, `reportMessage:m-4:spam:null`,
  /// `reportUser:p-lumiere:spam:note`, `findWith:p-lumiere:Studio`.
  final List<String> calls = <String>[];

  /// What [conversations] filters and pages, 20 at a time.
  List<ConversationRow> rows = fixtureList(
    'conversations_page.json',
    dir: 'messaging',
  ).map(ConversationRow.fromJson).toList();

  /// What [conversation] answers, by id.
  Map<String, ConversationDetail> details = <String, ConversationDetail>{
    'c-lumiere': ConversationDetail.fromJson(
      fixtureData('conversation_detail.json', dir: 'messaging'),
    ),
    'c-dispute': ConversationDetail.fromJson(
      fixtureData('conversation_dispute.json', dir: 'messaging'),
    ),
  };

  /// Each conversation's messages, oldest first. [messages] pages 30 back
  /// from the newest, with a `before` cursor, and the sends append here.
  Map<String, List<ChatMessage>> threads = <String, List<ChatMessage>>{
    'c-lumiere': MessagePage.fromEnvelope(
      fixture('messages_page.json', dir: 'messaging'),
    ).items,
  };

  /// What both report calls answer.
  bool reportCreated = true;

  /// Thrown by the next call only, whichever it is.
  Failure? failNext;

  /// Thrown by [conversations], [conversation] and [messages] while set.
  Failure? loadError;

  /// Thrown by [sendText], [sendPhoto] and [sendDisputeText] while set.
  Failure? sendError;
  Failure? startError;
  Failure? markReadError;
  Failure? findError;

  /// When set, every call waits on it — for asserting loading states.
  Completer<void>? gate;

  /// When set, only the sends wait on it — for asserting the D8 sending
  /// state while loads and polls still answer.
  Completer<void>? sendGate;

  int _sent = 0;

  static const int _pageSize = 20;
  static const int _messagePageSize = 30;

  Future<void> _enter(
    String call, {
    Failure? Function()? error,
    bool isSend = false,
  }) async {
    calls.add(call);
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
    if (isSend) {
      final Completer<void>? sending = sendGate;
      if (sending != null) await sending.future;
    }
    final Failure? once = failNext;
    if (once != null) {
      failNext = null;
      throw once;
    }
    // Read only now, after the gates, so a test can script the failure
    // while the call is still waiting.
    final Failure? always = error?.call();
    if (always != null) throw always;
  }

  ChatMessage _append(
    String conversationId, {
    required String body,
    MessageKind kind = MessageKind.text,
    String? imageUrl,
  }) {
    final int n = ++_sent;
    final ChatMessage message = ChatMessage(
      id: 'sent-$n',
      conversationId: conversationId,
      kind: kind,
      senderId: 'u-me',
      mine: true,
      body: body,
      masked: false,
      imageUrl: imageUrl,
      imageLargeUrl: imageUrl,
      // After every fixture message, in any time zone.
      createdAt: DateTime.utc(2026, 3, 12, 15, n).toLocal(),
    );
    threads.putIfAbsent(conversationId, () => <ChatMessage>[]).add(message);
    return message;
  }

  @override
  Future<ApiPage<ConversationRow>> conversations({
    ConversationFilter filter = ConversationFilter.all,
    String? q,
    int page = 1,
  }) async {
    await _enter(
      'conversations:${filter.apiValue}:$q:$page',
      error: () => loadError,
    );
    final String query = (q ?? '').trim().toLowerCase();
    final List<ConversationRow> found = rows
        .where(
          (ConversationRow row) => switch (filter) {
            ConversationFilter.all => true,
            ConversationFilter.unread => row.unreadCount > 0,
            ConversationFilter.booking => row.booking != null,
          },
        )
        .where((ConversationRow row) {
          if (query.isEmpty) return true;
          final String name = row.isGroup
              ? 'Eventor support'
              : row.other?.name ?? '';
          return name.toLowerCase().contains(query);
        })
        .toList();
    final int start = (page - 1) * _pageSize;
    return ApiPage<ConversationRow>(
      items: start >= found.length
          ? <ConversationRow>[]
          : found.sublist(start, (start + _pageSize).clamp(0, found.length)),
      page: page,
      totalPages: (found.length / _pageSize).ceil(),
      total: found.length,
    );
  }

  @override
  Future<ConversationDetail> conversation(String id) async {
    await _enter('conversation:$id', error: () => loadError);
    final ConversationDetail? detail = details[id];
    if (detail == null) {
      throw apiFailure(ApiErrorCode.conversationNotFound, statusCode: 404);
    }
    return detail;
  }

  @override
  Future<MessagePage> messages(String conversationId, {String? before}) async {
    await _enter('messages:$conversationId:$before', error: () => loadError);
    final List<ChatMessage> thread = threads[conversationId] ?? <ChatMessage>[];
    int end = thread.length;
    if (before != null) {
      end = thread.indexWhere((ChatMessage m) => m.id == before);
      if (end == -1) {
        throw apiFailure(ApiErrorCode.messageNotFound, statusCode: 404);
      }
    }
    final int start = (end - _messagePageSize).clamp(0, end);
    final List<ChatMessage> items = thread.sublist(start, end);
    final bool hasMore = start > 0;
    return MessagePage(
      items: items,
      hasMore: hasMore,
      nextBefore: hasMore ? items.first.id : null,
    );
  }

  @override
  Future<ChatMessage> sendText(String conversationId, String body) async {
    await _enter(
      'sendText:$conversationId:$body',
      error: () => sendError,
      isSend: true,
    );
    return _append(conversationId, body: body);
  }

  @override
  Future<ChatMessage> sendPhoto(
    String conversationId,
    PickedImage image, {
    String? caption,
  }) async {
    await _enter(
      'sendPhoto:$conversationId:${image.name}:$caption',
      error: () => sendError,
      isSend: true,
    );
    return _append(
      conversationId,
      body: caption ?? '',
      kind: MessageKind.attachment,
      imageUrl: 'https://files.example/${image.name}',
    );
  }

  @override
  Future<ChatMessage> sendDisputeText(String disputeId, String body) async {
    await _enter(
      'sendDisputeText:$disputeId:$body',
      error: () => sendError,
      isSend: true,
    );
    String conversationId = disputeId;
    for (final ConversationDetail detail in details.values) {
      if (detail.disputeId == disputeId) conversationId = detail.id;
    }
    return _append(conversationId, body: body);
  }

  @override
  Future<ConversationDetail> start(String userId, String body) async {
    await _enter('start:$userId:$body', error: () => startError);
    final ConversationDetail base = details['c-lumiere']!;
    final ConversationDetail created = ConversationDetail(
      id: 'c-new',
      kind: base.kind,
      isClosed: base.isClosed,
      other: base.other,
      lastMessage: body,
      lastMessageAt: DateTime(2026, 3, 12, 15),
      unreadCount: 0,
      booking: base.booking,
      canWrite: base.canWrite,
      participants: base.participants,
      contactUnmasked: base.contactUnmasked,
      disputeId: base.disputeId,
      closedByModeration: base.closedByModeration,
      createdAt: DateTime(2026, 3, 12, 15),
    );
    details['c-new'] = created;
    threads['c-new'] = <ChatMessage>[];
    _append('c-new', body: body);
    return created;
  }

  @override
  Future<void> markRead(String conversationId) =>
      _enter('markRead:$conversationId', error: () => markReadError);

  @override
  Future<bool> reportMessage(
    String messageId,
    ReportReason reason,
    String? note,
  ) async {
    await _enter('reportMessage:$messageId:${reason.apiValue}:$note');
    return reportCreated;
  }

  @override
  Future<bool> reportUser(
    String userId,
    ReportReason reason,
    String? note,
  ) async {
    await _enter('reportUser:$userId:${reason.apiValue}:$note');
    return reportCreated;
  }

  @override
  Future<ConversationRow?> findWith(String userId) async {
    await _enter('findWith:$userId', error: () => findError);
    for (final ConversationRow row in rows) {
      if (row.kind == ConversationKind.direct && row.other?.id == userId) {
        return row;
      }
    }
    return null;
  }
}

/// [NotificationsRepository] answering from `notifications_page.json`.
class FakeNotificationsRepository implements NotificationsRepository {
  /// `list:1`, `markRead:n-1,n-2`, `markAllRead`, `counts`.
  final List<String> calls = <String>[];

  /// What [list] pages, 20 at a time; the reads flip `read` here.
  List<AppNotification> items = fixtureList(
    'notifications_page.json',
    dir: 'messaging',
  ).map(AppNotification.fromJson).toList();

  /// What [counts] answers. The reads keep its `notifications` in step with
  /// [items], so a badge refreshed after a read agrees with the list.
  ({int notifications, int conversations}) countsResult = (
    notifications: 2,
    conversations: 1,
  );

  /// Thrown by the next call only.
  Failure? failNext;

  /// When set, calls wait on it — for asserting loading states.
  Completer<void>? gate;

  static const int _pageSize = 20;

  Future<void> _enter(String call) async {
    calls.add(call);
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
    final Failure? failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
  }

  int _markRead(bool Function(AppNotification n) which) {
    items = <AppNotification>[
      for (final AppNotification n in items)
        which(n) ? n.copyWith(read: true) : n,
    ];
    final int unread = items.where((AppNotification n) => !n.read).length;
    countsResult = (
      notifications: unread,
      conversations: countsResult.conversations,
    );
    return unread;
  }

  @override
  Future<ApiPage<AppNotification>> list({int page = 1}) async {
    await _enter('list:$page');
    final int start = (page - 1) * _pageSize;
    return ApiPage<AppNotification>(
      items: start >= items.length
          ? <AppNotification>[]
          : items.sublist(start, (start + _pageSize).clamp(0, items.length)),
      page: page,
      totalPages: (items.length / _pageSize).ceil(),
      total: items.length,
    );
  }

  @override
  Future<int> markRead(List<String> ids) async {
    await _enter('markRead:${ids.join(',')}');
    return _markRead((AppNotification n) => ids.contains(n.id));
  }

  @override
  Future<int> markAllRead() async {
    await _enter('markAllRead');
    return _markRead((AppNotification _) => true);
  }

  @override
  Future<void> delete(String id) async {
    await _enter('delete:$id');
    items = items.where((AppNotification n) => n.id != id).toList();
    countsResult = (
      notifications: items.where((AppNotification n) => !n.read).length,
      conversations: countsResult.conversations,
    );
  }

  @override
  Future<({int notifications, int conversations})> counts() async {
    await _enter('counts');
    return countsResult;
  }
}

/// [ChatUpdates] that only ticks when a test calls [tick] — no timers, no
/// app lifecycle.
class ManualChatUpdates implements ChatUpdates {
  Future<void> Function()? onTick;
  bool started = false;
  bool stopped = false;
  int pauses = 0;
  int resumes = 0;

  /// Runs the view model's tick once, as the poller would.
  Future<void> tick() => onTick?.call() ?? Future<void>.value();

  @override
  void start(Future<void> Function() onTick) {
    this.onTick = onTick;
    started = true;
  }

  @override
  void pause() => pauses++;

  @override
  void resume() => resumes++;

  @override
  void stop() => stopped = true;
}
