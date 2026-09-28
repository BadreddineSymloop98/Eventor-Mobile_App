import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/models/booking_card.dart';
import '../../../core/bookings/models/booking_detail.dart';
import '../../../core/errors/failure.dart';
import '../../../core/messaging/chat_launcher.dart';
import '../../../core/messaging/messaging_repository.dart';
import '../../../core/provider/models/provider_booking.dart' as provider_booking show replyHoursLeft;
import '../../../core/provider/provider_repository.dart';
import '../../../core/routing/app_routes.dart';

/// The answer running on P2 — its button shows the spinner, the others wait.
enum ProviderBookingBusy { accept, acceptProposal, rejectProposal, withdrawProposal }

/// P2 Booking detail, in every state (P2 pending, P2a accepted, P2b event
/// passed, P2c declined, P2d cancelled, P2e completed), and what is done
/// from it: Accept, Decline (P3), Cancel, the client's proposal (P4a), the
/// provider's own proposal, the problem report and "Message client".
///
/// Every write answers with the booking as it now stands, which replaces
/// what is on screen — P2c and P2d appear right after declining or
/// cancelling. A refusal that means the booking moved meanwhile reloads it.
class ProviderBookingViewModel extends BaseViewModel with ChatLauncher {
  ProviderBookingViewModel({
    required this.id,
    required this._provider,
    required this._messaging,
    required this.replyDeadlineHours,
    this._now = DateTime.now,
  }) {
    load();
  }

  final String id;
  final ProviderRepository _provider;
  final MessagingRepository _messaging;
  final DateTime Function() _now;

  /// How long a request waits for an answer, from the server's config.
  final int replyDeadlineHours;

  @override
  MessagingRepository get chatMessaging => _messaging;

  ProviderBooking? _booking;
  bool _isLoading = false;
  bool _isGone = false;
  ProviderBookingBusy? _busy;

  ProviderBooking? get booking => _booking;
  bool get isFirstLoad => _booking == null && (_isLoading || !hasError) && !_isGone;
  bool get isGone => _isGone;

  /// The answer on its way, if any.
  ProviderBookingBusy? get busy => _busy;

  DateTime get now => _now();

  /// The event day is behind us — P2b.
  bool get eventPassed {
    final ProviderBooking? booking = _booking;
    if (booking == null) return false;
    final DateTime today = DateTime(now.year, now.month, now.day);
    return booking.card.eventDate.isBefore(today);
  }

  /// "Reply within 47 h" on a request; `null` otherwise.
  int? get replyHoursLeft {
    final ProviderBooking? booking = _booking;
    if (booking == null || booking.status != 'pending') return null;
    return provider_booking.replyHoursLeft(
      booking.card,
      deadlineHours: replyDeadlineHours,
      now: now,
    );
  }

  /// P2 / P2c say "Request"; once accepted it is a "Booking" for good.
  bool get isRequest {
    final ProviderBooking? booking = _booking;
    return booking == null || !booking.wasAccepted;
  }

  Future<void> load() async {
    _isLoading = true;
    _isGone = false;
    notifyListeners();
    final ProviderBooking? loaded = await runGuarded(() => _provider.booking(id));
    final Failure? failure = this.failure;
    if (loaded != null) {
      _booking = loaded;
    } else if (_isGoneFailure(failure)) {
      _isGone = true;
      clearFailure();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Pull to refresh, and the reload after P4 / P5. What is on screen stays
  /// when it fails.
  Future<Failure?> refresh() async {
    try {
      _booking = await _provider.booking(id);
      clearFailure();
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      if (_isGoneFailure(failure)) {
        _isGone = true;
        notifyListeners();
      }
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
  }

  /// What P4 or P5 came back with.
  void replace(ProviderBooking booking) {
    _booking = booking;
    notifyListeners();
  }

  /// "Accept request", in one tap.
  Future<Failure?> accept() =>
      _answer(ProviderBookingBusy.accept, () => _provider.accept(id));

  /// P3's confirm — the sheet waits on it.
  Future<Failure?> decline(String reason) =>
      _write(() => _provider.decline(id, reason: reason.trim()));

  /// The cancel sheet's confirm.
  Future<Failure?> cancel(String reason) =>
      _write(() => _provider.cancel(id, reason: reason.trim()));

  /// P4a "Accept {date}".
  Future<Failure?> acceptProposal(Reschedule proposal) => _answer(
        ProviderBookingBusy.acceptProposal,
        () => _provider.acceptReschedule(id, proposal.id),
      );

  /// P4a "Decline" — the booking keeps its date.
  Future<Failure?> rejectProposal(Reschedule proposal) => _answer(
        ProviderBookingBusy.rejectProposal,
        () => _provider.rejectReschedule(id, proposal.id),
      );

  /// Takes back the provider's own proposal.
  Future<Failure?> withdrawProposal(Reschedule proposal) => _answer(
        ProviderBookingBusy.withdrawProposal,
        () => _provider.withdrawReschedule(id, proposal.id),
      );

  /// The problem sheet: opens a dispute, then reloads to show it.
  Future<Failure?> reportProblem(ProviderDisputeType type, String description) async {
    try {
      await _provider.openDispute(id, type: type, description: description);
    } on Failure catch (failure) {
      if (failure is ApiFailure && failure.code == ApiErrorCode.disputeAlreadyOpen) {
        await refresh();
      }
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
    await refresh();
    return null;
  }

  /// The booking's chat, else the lookup-or-draft every Message button uses.
  Future<String?> chatRoute() async {
    final ProviderBooking? booking = _booking;
    if (booking == null) return null;
    final String? conversation = booking.conversationId;
    if (conversation != null) return AppRoutes.chatFor(conversation);
    final String clientId = booking.client.id;
    if (clientId.isEmpty) return null;
    return chatRouteWith(userId: clientId, name: booking.clientName);
  }

  Future<Failure?> _answer(
    ProviderBookingBusy kind,
    Future<ProviderBooking> Function() call,
  ) async {
    if (_busy != null) return null;
    _busy = kind;
    notifyListeners();
    final Failure? failure = await _write(call);
    _busy = null;
    notifyListeners();
    return failure;
  }

  Future<Failure?> _write(Future<ProviderBooking> Function() call) async {
    try {
      _booking = await call();
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      if (_isStale(failure)) await refresh();
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
  }

  static bool _isGoneFailure(Failure? failure) =>
      failure is ApiFailure &&
      (failure.code == ApiErrorCode.bookingNotFound ||
          failure.code == ApiErrorCode.notOwner ||
          failure.statusCode == 404);

  /// The booking moved under us: what is shown is out of date.
  static bool _isStale(Failure failure) =>
      failure is ApiFailure &&
      const <String>{
        ApiErrorCode.bookingInvalidTransition,
        ApiErrorCode.bookingNotEditable,
        ApiErrorCode.rescheduleNotPending,
        ApiErrorCode.rescheduleNotFound,
        ApiErrorCode.dateUnavailable,
      }.contains(failure.code);
}

/// A proposal on [booking] this provider has to answer — P4a.
Reschedule? clientProposal(BookingDetail booking) =>
    booking.can(BookingAction.respondReschedule) ? booking.proposalForMe : null;
