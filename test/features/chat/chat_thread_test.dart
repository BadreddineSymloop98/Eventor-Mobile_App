import 'package:eventor/core/messaging/models/chat_message.dart';
import 'package:eventor/features/chat/view_model/chat_thread.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_test_support.dart';

void main() {
  String? names(String? id) => switch (id) {
    'p-lumiere' => 'Studio Lumière',
    'u-support' => 'Eventor support',
    _ => null,
  };

  List<ChatEntry> entries(List<ChatMessage> messages) => <ChatEntry>[
    for (final ChatMessage m in messages) ChatEntry(message: m),
  ];

  test('lays two days out newest first, each closed by its day pill', () {
    final List<ThreadItem> thread = buildThread(
      chronological: entries(<ChatMessage>[
        message('a1', at: DateTime(2026, 3, 11, 9)),
        message('b1', at: DateTime(2026, 3, 12, 9)),
        message('b2', at: DateTime(2026, 3, 12, 10), mine: true),
      ]),
      isGroup: false,
      senderName: names,
    );

    expect(
      <String>[for (final ThreadItem item in thread) item.key],
      <String>['b2', 'b1', 'day-2026-03-12', 'a1', 'day-2026-03-11'],
    );
  });

  test('labels each run of one sender in a group, never our own', () {
    final DateTime day = DateTime(2026, 3, 12);
    final List<ThreadItem> thread = buildThread(
      chronological: entries(<ChatMessage>[
        message('m1', at: day.add(const Duration(hours: 1))),
        message('m2', at: day.add(const Duration(hours: 2))),
        message(
          'm3',
          at: day.add(const Duration(hours: 3)),
          senderId: 'u-support',
        ),
        message('m4', at: day.add(const Duration(hours: 4))),
        message('m5', at: day.add(const Duration(hours: 5)), mine: true),
      ]),
      isGroup: true,
      senderName: names,
    );

    final Map<String, String?> labels = <String, String?>{
      for (final BubbleItem item in thread.whereType<BubbleItem>())
        item.entry.message.id: item.senderName,
    };
    expect(labels, <String, String?>{
      'm5': null,
      'm4': 'Studio Lumière',
      'm3': 'Eventor support',
      'm2': null,
      'm1': 'Studio Lumière',
    });
  });

  test('a system line ends the run', () {
    final DateTime day = DateTime(2026, 3, 12);
    final List<ThreadItem> thread = buildThread(
      chronological: entries(<ChatMessage>[
        message('m1', at: day.add(const Duration(hours: 1))),
        message(
          's1',
          at: day.add(const Duration(hours: 2)),
          kind: MessageKind.system,
          senderId: null,
        ),
        message('m2', at: day.add(const Duration(hours: 3))),
      ]),
      isGroup: true,
      senderName: names,
    );

    expect(thread.whereType<SystemItem>().single.message.id, 's1');
    expect(
      thread.whereType<BubbleItem>().every(
        (BubbleItem item) => item.senderName == 'Studio Lumière',
      ),
      isTrue,
    );
  });

  test('outside a group nobody is labelled', () {
    final List<ThreadItem> thread = buildThread(
      chronological: entries(<ChatMessage>[
        message('m1', at: DateTime(2026, 3, 12, 9)),
      ]),
      isGroup: false,
      senderName: names,
    );

    expect(thread.whereType<BubbleItem>().single.senderName, isNull);
  });

  test('a pending entry sits after everything the server returned', () {
    final List<ThreadItem> thread = buildThread(
      chronological: <ChatEntry>[
        ChatEntry(message: message('m1', at: DateTime(2026, 3, 12, 9))),
        ChatEntry(
          message: message(
            'local-0',
            at: DateTime(2026, 3, 12, 10),
            mine: true,
          ),
          state: EntryState.sending,
        ),
      ],
      isGroup: false,
      senderName: names,
    );

    expect(thread.first.key, 'local-0');
    expect((thread.first as BubbleItem).entry.isPending, isTrue);
  });
}
