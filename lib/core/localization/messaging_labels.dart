import '../../l10n/app_localizations.dart';
import '../formatting/chat_time_format.dart';
import '../messaging/models/conversation.dart';

/// Conversations in words — shared by the 14 rows and the 15 top bar.
extension MessagingLabels on AppLocalizations {
  /// Who the conversation is with. Support and dispute chats are named by
  /// the app, not by the person Eventor put on them (decision 7).
  String conversationTitle(ConversationRow row) {
    final String? reference = row.booking?.reference;
    return switch (row.kind) {
      ConversationKind.support => chatSupport,
      ConversationKind.dispute =>
        reference == null || reference.isEmpty
            ? chatDisputeNoRef
            : chatDispute(ltrIsolate(reference)),
      ConversationKind.direct => row.other?.name ?? chatDeletedAccount,
    };
  }
}
