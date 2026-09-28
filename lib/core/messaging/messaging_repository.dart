import 'package:dio/dio.dart';

import '../network/api_client.dart';
import 'conversation_filter.dart';
import 'models/chat_message.dart';
import 'models/conversation.dart';
import 'models/report_reason.dart';
import 'picked_image.dart';

/// Threads and their messages — screen 14's list, a thread's own screen, and
/// the moderation actions a thread or a message can carry: one-to-one chats,
/// the support conversation, and a booking's dispute thread.
abstract interface class MessagingRepository {
  /// Screen 14's list, newest thread first. [filter] is left off the request
  /// when it is [ConversationFilter.all], and a blank [q] (after trimming)
  /// is never sent — [page] is always 20 to a page.
  Future<ApiPage<ConversationRow>> conversations({
    ConversationFilter filter = ConversationFilter.all,
    String? q,
    int page = 1,
  });

  Future<ConversationDetail> conversation(String id);

  /// One page of a thread's history, oldest first. Omitting [before] loads
  /// the newest page; the server's own default page size (30) is left
  /// unsent rather than named here.
  Future<MessagePage> messages(String conversationId, {String? before});

  Future<ChatMessage> sendText(String conversationId, String body);

  Future<ChatMessage> sendPhoto(
    String conversationId,
    PickedImage image, {
    String? caption,
  });

  /// A dispute thread's own send route — keyed by [disputeId], not the
  /// conversation id, because the dispute and its conversation are different
  /// records on the server.
  Future<ChatMessage> sendDisputeText(String disputeId, String body);

  /// Opens (or reopens) a direct thread with [userId], sending [body] as its
  /// first message in the same call.
  Future<ConversationDetail> start(String userId, String body);

  Future<void> markRead(String conversationId);

  /// `true` once the server has recorded the report.
  Future<bool> reportMessage(
    String messageId,
    ReportReason reason,
    String? note,
  );

  /// `true` once the server has recorded the report.
  Future<bool> reportUser(String userId, ReportReason reason, String? note);

  /// The direct conversation already open with [userId], if there is one —
  /// a provider's profile "Message" button skips [start] when it finds one.
  /// Support and dispute threads never match, even when [userId] happens to
  /// sit in one of those too.
  Future<ConversationRow?> findWith(String userId);
}

/// [MessagingRepository] against the live API.
class ApiMessagingRepository implements MessagingRepository {
  ApiMessagingRepository(this._api);

  final ApiClient _api;
  static const int _pageSize = 20;

  @override
  Future<ApiPage<ConversationRow>> conversations({
    ConversationFilter filter = ConversationFilter.all,
    String? q,
    int page = 1,
  }) async {
    final String? query = q?.trim();
    final ApiPage<Map<String, Object?>> result = await _api.getPage(
      '/app/conversations',
      query: <String, Object?>{
        if (filter != ConversationFilter.all) 'filter': filter.apiValue,
        if (query != null && query.isNotEmpty) 'q': query,
        'page': page,
        'limit': _pageSize,
      },
    );
    return result.map(ConversationRow.fromJson);
  }

  @override
  Future<ConversationDetail> conversation(String id) async =>
      ConversationDetail.fromJson(
        _object(await _api.get('/app/conversations/$id')),
      );

  @override
  Future<MessagePage> messages(String conversationId, {String? before}) async {
    final Map<String, Object?> envelope = await _api.getEnvelope(
      '/app/conversations/$conversationId/messages',
      query: before == null ? null : <String, Object?>{'before': before},
    );
    return MessagePage.fromEnvelope(envelope);
  }

  @override
  Future<ChatMessage> sendText(String conversationId, String body) async =>
      ChatMessage.fromJson(
        _object(
          await _api.post(
            '/app/conversations/$conversationId/messages',
            body: <String, Object?>{'body': body},
          ),
        ),
      );

  @override
  Future<ChatMessage> sendPhoto(
    String conversationId,
    PickedImage image, {
    String? caption,
  }) async {
    final String? trimmedCaption = caption?.trim();
    final Object? data = await _api.upload(
      '/app/conversations/$conversationId/messages',
      // Built inside the closure: a retry after a token refresh has to
      // rebuild the form, since a FormData stream can only be read once.
      form: () => FormData.fromMap(<String, Object?>{
        'file': MultipartFile.fromBytes(image.bytes, filename: image.name),
        if (trimmedCaption != null && trimmedCaption.isNotEmpty)
          'body': trimmedCaption,
      }),
    );
    return ChatMessage.fromJson(_object(data));
  }

  @override
  Future<ChatMessage> sendDisputeText(String disputeId, String body) async =>
      ChatMessage.fromJson(
        _object(
          await _api.post(
            '/app/disputes/$disputeId/messages',
            body: <String, Object?>{'body': body},
          ),
        ),
      );

  @override
  Future<ConversationDetail> start(String userId, String body) async =>
      ConversationDetail.fromJson(
        _object(
          await _api.post(
            '/app/conversations',
            body: <String, Object?>{'userId': userId, 'body': body},
          ),
        ),
      );

  @override
  Future<void> markRead(String conversationId) async {
    await _api.post('/app/conversations/$conversationId/read');
  }

  @override
  Future<bool> reportMessage(
    String messageId,
    ReportReason reason,
    String? note,
  ) async {
    final String? trimmedNote = note?.trim();
    final Object? data = await _api.post(
      '/app/messages/$messageId/report',
      body: <String, Object?>{
        'reason': reason.apiValue,
        if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
      },
    );
    return _created(data);
  }

  @override
  Future<bool> reportUser(
    String userId,
    ReportReason reason,
    String? note,
  ) async {
    final String? trimmedNote = note?.trim();
    final Object? data = await _api.post(
      '/app/reports',
      body: <String, Object?>{
        'targetType': 'user',
        'targetId': userId,
        'reason': reason.apiValue,
        if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
      },
    );
    return _created(data);
  }

  @override
  Future<ConversationRow?> findWith(String userId) async {
    // The server returns only the direct chat with that user — an empty
    // list when there is none (since 2026-09-27; the app used to search by
    // name and match the id).
    final ApiPage<Map<String, Object?>> result = await _api.getPage(
      '/app/conversations',
      query: <String, Object?>{'userId': userId, 'limit': 1},
    );
    for (final Map<String, Object?> json in result.items) {
      final ConversationRow row = ConversationRow.fromJson(json);
      if (row.kind == ConversationKind.direct) return row;
    }
    return null;
  }

  static Map<String, Object?> _object(Object? data) =>
      data is Map<String, Object?> ? data : const <String, Object?>{};

  static bool _created(Object? data) =>
      data is Map<String, Object?> && data['created'] == true;
}
