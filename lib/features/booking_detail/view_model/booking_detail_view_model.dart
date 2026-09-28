import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/bookings_repository.dart';
import '../../../core/errors/failure.dart';
import '../../../core/messaging/chat_launcher.dart';
import '../../../core/messaging/messaging_repository.dart';
import '../../../core/routing/app_routes.dart';

/// B4 Booking detail, in every status (B4a–B4d), and what is answered from
/// it: cancelling (B5), a date the provider proposes (B6a), withdrawing the
/// client's own proposal, the review and the problem report.
///
/// Every write answers with the booking as it now stands, which replaces
/// what is on screen; a refusal that means it moved meanwhile reloads it.
class BookingDetailViewModel extends BaseViewModel with ChatLauncher {
  BookingDetailViewModel({
    required this.id,
    required this._bookings,
    required this._messaging,
    required this.replyDeadlineHours,
    this._now = DateTime.now,
  }) {
    load();
  }

  final String id;
  final BookingsRepository _bookings;
  final MessagingRepository _messaging;
  final DateTime Function() _now;

  /// How long a provider has to answer, from the server's config.
  final int replyDeadlineHours;

  /// B5's cap on the reason.
  static const int maxCancelReason = 60;

  @override
  MessagingRepository get chatMessaging => _messaging;

  BookingDetail? _detail;
  bool _isLoading = false;
  bool _isGone = false;
  String? _answering;

  BookingDetail? get detail => _detail;
  bool get isFirstLoad => _detail == null && (_isLoading || !hasError);
  bool get isGone => _isGone;

  /// `accept`, `reject` or `withdraw` while that answer is on its way.
  String? get answering => _answering;

  DateTime get now => _now();

  /// Whole days from today to the event — B5's note. Never below zero.
  int get daysToEvent {
    final BookingDetail? booking = _detail;
    if (booking == null) return 0;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int days = booking.card.eventDate.difference(today).inDays;
    return days < 0 ? 0 : days;
  }

  /// The event day is behind us.
  bool get eventPassed {
    final BookingDetail? booking = _detail;
    if (booking == null) return false;
    final DateTime today = DateTime(now.year, now.month, now.day);
    return booking.card.eventDate.isBefore(today);
  }

  Future<void> load() async {
    _isLoading = true;
    _isGone = false;
    notifyListeners();
    final BookingDetail? loaded = await runGuarded(() => _bookings.detail(id));
    final Failure? failure = this.failure;
    if (loaded != null) {
      _detail = loaded;
    } else if (_isGoneFailure(failure)) {
      _isGone = true;
      clearFailure();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Pull to refresh, and the reload after B6 / B7 / B8. What is on screen
  /// stays when it fails.
  Future<Failure?> refresh() async {
    try {
      _detail = await _bookings.detail(id);
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

  /// What B6 or B7 came back with.
  void replace(BookingDetail booking) {
    _detail = booking;
    notifyListeners();
  }

  /// B5's "Yes, cancel". `null` when it went through.
  Future<Failure?> cancel(String reason) =>
      _write(() => _bookings.cancel(id, reason: reason));

  /// B6a "Accept {date}".
  Future<Failure?> acceptProposal(Reschedule proposal) =>
      _answer('accept', () => _bookings.acceptReschedule(id, proposal.id));

  /// B6a "Decline" — the booking keeps its date.
  Future<Failure?> rejectProposal(Reschedule proposal) =>
      _answer('reject', () => _bookings.rejectReschedule(id, proposal.id));

  /// Takes back this client's own proposal.
  Future<Failure?> withdrawProposal(Reschedule proposal) =>
      _answer('withdraw', () => _bookings.withdrawReschedule(id, proposal.id));

  /// The review sheet. Reloads so "Leave a review" goes away.
  Future<Failure?> review(int rating, String comment) async {
    try {
      await _bookings.review(id, rating: rating, comment: comment);
    } on Failure catch (failure) {
      if (failure is ApiFailure && failure.code == ApiErrorCode.reviewExists) {
        await refresh();
      }
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
    await refresh();
    return null;
  }

  /// The problem sheet: opens a dispute. Reloads to show it.
  Future<Failure?> reportProblem(DisputeType type, String description) async {
    try {
      await _bookings.openDispute(id, type: type, description: description);
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
    final BookingDetail? booking = _detail;
    if (booking == null) return null;
    final String? conversation = booking.conversationId;
    if (conversation != null) return AppRoutes.chatFor(conversation);
    final String? providerId = booking.provider?.id;
    if (providerId == null) return null;
    return chatRouteWith(userId: providerId, name: booking.card.providerName);
  }

  Future<Failure?> _answer(String kind, Future<BookingDetail> Function() call) async {
    if (_answering != null) return null;
    _answering = kind;
    notifyListeners();
    final Failure? failure = await _write(call);
    _answering = null;
    notifyListeners();
    return failure;
  }

  Future<Failure?> _write(Future<BookingDetail> Function() call) async {
    try {
      _detail = await call();
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
