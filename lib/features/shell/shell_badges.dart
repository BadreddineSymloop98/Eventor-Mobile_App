import 'package:flutter/foundation.dart';

/// The counts on the bottom nav — unread conversations on Messages.
///
/// Home's feed carries the number; this holds it so the nav, which outlives
/// every tab, can show it.
class ShellBadges extends ChangeNotifier {
  int _unreadConversations = 0;

  int get unreadConversations => _unreadConversations;

  void update({required int unreadConversations}) {
    if (_unreadConversations == unreadConversations) return;
    _unreadConversations = unreadConversations;
    notifyListeners();
  }

  /// Signed out: nothing is unread for nobody.
  void clear() => update(unreadConversations: 0);
}
