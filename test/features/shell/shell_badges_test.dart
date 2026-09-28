import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/features/shell/shell_badges.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  group('ShellBadges update', () {
    test('with only one field keeps the other', () {
      final ShellBadges badges = ShellBadges()
        ..update(unreadConversations: 3, unreadNotifications: 5);

      badges.update(unreadConversations: 7);

      expect(badges.unreadConversations, 7);
      expect(badges.unreadNotifications, 5);
    });

    test('does not notify when nothing changed', () {
      final ShellBadges badges = ShellBadges()
        ..update(unreadConversations: 3, unreadNotifications: 5);
      int notified = 0;
      badges.addListener(() => notified++);

      badges.update(unreadConversations: 3, unreadNotifications: 5);

      expect(notified, 0);
    });
  });

  group('ShellBadges refresh', () {
    test('applies counts() from the repository', () async {
      final FakeNotificationsRepository repository =
          FakeNotificationsRepository()
            ..countsResult = (notifications: 4, conversations: 2);
      final ShellBadges badges = ShellBadges(notifications: repository);

      await badges.refresh();

      expect(badges.unreadNotifications, 4);
      expect(badges.unreadConversations, 2);
      expect(repository.calls, contains('counts'));
    });

    test('a throwing counts() leaves the values and does not throw', () async {
      final FakeNotificationsRepository repository =
          FakeNotificationsRepository()..failNext = const NetworkFailure();
      final ShellBadges badges = ShellBadges(notifications: repository)
        ..update(unreadConversations: 1, unreadNotifications: 1);

      await badges.refresh();

      expect(badges.unreadConversations, 1);
      expect(badges.unreadNotifications, 1);
    });

    test('is a no-op without a repository', () async {
      final ShellBadges badges = ShellBadges()
        ..update(unreadConversations: 1, unreadNotifications: 1);

      await badges.refresh();

      expect(badges.unreadConversations, 1);
      expect(badges.unreadNotifications, 1);
    });
  });

  group('ShellBadges clear', () {
    test('zeroes both', () {
      final ShellBadges badges = ShellBadges()
        ..update(unreadConversations: 3, unreadNotifications: 5);

      badges.clear();

      expect(badges.unreadConversations, 0);
      expect(badges.unreadNotifications, 0);
    });
  });
}
