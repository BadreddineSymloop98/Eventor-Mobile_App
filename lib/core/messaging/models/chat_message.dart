import '../../catalog/models/json_read.dart';

/// A message's shape — a text bubble, an image bubble, or a system line
/// like "Booking requested".
enum MessageKind {
  text,
  attachment,
  system;

  /// An unrecognised kind (a sticker, say) reads as [text] — the body still
  /// has something to show, even if the intended treatment is lost.
  static MessageKind fromApi(String? value) => switch (value) {
        'attachment' => MessageKind.attachment,
        'system' => MessageKind.system,
        _ => MessageKind.text,
      };
}

/// One message in a thread.
class ChatMessage {
  /// The body a removed message is replaced with, everywhere — the sender's
  /// bubble, the row preview, the other side's bubble.
  static const String removedBody = '[removed by Eventor]';

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.kind,
    required this.senderId,
    required this.mine,
    required this.body,
    required this.masked,
    required this.imageUrl,
    required this.imageLargeUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, Object?> json) => ChatMessage(
        id: json['id']! as String,
        conversationId: readString(json, 'conversationId'),
        kind: MessageKind.fromApi(json['kind'] as String?),
        senderId: readStringOrNull(json, 'senderId'),
        mine: readBool(json, 'mine'),
        body: readString(json, 'body'),
        masked: readBool(json, 'masked'),
        imageUrl: readStringOrNull(json, 'imageUrl'),
        imageLargeUrl: readStringOrNull(json, 'imageLargeUrl'),
        createdAt: readDate(json, 'createdAt'),
      );

  final String id;
  final String conversationId;
  final MessageKind kind;

  /// `null` for a system message.
  final String? senderId;
  final bool mine;
  final String body;

  /// Whether the server redacted a phone number or similar out of [body].
  final bool masked;
  final String? imageUrl;
  final String? imageLargeUrl;
  final DateTime createdAt;

  bool get isRemoved => body.trim() == removedBody;

  /// A removed attachment keeps its image fields at `null`, but checking
  /// [isRemoved] too means a future bug that leaves a stale URL behind can
  /// never resurrect the picture.
  bool get hasImage => imageUrl != null && !isRemoved;

  /// The same message with fresh signed URLs — everything else carried over
  /// unchanged, since a re-fetch only moves the query string's expiry.
  ChatMessage withImages({String? imageUrl, String? imageLargeUrl}) =>
      ChatMessage(
        id: id,
        conversationId: conversationId,
        kind: kind,
        senderId: senderId,
        mine: mine,
        body: body,
        masked: masked,
        imageUrl: imageUrl,
        imageLargeUrl: imageLargeUrl,
        createdAt: createdAt,
      );
}

/// A page of a thread's history, as `ApiClient.getEnvelope` returns it.
class MessagePage {
  const MessagePage({
    required this.items,
    required this.hasMore,
    required this.nextBefore,
  });

  /// [body] is the whole envelope — `{data: [...], meta: {limit, hasMore,
  /// nextBefore}}` — not just `data`, because this list's `meta` shape is
  /// not the page `meta` that `ApiClient.getPage` reads. A missing `meta`
  /// (should not happen live) reads as the last page.
  factory MessagePage.fromEnvelope(Map<String, Object?> body) {
    final Map<String, Object?>? meta = readObject(body, 'meta');
    return MessagePage(
      items: readList(body, 'data', ChatMessage.fromJson),
      hasMore: meta == null ? false : readBool(meta, 'hasMore'),
      nextBefore: meta == null ? null : readStringOrNull(meta, 'nextBefore'),
    );
  }

  /// Oldest first.
  final List<ChatMessage> items;
  final bool hasMore;
  final String? nextBefore;
}
