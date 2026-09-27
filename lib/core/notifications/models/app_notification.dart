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
  const NotificationData({this.conversationId, this.bookingId, this.href});

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
      href: stringOrNull('href'),
    );
  }

  final String? conversationId;
  final String? bookingId;
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

  /// A conversation to open, or nowhere — the only target this build
  /// knows how to follow.
  NotificationTarget get target {
    final String? conversationId = data.conversationId;
    return conversationId == null
        ? const UnsupportedTarget()
        : ChatTarget(conversationId);
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
