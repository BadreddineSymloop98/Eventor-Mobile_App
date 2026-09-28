import '../../catalog/models/json_read.dart';

/// Which section of the notification list a row falls under.
enum NotificationGroup {
  today,
  thisWeek,
  earlier;

  /// An unrecognised group (a future `someday` bucket, say) reads as
  /// [earlier] — the list's catch-all section, never the two that imply
  /// something recent.
  static NotificationGroup fromApi(String? value) => switch (value) {
        'today' => NotificationGroup.today,
        'this_week' => NotificationGroup.thisWeek,
        _ => NotificationGroup.earlier,
      };
}

/// The notification's `data` payload — whatever it points at, read
/// defensively because its shape varies by `type` and a future `type` this
/// build does not know sends fields it cannot predict.
class NotificationData {
  const NotificationData({
    this.conversationId,
    this.bookingId,
    this.disputeId,
    this.requestId,
    this.reviewId,
    this.reportId,
    this.href,
  });

  /// `null` (no `data` field on the notification) reads the same as an
  /// empty object: every field `null`. A value under one of these keys
  /// that is not a string (n-4's numeric `conversationId`) is ignored
  /// rather than thrown on — a field the app cannot use is not a field
  /// worth crashing the list over.
  factory NotificationData.fromJson(Map<String, Object?>? json) {
    if (json == null) return const NotificationData();
    String? stringOrNull(String key) {
      final Object? value = json[key];
      return value is String ? value : null;
    }

    return NotificationData(
      conversationId: stringOrNull('conversationId'),
      bookingId: stringOrNull('bookingId'),
      disputeId: stringOrNull('disputeId'),
      requestId: stringOrNull('requestId'),
      reviewId: stringOrNull('reviewId'),
      reportId: stringOrNull('reportId'),
      href: stringOrNull('href'),
    );
  }

  // Typed ids since 2026-09-27, as the notification's type requires. The
  // API asks for these to be followed rather than [href] parsed.
  final String? conversationId;
  final String? bookingId;
  final String? disputeId;
  final String? requestId;
  final String? reviewId;
  final String? reportId;

  /// A web path relative to the public site, when there is one. Never
  /// parsed — the ids above say where to go.
  final String? href;
}

/// Where tapping a notification goes.
sealed class NotificationTarget {
  const NotificationTarget();
}

/// Opens the thread named by [conversationId].
class ChatTarget extends NotificationTarget {
  const ChatTarget(this.conversationId);

  final String conversationId;
}

/// A booking moved — B4 for a client.
class BookingTarget extends NotificationTarget {
  const BookingTarget(this.bookingId);

  final String bookingId;
}

/// A provider's verification was decided — their home says how it went.
class VerificationTarget extends NotificationTarget {
  const VerificationTarget();
}

/// Nothing in the app to open yet — the row is still readable, just not
/// tappable.
class UnsupportedTarget extends NotificationTarget {
  const UnsupportedTarget();
}

/// One row of the notification list.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.group,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, Object?> json) =>
      AppNotification(
        id: json['id']! as String,
        type: readString(json, 'type'),
        title: readString(json, 'title'),
        body: readString(json, 'body'),
        data: NotificationData.fromJson(readObject(json, 'data')),
        group: NotificationGroup.fromApi(json['group'] as String?),
        read: readBool(json, 'read'),
        createdAt: readDate(json, 'createdAt'),
      );

  final String id;

  /// `"booking.accepted"` — `area.event`. Drives [NotificationTarget] and
  /// `notificationIcon`.
  final String type;
  final String title;
  final String body;
  final NotificationData data;
  final NotificationGroup group;
  final bool read;
  final DateTime createdAt;

  /// Where this build can take the user: a conversation (messages and
  /// disputes carry one), the provider home for a verification decision, or
  /// nowhere yet.
  NotificationTarget get target {
    final String? conversationId = data.conversationId;
    if (conversationId != null) return ChatTarget(conversationId);
    if (type.startsWith('verification.')) return const VerificationTarget();
    final String? bookingId = data.bookingId;
    if (bookingId != null && type.startsWith('booking.')) {
      return BookingTarget(bookingId);
    }
    return const UnsupportedTarget();
  }

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        group: group,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}
