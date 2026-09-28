import 'package:eventor/core/notifications/models/app_notification.dart';
import 'package:eventor/core/notifications/notification_icon.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  final List<AppNotification> notifications = fixtureList(
    'notifications_page.json',
    dir: 'messaging',
  ).map(AppNotification.fromJson).toList();

  AppNotification byId(String id) =>
      notifications.firstWhere((AppNotification n) => n.id == id);

  group('AppNotification', () {
    test('n-1 has nowhere to go — no conversationId in its data', () {
      // A booking notification opens the booking (section 9).
      expect(byId('n-1').target, isA<BookingTarget>());
      expect((byId('n-1').target as BookingTarget).bookingId, 'b-1');
    });

    test('n-2 opens its conversation', () {
      final NotificationTarget target = byId('n-2').target;

      expect(target, isA<ChatTarget>());
      expect((target as ChatTarget).conversationId, 'c-yasmine');
    });

    test('n-3 has a null data object, so every field reads null', () {
      final AppNotification n3 = byId('n-3');

      expect(n3.data.conversationId, isNull);
      expect(n3.data.bookingId, isNull);
      expect(n3.data.href, isNull);
    });

    test('n-4 ignores its numeric conversationId', () {
      final AppNotification n4 = byId('n-4');

      expect(n4.data.conversationId, isNull);
      expect(n4.target, isA<UnsupportedTarget>());
    });

    test('n-4 groups as earlier, n-3 as thisWeek', () {
      expect(byId('n-4').group, NotificationGroup.earlier);
      expect(byId('n-3').group, NotificationGroup.thisWeek);
    });

    test('copyWith(read: true) keeps every other field', () {
      final AppNotification original = byId('n-1');
      final AppNotification updated = original.copyWith(read: true);

      expect(updated.read, true);
      expect(updated.id, original.id);
      expect(updated.type, original.type);
      expect(updated.title, original.title);
      expect(updated.body, original.body);
      expect(updated.data, original.data);
      expect(updated.group, original.group);
      expect(updated.createdAt, original.createdAt);
    });
  });

  group('notificationIcon', () {
    test('maps every known type, in the order the brief specifies', () {
      expect(notificationIcon('booking.accepted'), AppIcons.check);
      expect(notificationIcon('booking.declined'), AppIcons.close);
      expect(notificationIcon('booking.cancelled'), AppIcons.close);
      expect(notificationIcon('message.new'), AppIcons.message);
      expect(notificationIcon('dispute.update'), AppIcons.message);
      expect(notificationIcon('booking.reminder'), AppIcons.calendar);
      expect(notificationIcon('booking.reschedule_proposed'), AppIcons.calendar);
      expect(notificationIcon('booking.waiting'), AppIcons.calendar);
      expect(notificationIcon('review.request'), AppIcons.starFilled);
      expect(notificationIcon('review.reply'), AppIcons.starFilled);
      expect(notificationIcon('booking.created'), AppIcons.bell);
      expect(notificationIcon(''), AppIcons.bell);
      expect(notificationIcon('weird'), AppIcons.bell);
    });
  });

  group('2026-09-27 types', () {
    AppNotification withType(String type, Map<String, Object?> data) =>
        AppNotification.fromJson(<String, Object?>{
          ...fixtureList('notifications_page.json', dir: 'messaging').first,
          'type': type,
          'data': data,
        });

    test('verification notifications open the provider home', () {
      expect(
        withType('verification.approved', <String, Object?>{}).target,
        isA<VerificationTarget>(),
      );
      expect(
        withType('verification.rejected', <String, Object?>{}).target,
        isA<VerificationTarget>(),
      );
    });

    test('a dispute message opens its conversation and keeps its ids', () {
      final AppNotification n = withType('dispute.message', <String, Object?>{
        'disputeId': 'd-2041',
        'conversationId': 'c-dispute',
      });

      expect(n.data.disputeId, 'd-2041');
      expect((n.target as ChatTarget).conversationId, 'c-dispute');
    });

    test('the new types get their icons', () {
      expect(notificationIcon('verification.approved'), AppIcons.check);
      expect(notificationIcon('verification.rejected'), AppIcons.close);
      expect(notificationIcon('academic_request.cancelled'), AppIcons.close);
      expect(notificationIcon('report.resolved'), AppIcons.alertTriangle);
    });
  });
}
