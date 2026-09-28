import 'package:flutter/foundation.dart';

import '../budget/budget_repository.dart' show apiDate;
import '../catalog/models/pack.dart' show EventType;
import '../errors/failure.dart';
import '../network/api_client.dart';
import 'models/booking_card.dart';
import 'models/booking_detail.dart';

export 'models/booking_card.dart';
export 'models/booking_detail.dart';

/// What B1 and B9 send — to be priced first (`/quote`), then created.
class BookingRequest {
  const BookingRequest({
    required this.eventDate,
    required this.wilayaCode,
    required this.eventType,
    this.serviceId,
    this.packId,
    this.startTime,
    this.endTime,
    this.guests,
    this.extras = const <String, int>{},
    this.communeId,
    this.locationText,
    this.clientNote,
  }) : assert(
          (serviceId == null) != (packId == null),
          'Exactly one of serviceId and packId.',
        );

  final String? serviceId;
  final String? packId;
  final DateTime eventDate;

  /// `"18:00"`.
  final String? startTime;
  final String? endTime;
  final int? guests;

  /// Extra id → quantity, only those above zero. Services only.
  final Map<String, int> extras;
  final int wilayaCode;
  final String? communeId;
  final String? locationText;
  final EventType eventType;
  final String? clientNote;

  /// What the quote prices: the date, the times, the guests, the extras.
  Map<String, Object?> toQuoteJson() => <String, Object?>{
        'serviceId': ?serviceId,
        'packId': ?packId,
        'eventDate': apiDate(eventDate),
        'startTime': ?startTime,
        'endTime': ?endTime,
        'guests': ?guests,
        if (serviceId != null && extras.isNotEmpty)
          'extras': <Map<String, Object?>>[
            for (final MapEntry<String, int> e in extras.entries)
              if (e.value > 0)
                <String, Object?>{'extraId': e.key, 'quantity': e.value},
          ],
      };

  Map<String, Object?> toJson() => <String, Object?>{
        ...toQuoteJson(),
        'wilayaCode': wilayaCode,
        'communeId': ?communeId,
        if (locationText case final String text when text.trim().isNotEmpty)
          'locationText': text.trim(),
        'eventType': eventType.apiValue,
        if (clientNote case final String note when note.trim().isNotEmpty)
          'clientNote': note.trim(),
      };
}

/// What went wrong, for the problem sheet — the API's dispute `type`.
enum DisputeType {
  providerNoShow('provider_no_show'),
  serviceNotAsDescribed('service_not_as_described'),
  incompleteOrLate('incomplete_or_late'),
  priceDisagreement('price_disagreement'),
  damageOrSafety('damage_or_safety'),
  behaviour('behaviour'),
  other('other');

  const DisputeType(this.apiValue);

  final String apiValue;
}

/// The client's bookings: the four lists, one booking, and everything that
/// can be done to it.
abstract interface class BookingsRepository {
  /// One tab of the client Bookings list. [limit] goes up to the API's 100.
  Future<ApiPage<BookingCard>> list({
    required BookingTab tab,
    int page = 1,
    int limit = 20,
  });

  /// Throws `BOOKING_NOT_FOUND` / `NOT_OWNER`.
  Future<BookingDetail> detail(String id);

  /// The price and whether the date is free. Writes nothing; a taken date is
  /// an answer here, not an error.
  Future<BookingQuote> quote(BookingRequest request);

  /// B1 / B9a "Send". Throws `DATE_UNAVAILABLE` (B1b), `MIN_NOTICE`,
  /// `PROVIDER_NOT_ACCEPTING`.
  Future<BookingDetail> create(BookingRequest request);

  /// B5 — [reason] is at most 60 characters.
  Future<BookingDetail> cancel(String id, {required String reason});

  /// B6. Applied at once on a pending booking; a proposal on an accepted one.
  Future<BookingDetail> reschedule(
    String id, {
    required DateTime date,
    required String reason,
    String? startTime,
    String? endTime,
  });

  /// B6a.
  Future<BookingDetail> acceptReschedule(String id, String rescheduleId);
  Future<BookingDetail> rejectReschedule(String id, String rescheduleId);

  /// Takes back this client's own proposal.
  Future<BookingDetail> withdrawReschedule(String id, String rescheduleId);

  /// B7 "All good".
  Future<BookingDetail> checkIn(String id);

  /// B8. Throws `INVOICE_NOT_FOUND` before the booking is accepted.
  Future<Invoice> invoice(String id);
  Future<Uint8List> invoicePdf(String id);

  /// The review sheet after B4d.
  Future<void> review(String id, {required int rating, required String comment});

  /// B7 "There was a problem". The dispute conversation's id, when the
  /// server opened one.
  Future<BookingDisputeSummary> openDispute(
    String id, {
    required DisputeType type,
    required String description,
  });
}

/// [BookingsRepository] against the live API.
class ApiBookingsRepository implements BookingsRepository {
  ApiBookingsRepository(this._api);

  final ApiClient _api;
  static const String _path = '/app/bookings';

  @override
  Future<ApiPage<BookingCard>> list({
    required BookingTab tab,
    int page = 1,
    int limit = 20,
  }) async {
    final ApiPage<Map<String, Object?>> result = await _api.getPage(
      _path,
      query: <String, Object?>{
        'tab': tab.apiValue,
        'page': page,
        'limit': limit,
      },
    );
    return result.map(BookingCard.fromJson);
  }

  @override
  Future<BookingDetail> detail(String id) async =>
      _detail(await _api.get('$_path/$id'));

  @override
  Future<BookingQuote> quote(BookingRequest request) async => BookingQuote.fromJson(
        _object(await _api.post('$_path/quote', body: request.toQuoteJson())),
      );

  @override
  Future<BookingDetail> create(BookingRequest request) async => _detail(
        await _api.post(
          _path,
          body: request.toJson(),
          headers: <String, String>{'X-Platform': _platform},
        ),
      );

  @override
  Future<BookingDetail> cancel(String id, {required String reason}) async =>
      _detail(
        await _api.post(
          '$_path/$id/cancel',
          body: <String, Object?>{'reason': reason.trim()},
        ),
      );

  @override
  Future<BookingDetail> reschedule(
    String id, {
    required DateTime date,
    required String reason,
    String? startTime,
    String? endTime,
  }) async =>
      _detail(
        await _api.post(
          '$_path/$id/reschedule',
          body: <String, Object?>{
            'date': apiDate(date),
            'startTime': ?startTime,
            'endTime': ?endTime,
            'reason': reason.trim(),
          },
        ),
      );

  @override
  Future<BookingDetail> acceptReschedule(String id, String rescheduleId) async =>
      _detail(await _api.post('$_path/$id/reschedules/$rescheduleId/accept'));

  @override
  Future<BookingDetail> rejectReschedule(String id, String rescheduleId) async =>
      _detail(await _api.post('$_path/$id/reschedules/$rescheduleId/reject'));

  @override
  Future<BookingDetail> withdrawReschedule(
    String id,
    String rescheduleId,
  ) async =>
      _detail(await _api.post('$_path/$id/reschedules/$rescheduleId/withdraw'));

  @override
  Future<BookingDetail> checkIn(String id) async => _detail(
        await _api.post(
          '$_path/$id/check-in',
          body: const <String, Object?>{'answer': 'ok'},
        ),
      );

  @override
  Future<Invoice> invoice(String id) async =>
      Invoice.fromJson(_object(await _api.get('$_path/$id/invoice')));

  @override
  Future<Uint8List> invoicePdf(String id) =>
      _api.getBytes('$_path/$id/invoice.pdf');

  @override
  Future<void> review(
    String id, {
    required int rating,
    required String comment,
  }) async {
    await _api.post(
      '$_path/$id/review',
      body: <String, Object?>{'rating': rating, 'comment': comment.trim()},
    );
  }

  @override
  Future<BookingDisputeSummary> openDispute(
    String id, {
    required DisputeType type,
    required String description,
  }) async =>
      BookingDisputeSummary.fromJson(
        _object(
          await _api.post(
            '$_path/$id/disputes',
            body: <String, Object?>{
              'type': type.apiValue,
              'description': description.trim(),
            },
          ),
        ),
      );

  static String get _platform => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        _ => 'android',
      };

  static BookingDetail _detail(Object? data) =>
      BookingDetail.fromJson(_object(data));

  static Map<String, Object?> _object(Object? data) {
    if (data is Map<String, Object?>) return data;
    throw UnexpectedFailure(cause: data);
  }
}
