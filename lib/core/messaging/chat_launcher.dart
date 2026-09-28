import '../base/base_view_model.dart';
import '../routing/app_routes.dart';
import 'messaging_repository.dart';
import 'models/conversation.dart';

/// "Message" on 12 and 13 (decision 2): opens the existing chat with a
/// provider when the list has one, else a draft.
mixin ChatLauncher on BaseViewModel {
  MessagingRepository get chatMessaging;

  bool _isOpeningChat = false;

  /// A lookup is running — the button shows its spinner.
  bool get isOpeningChat => _isOpeningChat;

  /// The route for a chat with [userId]; `null` while a lookup is already
  /// running, so a double tap opens one chat, not two.
  Future<String?> chatRouteWith({
    required String userId,
    required String name,
  }) async {
    if (_isOpeningChat) return null;
    _isOpeningChat = true;
    notifyListeners();
    try {
      final ConversationRow? row = await chatMessaging.findWith(userId);
      return row == null
          ? AppRoutes.chatDraftFor(userId: userId, name: name)
          : AppRoutes.chatFor(row.id);
    } catch (_) {
      // A failed lookup still lets the user write: the draft's first send
      // reaches the existing chat anyway, since there is one per pair.
      return AppRoutes.chatDraftFor(userId: userId, name: name);
    } finally {
      _isOpeningChat = false;
      notifyListeners();
    }
  }
}
