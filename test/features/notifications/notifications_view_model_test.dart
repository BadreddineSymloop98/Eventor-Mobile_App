import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/notifications/models/app_notification.dart';
import 'package:eventor/features/notifications/view_model/notifications_view_model.dart';
import 'package:eventor/features/shell/shell_badges.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  late FakeNotificationsRepository notifications;
  late ShellBadges badges;

  setUp(() {
    notifications = FakeNotificationsRepository();
    badges = ShellBadges(notifications: notifications);
  });

  Future<NotificationsViewModel> build() async {
    final NotificationsViewModel viewModel = NotificationsViewModel(
      notifications: notifications,
      badges: badges,
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  List<String> ids(NotificationsViewModel viewModel) => <String>[
        for (final NotificationSection section in viewModel.sections)
          for (final AppNotification n in section.items) n.id,
      ];

  AppNotification byId(String id) =>
      notifications.items.firstWhere((AppNotification n) => n.id == id);

  group('swipe to delete (16)', () {
    test('a swipe hides the row at once and calls nothing yet', () async {
      final NotificationsViewModel viewModel = await build();
      final AppNotification n1 = byId('n-1');

      viewModel.removeLocally(n1);

      expect(ids(viewModel), isNot(contains('n-1')));
      expect(notifications.calls, isNot(contains('delete:n-1')));
    });

    test('Undo puts it back where it was', () async {
      final NotificationsViewModel viewModel = await build();
      final List<String> before = ids(viewModel);
      final AppNotification n2 = byId('n-2');

      final int index = viewModel.removeLocally(n2);
      viewModel.undoRemove(n2, index);

      expect(ids(viewModel), before);
    });

    test('once the toast is gone, deletes it and refreshes the bell', () async {
      final NotificationsViewModel viewModel = await build();
      final AppNotification n1 = byId('n-1');
      final int index = viewModel.removeLocally(n1);

      expect(await viewModel.commitRemove(n1, index), isNull);
      await flushAsync();

      expect(notifications.calls, contains('delete:n-1'));
      // n-1 was unread: the badge is recounted.
      expect(notifications.calls.last, 'counts');
    });

    test('a refused delete brings the row back', () async {
      final NotificationsViewModel viewModel = await build();
      final List<String> before = ids(viewModel);
      final AppNotification n2 = byId('n-2');
      final int index = viewModel.removeLocally(n2);
      notifications.failNext = const NetworkFailure();

      expect(await viewModel.commitRemove(n2, index), isA<NetworkFailure>());

      expect(ids(viewModel), before);
    });
  });
}
