import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/models/booking_card.dart';
import '../../../core/errors/failure.dart';
import '../../../core/provider/models/provider_booking.dart' as provider_booking show replyHoursLeft;
import '../../../core/provider/provider_repository.dart';
import '../../../core/session/session_controller.dart';
import '../../home/view_model/home_view_model.dart' show Greeting;
import '../../shell/shell_badges.dart';

export '../../home/view_model/home_view_model.dart' show Greeting;

/// Screens 21, 21a and 21b: the provider's home, from one
/// `/app/provider/home` call.
///
/// Answering a request (Accept here, Decline through its sheet) reloads the
/// home, so the counters and both lists move together; a refusal that means
/// the request changed meanwhile reloads too. A blocked account stays signed
/// in and sees 21c: it can still read its chats and history (user decision,
/// 2026-09-27).
class ProviderHomeViewModel extends BaseViewModel {
  ProviderHomeViewModel({
    required this._provider,
    required this._session,
    required this._badges,
    required this._replyDeadlineHours,
    this._now = DateTime.now,
  }) {
    load();
  }

  final ProviderRepository _provider;
  final SessionController _session;
  final ShellBadges _badges;
  final int _replyDeadlineHours;
  final DateTime Function() _now;

  ProviderHome? _home;
  bool _isLoading = false;
  String? _accepting;
  bool _isSavingAvailability = false;

  ProviderHome? get home => _home;

  /// Nothing to show yet — the skeleton.
  bool get isFirstLoad => _home == null && (_isLoading || !hasError);

  /// The request whose Accept is running.
  String? get accepting => _accepting;
  bool get isSavingAvailability => _isSavingAvailability;

  /// How long a request waits for an answer, from the server's config.
  int get replyDeadlineHours => _replyDeadlineHours;

  /// The provider's own name, for the header — the design greets the person,
  /// not the business.
  String get fullName => _session.user?.fullName ?? _home?.businessName ?? '';

  /// Morning from 05:00, afternoon from 12:00, evening from 18:00.
  Greeting get greeting {
    final int hour = _now().hour;
    if (hour >= 5 && hour < 12) return Greeting.morning;
    if (hour >= 12 && hour < 18) return Greeting.afternoon;
    return Greeting.evening;
  }

  /// Whole hours left to answer [request] — "reply within 47 h" — never
  /// below zero; `null` when the server did not say when it was made.
  int? replyHoursLeft(BookingCard request) =>
      // Shared with P1 / P2, so the two screens never disagree.
      provider_booking.replyHoursLeft(
        request,
        deadlineHours: _replyDeadlineHours,
        now: _now(),
      );

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final ProviderHome? home = await runGuarded(_provider.home);
    if (home != null) _apply(home);
    _isLoading = false;
    notifyListeners();
  }

  /// Pull to refresh, and the reload after a screen opened from here. What
  /// is on screen stays when it fails.
  Future<Failure?> refresh() async {
    try {
      _apply(await _provider.home());
      clearFailure();
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
  }

  /// Accepts [request]. `null` when it went through.
  Future<Failure?> accept(BookingCard request) async {
    if (_accepting != null) return null;
    _accepting = request.id;
    notifyListeners();
    Failure? failure;
    try {
      await _provider.accept(request.id);
    } on Failure catch (error) {
      failure = error;
    } catch (error) {
      failure = UnexpectedFailure(cause: error);
    }
    // Either way the list may be stale: accepted, taken meanwhile, or gone.
    await refresh();
    _accepting = null;
    notifyListeners();
    return failure;
  }

  /// Declines [request] with the client-facing [reason] — P3's confirm. The
  /// sheet waits on it, so the failure comes back to it.
  Future<Failure?> decline(BookingCard request, String reason) async {
    try {
      await _provider.decline(request.id, reason: reason.trim());
    } on Failure catch (failure) {
      if (_isStale(failure)) await refresh();
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
    await refresh();
    return null;
  }

  /// 21's "Accepting bookings" choice. Shown at once, put back if the
  /// server refuses.
  Future<Failure?> setAcceptingBookings(bool accepting) async {
    final ProviderHome? home = _home;
    if (home == null || _isSavingAvailability) return null;
    if (home.acceptingBookings == accepting) return null;
    _isSavingAvailability = true;
    _home = home.copyWith(acceptingBookings: accepting);
    notifyListeners();
    Failure? failure;
    try {
      final bool saved = await _provider.setAcceptingBookings(accepting);
      _home = _home?.copyWith(acceptingBookings: saved);
    } on Failure catch (error) {
      failure = error;
      _home = _home?.copyWith(acceptingBookings: home.acceptingBookings);
    }
    _isSavingAvailability = false;
    notifyListeners();
    return failure;
  }

  void _apply(ProviderHome home) {
    _home = home;
    _badges.update(
      unreadConversations: home.counts.unreadMessages,
      unreadNotifications: home.counts.unreadNotifications,
    );
  }

  static bool _isStale(Failure failure) =>
      failure is ApiFailure &&
      (failure.code == ApiErrorCode.bookingInvalidTransition ||
          failure.code == ApiErrorCode.bookingNotFound);
}
