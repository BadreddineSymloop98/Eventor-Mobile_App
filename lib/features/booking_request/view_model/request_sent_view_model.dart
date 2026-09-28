import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/bookings_repository.dart';
import '../../../core/messaging/chat_launcher.dart';
import '../../../core/messaging/messaging_repository.dart';
import '../../../core/routing/app_routes.dart';

/// B2 Request sent: the booking just made, and the way to it or to the
/// provider's chat.
class RequestSentViewModel extends BaseViewModel with ChatLauncher {
  RequestSentViewModel({
    required this.args,
    required this._messaging,
    required this.replyDeadlineHours,
  });

  final RequestSentArgs args;
  final MessagingRepository _messaging;

  /// How long a provider has to answer, from the server's config.
  final int replyDeadlineHours;

  @override
  MessagingRepository get chatMessaging => _messaging;

  BookingDetail get booking => args.booking;

  /// The chat the booking opened with the provider, else the lookup-or-draft
  /// every Message button uses.
  Future<String?> chatRoute() async {
    final String? conversation = booking.conversationId;
    if (conversation != null) return AppRoutes.chatFor(conversation);
    final String? providerId = booking.provider?.id;
    if (providerId == null) return null;
    return chatRouteWith(userId: providerId, name: booking.card.providerName);
  }
}
