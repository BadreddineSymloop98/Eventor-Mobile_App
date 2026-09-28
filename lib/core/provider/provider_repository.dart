import 'package:flutter/foundation.dart';

import '../bookings/models/booking_card.dart';
import '../bookings/models/booking_detail.dart';
import '../budget/budget_repository.dart' show apiDate;
import '../catalog/catalog_repository.dart' show monthParam;
import '../errors/failure.dart';
import '../network/api_client.dart';
import 'models/provider_booking.dart';
import 'models/provider_home.dart';

export 'models/provider_booking.dart';
export 'models/provider_home.dart';

/// The provider's own side of the app: their home, their requests and
/// bookings (section 10, P1–P5), and their answers to them.
///
/// Every write on a booking answers with the booking as it now stands, so a
/// screen replaces what it shows instead of reloading.
abstract interface class ProviderRepository {
  /// 21 / 21a / 21b in one call.
  Future<ProviderHome> home();

  /// 21's "Accepting bookings" choice. Paused keeps the services visible
  /// and refuses new requests. Returns what the server now holds.
  Future<bool> setAcceptingBookings(bool accepting);

  /// One of P1's three lists. [limit] goes up to the API's 100.
  Future<ApiPage<BookingCard>> bookings({
    required ProviderBookingTab tab,
    int page = 1,
    int limit = 20,
  });

  /// P2 and its variants. Throws `BOOKING_NOT_FOUND`, or `NOT_OWNER` for
  /// another provider's booking.
  Future<ProviderBooking> booking(String bookingId);

  /// Accepts a pending request — the date is re-checked on the server
  /// (`DATE_UNAVAILABLE`); only a verified provider can
  /// (`PROVIDER_NOT_VERIFIED`).
  Future<ProviderBooking> accept(String bookingId);

  /// Declines a pending request; the client reads [reason] (1–60).
  Future<ProviderBooking> decline(String bookingId, {required String reason});

  /// Cancels an accepted booking; the client reads [reason] (1–60). The date
  /// is released and the invoice voided.
  Future<ProviderBooking> cancel(String bookingId, {required String reason});

  /// P4. A pending request moves at once; an accepted booking gets a
  /// proposal the client answers. [reason] is required (1–200). Throws
  /// `RESCHEDULE_PENDING_EXISTS`, `DATE_UNAVAILABLE`, `BOOKING_DATE_PAST`.
  Future<ProviderBooking> reschedule(
    String bookingId, {
    required DateTime date,
    required String reason,
    String? startTime,
    String? endTime,
  });

  /// P4a "Accept {date}" — the client's proposal moves the booking.
  Future<ProviderBooking> acceptReschedule(String bookingId, String rescheduleId);

  /// P4a "Decline" — the booking keeps its date.
  Future<ProviderBooking> rejectReschedule(String bookingId, String rescheduleId);

  /// Takes back the provider's own proposal while the client has not
  /// answered.
  Future<ProviderBooking> withdrawReschedule(String bookingId, String rescheduleId);

  /// P5 "All good". When the client said so too, the booking completes at
  /// once. Throws `CHECK_IN_TOO_EARLY`, `CHECK_IN_NOT_ALLOWED`,
  /// `CHECK_IN_DISPUTED`.
  Future<ProviderBooking> checkIn(String bookingId);

  /// "There was a problem" / "Report a problem" — the dispute route both
  /// sides share (`POST /app/bookings/{id}/disputes`). [description] is 30
  /// to 5000 characters.
  Future<BookingDisputeSummary> openDispute(
    String bookingId, {
    required ProviderDisputeType type,
    required String description,
  });

  /// The invoice Eventor issued on acceptance — accepted or completed
  /// bookings only (`INVOICE_NOT_FOUND`).
  Future<Invoice> invoice(String bookingId);

  /// The same invoice as a PDF.
  Future<Uint8List> invoicePdf(String bookingId);

  /// The provider's own calendar for the month holding [month] — read-only,
  /// for P4's day picker. Blocking and unblocking days live with the
  /// availability screen (P15).
  Future<ProviderCalendarMonth> availabilityMonth(DateTime month);
}

/// [ProviderRepository] against the live API.
class ApiProviderRepository implements ProviderRepository {
  ApiProviderRepository(this._api);

  final ApiClient _api;
  static const String _bookings = '/app/provider/bookings';

  @override
  Future<ProviderHome> home() async {
    final Object? data = await _api.get('/app/provider/home');
    return ProviderHome.fromJson(
      data is Map<String, Object?> ? data : const <String, Object?>{},
    );
  }

  @override
  Future<bool> setAcceptingBookings(bool accepting) async {
    final Object? data = await _api.patch(
      '/app/provider/profile',
      body: <String, Object?>{'acceptingBookings': accepting},
    );
    // Answers with the whole account; the toggle lives on its provider part.
    final Object? provider = data is Map<String, Object?> ? data['provider'] : null;
    final Object? value =
        provider is Map<String, Object?> ? provider['acceptingBookings'] : null;
    return value is bool ? value : accepting;
  }

  @override
  Future<ApiPage<BookingCard>> bookings({
    required ProviderBookingTab tab,
    int page = 1,
    int limit = 20,
  }) async {
    final ApiPage<Map<String, Object?>> result = await _api.getPage(
      _bookings,
      query: <String, Object?>{
        'tab': tab.apiValue,
        'page': page,
        'limit': limit,
      },
    );
    return result.map(BookingCard.fromJson);
  }

  @override
  Future<ProviderBooking> booking(String bookingId) async =>
      _booking(await _api.get('$_bookings/$bookingId'));

  @override
  Future<ProviderBooking> accept(String bookingId) async =>
      _booking(await _api.post('$_bookings/$bookingId/accept'));

  @override
  Future<ProviderBooking> decline(String bookingId, {required String reason}) async =>
      _booking(
        await _api.post(
          '$_bookings/$bookingId/decline',
          body: <String, Object?>{'reason': reason.trim()},
        ),
      );

  @override
  Future<ProviderBooking> cancel(String bookingId, {required String reason}) async =>
      _booking(
        await _api.post(
          '$_bookings/$bookingId/cancel',
          body: <String, Object?>{'reason': reason.trim()},
        ),
      );

  @override
  Future<ProviderBooking> reschedule(
    String bookingId, {
    required DateTime date,
    required String reason,
    String? startTime,
    String? endTime,
  }) async =>
      _booking(
        await _api.post(
          '$_bookings/$bookingId/reschedule',
          body: <String, Object?>{
            'date': apiDate(date),
            'startTime': ?startTime,
            // An end without a start means nothing to the server.
            if (startTime != null) 'endTime': ?endTime,
            'reason': reason.trim(),
          },
        ),
      );

  @override
  Future<ProviderBooking> acceptReschedule(String bookingId, String rescheduleId) async =>
      _booking(await _api.post('$_bookings/$bookingId/reschedules/$rescheduleId/accept'));

  @override
  Future<ProviderBooking> rejectReschedule(String bookingId, String rescheduleId) async =>
      _booking(await _api.post('$_bookings/$bookingId/reschedules/$rescheduleId/reject'));

  @override
  Future<ProviderBooking> withdrawReschedule(String bookingId, String rescheduleId) async =>
      _booking(await _api.post('$_bookings/$bookingId/reschedules/$rescheduleId/withdraw'));

  @override
  Future<ProviderBooking> checkIn(String bookingId) async => _booking(
        await _api.post(
          '$_bookings/$bookingId/check-in',
          body: const <String, Object?>{'answer': 'ok'},
        ),
      );

  @override
  Future<BookingDisputeSummary> openDispute(
    String bookingId, {
    required ProviderDisputeType type,
    required String description,
  }) async =>
      BookingDisputeSummary.fromJson(
        _object(
          await _api.post(
            '/app/bookings/$bookingId/disputes',
            body: <String, Object?>{
              'type': type.apiValue,
              'description': description.trim(),
            },
          ),
        ),
      );

  @override
  Future<Invoice> invoice(String bookingId) async =>
      Invoice.fromJson(_object(await _api.get('$_bookings/$bookingId/invoice')));

  @override
  Future<Uint8List> invoicePdf(String bookingId) =>
      _api.getBytes('$_bookings/$bookingId/invoice.pdf');

  @override
  Future<ProviderCalendarMonth> availabilityMonth(DateTime month) async =>
      ProviderCalendarMonth.fromJson(
        _object(
          await _api.get(
            '/app/provider/availability',
            query: <String, Object?>{'month': monthParam(month)},
          ),
        ),
      );

  static ProviderBooking _booking(Object? data) =>
      ProviderBooking.fromJson(_object(data));

  static Map<String, Object?> _object(Object? data) {
    if (data is Map<String, Object?>) return data;
    throw UnexpectedFailure(cause: data);
  }
}
