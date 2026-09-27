import '../../../core/messaging/models/chat_message.dart';
import '../../../core/messaging/picked_image.dart';

/// Where a bubble stands on its way to the server (D8). The API has no
/// delivery or read states, so there is nothing past [sent].
enum EntryState { sent, sending, failed }

/// One bubble on screen 15: a message the server returned, or one of ours
/// still on its way.
///
/// A pending entry holds a synthetic [ChatMessage] — id `local-<n>`, `mine`,
/// created now. When the server answers, the entry is dropped by that local
/// id and the server's copy is stored under its own id, so a poll that
/// brought it first still leaves one bubble.
class ChatEntry {
  const ChatEntry({
    required this.message,
    this.state = EntryState.sent,
    this.localImage,
  });

  final ChatMessage message;
  final EntryState state;

  /// The photo being sent, shown from memory until the server's URL exists.
  final PickedImage? localImage;

  bool get isPending => state != EntryState.sent;

  ChatEntry copyWith({EntryState? state, ChatMessage? message}) => ChatEntry(
    message: message ?? this.message,
    state: state ?? this.state,
    localImage: localImage,
  );
}

/// One row of the thread: a day pill, a system pill or a bubble.
sealed class ThreadItem {
  const ThreadItem();

  /// Stable across rebuilds, for the list's keys.
  String get key;
}

class DayItem extends ThreadItem {
  const DayItem(this.day);

  /// Local midnight of the day.
  final DateTime day;

  @override
  String get key =>
      'day-${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

class SystemItem extends ThreadItem {
  const SystemItem(this.message);

  final ChatMessage message;

  @override
  String get key => message.id;
}

class BubbleItem extends ThreadItem {
  const BubbleItem(this.entry, {this.senderName});

  final ChatEntry entry;

  /// Shown above the first bubble of a run from one sender, in support and
  /// dispute chats only (decision 8).
  final String? senderName;

  @override
  String get key => entry.message.id;
}

/// The thread of screen 15, newest first — the order a reversed ListView
/// draws bottom-up.
///
/// [chronological] is oldest first, pending entries last. A day pill opens
/// each day; a sender label opens each run of received messages from one
/// sender in a group chat, and a new day, a system line or one of our own
/// messages ends the run.
List<ThreadItem> buildThread({
  required List<ChatEntry> chronological,
  required bool isGroup,
  required String? Function(String? senderId) senderName,
}) {
  final List<ThreadItem> items = <ThreadItem>[];
  DateTime? day;
  String? runSender;
  for (final ChatEntry entry in chronological) {
    final ChatMessage m = entry.message;
    final DateTime d = DateTime(
      m.createdAt.year,
      m.createdAt.month,
      m.createdAt.day,
    );
    if (day != d) {
      items.add(DayItem(d));
      day = d;
      runSender = null;
    }
    if (m.kind == MessageKind.system) {
      items.add(SystemItem(m));
      runSender = null;
      continue;
    }
    String? label;
    if (isGroup && !m.mine) {
      if (m.senderId != runSender) label = senderName(m.senderId);
      runSender = m.senderId;
    } else {
      runSender = null;
    }
    items.add(BubbleItem(entry, senderName: label));
  }
  return items.reversed.toList();
}
