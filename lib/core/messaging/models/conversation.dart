import '../../catalog/models/json_read.dart';
import 'chat_message.dart';
import 'chat_person.dart';

/// A thread's shape — a one-to-one, a support conversation, or a dispute.
enum ConversationKind {
  direct,
  support,
  dispute;

  /// An unrecognised kind reads as [direct] — the ordinary, one-to-one
  /// treatment, so a thread never gains the group chrome by accident.
  static ConversationKind fromApi(String? value) => switch (value) {
        'support' => ConversationKind.support,
        'dispute' => ConversationKind.dispute,
        _ => ConversationKind.direct,
      };
}

/// The booking a thread is about, embedded in the row.
class ChatBooking {
  const ChatBooking({
    required this.id,
    required this.reference,
    required this.status,
    required this.eventDate,
    required this.title,
    required this.total,
  });

  factory ChatBooking.fromJson(Map<String, Object?> json) => ChatBooking(
        id: json['id']! as String,
        reference: readString(json, 'reference'),
        status: readString(json, 'status'),
        // A date-only field — `readDateOrNull` reads it as local midnight.
        eventDate: readDateOrNull(json, 'eventDate'),
        title: readString(json, 'title'),
        total: readString(json, 'total'),
      );

  final String id;
  final String reference;
  final String status;
  final DateTime? eventDate;
  final String title;

  /// `"57000.00"` — a decimal string, like the catalog's prices.
  final String total;
}

/// What a conversation row's preview line shows.
enum PreviewKind { text, photo, removed, none }

/// One row of the conversation list.
class ConversationRow {
  const ConversationRow({
    required this.id,
    required this.kind,
    required this.isClosed,
    required this.other,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.booking,
    required this.canWrite,
  });

  factory ConversationRow.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? other = readObject(json, 'other');
    final Map<String, Object?>? booking = readObject(json, 'booking');
    return ConversationRow(
      id: json['id']! as String,
      kind: ConversationKind.fromApi(json['kind'] as String?),
      isClosed: readString(json, 'status') == 'closed',
      // The other side can be null — a deleted account leaves the thread
      // behind with nobody to show.
      other: other == null ? null : ChatPerson.fromJson(other),
      lastMessage: readStringOrNull(json, 'lastMessage'),
      lastMessageAt: readDateOrNull(json, 'lastMessageAt'),
      unreadCount: readInt(json, 'unreadCount'),
      booking: booking == null ? null : ChatBooking.fromJson(booking),
      canWrite: readBool(json, 'canWrite'),
    );
  }

  final String id;
  final ConversationKind kind;

  /// `status == 'closed'`.
  final bool isClosed;
  final ChatPerson? other;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final ChatBooking? booking;
  final bool canWrite;

  /// Support and dispute threads show a sender label on every bubble and
  /// hide the one-to-one "⋯" menu — they are never a single other person.
  bool get isGroup => kind != ConversationKind.direct;

  /// A removed body wins over everything else, even a null
  /// [lastMessageAt] (c-weird). Otherwise: non-blank text is [text]; a
  /// blank message with a timestamp is an image-only message the API sent
  /// no preview text for ([photo], per D11); anything left is [none].
  PreviewKind get previewKind {
    final String? message = lastMessage;
    if (message == ChatMessage.removedBody) return PreviewKind.removed;
    if (message != null && message.isNotEmpty) return PreviewKind.text;
    if (lastMessageAt != null) return PreviewKind.photo;
    return PreviewKind.none;
  }
}

/// The full thread — the row plus what only the detail endpoint sends.
class ConversationDetail extends ConversationRow {
  const ConversationDetail({
    required super.id,
    required super.kind,
    required super.isClosed,
    required super.other,
    required super.lastMessage,
    required super.lastMessageAt,
    required super.unreadCount,
    required super.booking,
    required super.canWrite,
    required this.participants,
    required this.contactUnmasked,
    required this.disputeId,
    required this.closedReason,
    required this.createdAt,
  });

  factory ConversationDetail.fromJson(Map<String, Object?> json) {
    final ConversationRow row = ConversationRow.fromJson(json);
    return ConversationDetail(
      id: row.id,
      kind: row.kind,
      isClosed: row.isClosed,
      other: row.other,
      lastMessage: row.lastMessage,
      lastMessageAt: row.lastMessageAt,
      unreadCount: row.unreadCount,
      booking: row.booking,
      canWrite: row.canWrite,
      participants: readList(json, 'participants', ChatPerson.fromJson),
      contactUnmasked: readBool(json, 'contactUnmasked'),
      disputeId: readStringOrNull(json, 'disputeId'),
      closedReason: readStringOrNull(json, 'closedReason'),
      createdAt: readDate(json, 'createdAt'),
    );
  }

  final List<ChatPerson> participants;

  /// Whether the real phone numbers are visible in this thread yet.
  final bool contactUnmasked;
  final String? disputeId;

  /// Why a closed thread was closed — parsed for completeness, never shown.
  final String? closedReason;
  final DateTime createdAt;

  ChatPerson? participant(String? userId) {
    if (userId == null) return null;
    for (final ChatPerson person in participants) {
      if (person.id == userId) return person;
    }
    return null;
  }

  /// The first participant with the provider role — the middle name in
  /// "You, {provider} and Eventor support".
  ChatPerson? get groupProvider {
    for (final ChatPerson person in participants) {
      if (person.role == ChatRole.provider) return person;
    }
    return null;
  }
}
