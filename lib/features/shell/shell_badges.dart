import 'package:flutter/foundation.dart';

import '../../core/notifications/notifications_repository.dart';

/// The counts the shell shows outside any one screen: unread conversations
/// on Messages, unread notifications on the bell.
///
/// Home's feed carries both numbers first; this holds them so the nav and the
/// bell, which outlive every tab, can show them, and [refresh] can bring them
/// forward again — on app resume — without Home being on screen to do it.
class ShellBadges extends ChangeNotifier {
  ShellBadges({this._notifications});

  final NotificationsRepository? _notifications;

  int _unreadConversations = 0;
  int _unreadNotifications = 0;

  int get unreadConversations => _unreadConversations;
  int get unreadNotifications => _unreadNotifications;

  /// Leaves whichever count is left out unchanged; notifies only when
  /// something actually moved.
  void update({int? unreadConversations, int? unreadNotifications}) {
    final int conversations = unreadConversations ?? _unreadConversations;
    final int notifications = unreadNotifications ?? _unreadNotifications;
    if (conversations == _unreadConversations &&
        notifications == _unreadNotifications) {
      return;
    }
    _unreadConversations = conversations;
    _unreadNotifications = notifications;
    notifyListeners();
  }

  /// Pulls both counts from `GET /app/me`. A badge is not worth an error, so
  /// a failure is swallowed rather than surfaced; a no-op without a
  /// repository to ask.
  Future<void> refresh() async {
    final NotificationsRepository? repository = _notifications;
    if (repository == null) return;
    try {
      final ({int notifications, int conversations}) counts =
          await repository.counts();
      update(
        unreadConversations: counts.conversations,
        unreadNotifications: counts.notifications,
      );
    } catch (_) {
      // A stale badge is fine; an error toast for it is not.
    }
  }

  /// Signed out: nothing is unread for nobody.
  void clear() => update(unreadConversations: 0, unreadNotifications: 0);
}
