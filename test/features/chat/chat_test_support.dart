import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/messaging/models/chat_message.dart';
import 'package:eventor/core/messaging/models/conversation.dart';
import 'package:eventor/features/chat/view_model/chat_view_model.dart';
import 'package:eventor/features/shell/shell_badges.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';

/// Everything a [ChatViewModel] test needs, on fakes.
class ChatHarness {
  ChatHarness({FakeMessagingRepository? messaging})
    : messaging = messaging ?? FakeMessagingRepository() {
    // The fixture provider has no reply time yet; D4 needs one to show.
    catalog.providerDetail = ProviderDetail.fromJson(<String, Object?>{
      ...fixtureData('provider_detail.json'),
      'replyTime': '2 h',
    });
  }

  final FakeMessagingRepository messaging;
  final FakeCatalogRepository catalog = FakeCatalogRepository();
  final FakeNotificationsRepository notifications =
      FakeNotificationsRepository();
  final ManualChatUpdates updates = ManualChatUpdates();
  late final ShellBadges badges = ShellBadges(notifications: notifications);

  /// A chat on [conversationId], a draft, or a hand-over — disposed after
  /// the test unless [autoDispose] is false.
  ChatViewModel build({
    String? conversationId = 'c-lumiere',
    ChatDraftPeer? draft,
    ChatOpening? opening,
    AppConfig config = const AppConfig(),
    bool autoDispose = true,
  }) {
    final ChatViewModel viewModel = ChatViewModel(
      messaging: messaging,
      catalog: catalog,
      badges: badges,
      config: config,
      updates: updates,
      conversationId: draft == null ? conversationId : null,
      draft: draft,
      opening: opening,
      now: () => DateTime(2026, 3, 12, 16),
    );
    if (autoDispose) addTearDown(viewModel.dispose);
    return viewModel;
  }

  /// Calls to the messaging fake that start with [prefix].
  int count(String prefix) =>
      messaging.calls.where((String c) => c.startsWith(prefix)).length;
}

/// The c-lumiere detail with some of its fields replaced.
ConversationDetail detailWith(Map<String, Object?> overrides) =>
    ConversationDetail.fromJson(<String, Object?>{
      ...fixtureData('conversation_detail.json', dir: 'messaging'),
      ...overrides,
    });

/// A plain text message in c-lumiere.
ChatMessage message(
  String id, {
  required DateTime at,
  bool mine = false,
  String? senderId = 'p-lumiere',
  MessageKind kind = MessageKind.text,
  String body = 'hello',
  String conversationId = 'c-lumiere',
  String? imageUrl,
}) => ChatMessage(
  id: id,
  conversationId: conversationId,
  kind: kind,
  senderId: mine ? 'u-me' : senderId,
  mine: mine,
  body: body,
  masked: false,
  imageUrl: imageUrl,
  imageLargeUrl: imageUrl,
  createdAt: at,
);

/// The bubbles of [viewModel]'s thread, newest first.
List<BubbleItem> bubbles(ChatViewModel viewModel) =>
    viewModel.thread.whereType<BubbleItem>().toList();

/// The ids of [viewModel]'s bubbles, newest first.
List<String> bubbleIds(ChatViewModel viewModel) => <String>[
  for (final BubbleItem item in bubbles(viewModel)) item.entry.message.id,
];
