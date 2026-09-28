import 'dart:typed_data';

import 'package:eventor/core/messaging/conversation_filter.dart';
import 'package:eventor/core/messaging/models/chat_message.dart';
import 'package:eventor/core/messaging/models/chat_person.dart';
import 'package:eventor/core/messaging/models/conversation.dart';
import 'package:eventor/core/messaging/models/report_reason.dart';
import 'package:eventor/core/messaging/picked_image.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  group('ConversationRow', () {
    final List<ConversationRow> rows = fixtureList(
      'conversations_page.json',
      dir: 'messaging',
    ).map(ConversationRow.fromJson).toList();

    test('every row parses', () {
      expect(rows.length, 5);
    });

    test('c-weird falls back to direct/client, is closed, and removed', () {
      final ConversationRow row = rows.firstWhere((ConversationRow r) => r.id == 'c-weird');

      expect(row.kind, ConversationKind.direct);
      expect(row.other?.role, ChatRole.client);
      expect(row.isClosed, true);
      expect(row.previewKind, PreviewKind.removed);
    });

    test('c-deleted has no other side and an image-only preview', () {
      final ConversationRow row = rows.firstWhere((ConversationRow r) => r.id == 'c-deleted');

      expect(row.other, isNull);
      expect(row.previewKind, PreviewKind.photo);
    });

    test('c-lumiere parses its booking and is not a group', () {
      final ConversationRow row = rows.firstWhere((ConversationRow r) => r.id == 'c-lumiere');

      expect(row.previewKind, PreviewKind.text);
      expect(row.booking?.eventDate, DateTime(2026, 3, 14));
      expect(row.isGroup, false);
    });

    test('c-dispute and c-support are groups', () {
      final ConversationRow dispute = rows.firstWhere((ConversationRow r) => r.id == 'c-dispute');
      final ConversationRow support = rows.firstWhere((ConversationRow r) => r.id == 'c-support');

      expect(dispute.isGroup, true);
      expect(support.isGroup, true);
    });

    test('a blank message with no timestamp gives none', () {
      // Built directly, not from a fixture — none of the five rows land on
      // this combination, and previewKind's last branch still needs it
      // exercised.
      const ConversationRow row = ConversationRow(
        id: 'c-synthetic',
        kind: ConversationKind.direct,
        isClosed: false,
        other: null,
        lastMessage: '',
        lastMessageAt: null,
        unreadCount: 0,
        booking: null,
        canWrite: true,
      );

      expect(row.previewKind, PreviewKind.none);
    });
  });

  group('ConversationDetail', () {
    test('a direct thread resolves its other participant', () {
      final ConversationDetail detail = ConversationDetail.fromJson(
        fixtureData('conversation_detail.json', dir: 'messaging'),
      );

      expect(detail.participant('p-lumiere')?.name, 'Studio Lumière');
    });

    test('a dispute names its group provider and dispute id', () {
      final ConversationDetail dispute = ConversationDetail.fromJson(
        fixtureData('conversation_dispute.json', dir: 'messaging'),
      );

      expect(dispute.groupProvider?.name, 'Studio Lumière');
      expect(dispute.disputeId, 'd-2041');
    });
  });

  group('MessagePage', () {
    final Map<String, Object?> envelope = fixture(
      'messages_page.json',
      dir: 'messaging',
    );
    final MessagePage page = MessagePage.fromEnvelope(envelope);

    test('reads all items oldest first, with the paging meta', () {
      expect(page.items.length, 6);
      expect(page.items.map((ChatMessage m) => m.id).toList(), <String>[
        'm-1', 'm-2', 'm-3', 'm-4', 'm-5', 'm-6',
      ]);
      expect(page.hasMore, true);
      expect(page.nextBefore, 'm-1');
    });

    test('a missing meta reads as the last page', () {
      final MessagePage noMeta = MessagePage.fromEnvelope(
        <String, Object?>{'data': envelope['data']},
      );

      expect(noMeta.hasMore, false);
      expect(noMeta.nextBefore, isNull);
    });

    test('m-5 is removed and carries no image', () {
      final ChatMessage m5 = page.items.firstWhere((ChatMessage m) => m.id == 'm-5');

      expect(m5.isRemoved, true);
      expect(m5.hasImage, false);
    });

    test('m-4 has an image', () {
      final ChatMessage m4 = page.items.firstWhere((ChatMessage m) => m.id == 'm-4');

      expect(m4.hasImage, true);
    });

    test('m-3 is masked', () {
      final ChatMessage m3 = page.items.firstWhere((ChatMessage m) => m.id == 'm-3');

      expect(m3.masked, true);
    });

    test('m-6 falls back to text for an unknown kind', () {
      final ChatMessage m6 = page.items.firstWhere((ChatMessage m) => m.id == 'm-6');

      expect(m6.kind, MessageKind.text);
    });

    test('m-1 has no sender', () {
      final ChatMessage m1 = page.items.firstWhere((ChatMessage m) => m.id == 'm-1');

      expect(m1.senderId, isNull);
    });

    test('withImages replaces only the two URLs', () {
      final ChatMessage original = page.items.firstWhere((ChatMessage m) => m.id == 'm-4');
      final ChatMessage refreshed = original.withImages(
        imageUrl: 'https://files.example/fresh.jpg?exp=2',
        imageLargeUrl: 'https://files.example/fresh-large.jpg?exp=2',
      );

      expect(refreshed.imageUrl, 'https://files.example/fresh.jpg?exp=2');
      expect(refreshed.imageLargeUrl, 'https://files.example/fresh-large.jpg?exp=2');
      expect(refreshed.id, original.id);
      expect(refreshed.body, original.body);
      expect(refreshed.kind, original.kind);
      expect(refreshed.mine, original.mine);
      expect(refreshed.masked, original.masked);
      expect(refreshed.createdAt, original.createdAt);
    });
  });

  group('PickedImage.validate', () {
    const int maxMb = 10;
    const List<String> types = <String>['jpeg', 'png', 'webp', 'heic'];

    Uint8List bytesOfLength(int length) => Uint8List(length);

    test('jpg normalises to jpeg and passes', () {
      final PickedImage image = PickedImage(
        name: 'a.jpg',
        bytes: bytesOfLength(10),
        extension: 'jpg',
      );

      expect(image.validate(maxMb: maxMb, types: types), isNull);
    });

    test('an upper-case extension passes', () {
      final PickedImage image = PickedImage(
        name: 'a.PNG',
        bytes: bytesOfLength(10),
        extension: 'PNG',
      );

      expect(image.validate(maxMb: maxMb, types: types), isNull);
    });

    test('gif is the wrong type', () {
      final PickedImage image = PickedImage(
        name: 'a.gif',
        bytes: bytesOfLength(10),
        extension: 'gif',
      );

      expect(image.validate(maxMb: maxMb, types: types), ImageProblem.wrongType);
    });

    test('an empty extension is the wrong type', () {
      final PickedImage image = PickedImage(
        name: 'a',
        bytes: bytesOfLength(10),
        extension: '',
      );

      expect(image.validate(maxMb: maxMb, types: types), ImageProblem.wrongType);
    });

    test('exactly the byte limit passes', () {
      final PickedImage image = PickedImage(
        name: 'a.jpeg',
        bytes: bytesOfLength(10 * 1024 * 1024),
        extension: 'jpeg',
      );

      expect(image.validate(maxMb: maxMb, types: types), isNull);
    });

    test('one byte over the limit is too large', () {
      final PickedImage image = PickedImage(
        name: 'a.jpeg',
        bytes: bytesOfLength(10 * 1024 * 1024 + 1),
        extension: 'jpeg',
      );

      expect(image.validate(maxMb: maxMb, types: types), ImageProblem.tooLarge);
    });

    test('a wrong type is reported before the size', () {
      final PickedImage image = PickedImage(
        name: 'a.gif',
        bytes: bytesOfLength(50 * 1024 * 1024),
        extension: 'gif',
      );

      expect(image.validate(maxMb: maxMb, types: types), ImageProblem.wrongType);
    });
  });

  // Plain data enums — exercised so a future rename of an `apiValue` is
  // caught here rather than silently breaking a filter chip or a report
  // request.
  group('ReportReason and ConversationFilter', () {
    test('report reasons carry their API value', () {
      expect(ReportReason.contactOutside.apiValue, 'contact_outside');
      expect(ReportReason.other.apiValue, 'other');
    });

    test('conversation filters carry their API value', () {
      expect(ConversationFilter.unread.apiValue, 'unread');
      expect(ConversationFilter.booking.apiValue, 'booking');
    });
  });

  group('2026-09-27 shapes', () {
    Map<String, Object?> lumiere() => Map<String, Object?>.of(
          fixtureList('conversations_page.json', dir: 'messaging')
              .firstWhere((Map<String, Object?> r) => r['id'] == 'c-lumiere'),
        );

    test('lastMessage as an object says who sent it', () {
      final ConversationRow row = ConversationRow.fromJson(
        lumiere()
          ..['lastMessage'] = <String, Object?>{
            'body': 'See you Saturday',
            'kind': 'text',
            'mine': true,
          },
      );

      expect(row.lastMessage, 'See you Saturday');
      expect(row.lastMessageMine, isTrue);
      expect(row.previewKind, PreviewKind.text);
    });

    test('a photo without a caption previews as a photo', () {
      final ConversationRow row = ConversationRow.fromJson(
        lumiere()
          ..['lastMessage'] = <String, Object?>{
            'body': '',
            'kind': 'attachment',
            'mine': false,
          },
      );

      expect(row.lastMessageKind, MessageKind.attachment);
      expect(row.previewKind, PreviewKind.photo);
    });

    test('the old plain-text lastMessage still reads', () {
      final ConversationRow row =
          ConversationRow.fromJson(lumiere()..['lastMessage'] = 'Hello');

      expect(row.lastMessage, 'Hello');
      expect(row.lastMessageMine, isFalse);
      expect(row.lastMessageKind, isNull);
    });

    test('a message flagged removed is removed, whatever its body', () {
      final ChatMessage message = ChatMessage.fromJson(<String, Object?>{
        'id': 'm-x',
        'conversationId': 'c-lumiere',
        'kind': 'text',
        'senderId': 'p-lumiere',
        'mine': false,
        'body': 'Retiré par Eventor',
        'masked': false,
        'removed': true,
        'createdAt': '2026-03-12T09:30:00.000Z',
      });

      expect(message.isRemoved, isTrue);
    });

    test('closedByModeration tells an Eventor close from a plain one', () {
      final Map<String, Object?> json =
          fixtureData('conversation_detail.json', dir: 'messaging');

      expect(ConversationDetail.fromJson(json).closedByModeration, isFalse);
      expect(
        ConversationDetail.fromJson(
          Map<String, Object?>.of(json)..['closedByModeration'] = true,
        ).closedByModeration,
        isTrue,
      );
    });
  });
}
