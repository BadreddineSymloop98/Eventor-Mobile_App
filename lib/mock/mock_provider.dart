import 'package:flutter/foundation.dart';

import '../core/bookings/models/booking_card.dart';
import '../core/bookings/models/booking_detail.dart';
import '../core/errors/failure.dart';
import '../core/models/account.dart';
import '../core/network/api_page.dart';
import '../core/provider/provider_repository.dart';
import '../features/auth/data/documents_repository.dart';
import 'mock_backend.dart';
import 'mock_catalog.dart';
import 'mock_messaging.dart';

/// A provider's documents as `GET /app/me/documents` answers — shared by the
/// mock documents repository and the mock provider home, as the API shares
/// the payload.
Map<String, Object?> mockDocumentsJson(MockAccount account, DateTime now) {
  final Map<String, String> labels = <String, String>{
    ProviderDocumentType.nationalId.apiValue: 'National ID card',
    ProviderDocumentType.commercialRegister.apiValue: 'Register or artisan card',
    ProviderDocumentType.taxCard.apiValue: 'Tax registration card (NIF)',
  };
  final List<Map<String, Object?>> documents = <Map<String, Object?>>[
    for (final ProviderDocumentType type in ProviderDocumentType.values)
      () {
        final String status = account.documents[type.apiValue] ?? 'missing';
        final Map<String, Object?> review =
            account.documentReviews[type.apiValue] ?? const <String, Object?>{};
        final int daysAgo = (review['daysAgo'] as num?)?.toInt() ?? 1;
        final bool reviewed = status == 'approved' || status == 'rejected';
        return <String, Object?>{
          'id': status == 'missing' ? null : 'mock-doc-${type.apiValue}',
          'type': type.apiValue,
          'label': labels[type.apiValue],
          'status': status,
          'fileUrl': null,
          'rejectReason': status == 'rejected' ? review['reason'] : null,
          'rejectReasonLabel': status == 'rejected' ? review['reasonLabel'] : null,
          'rejectNote': status == 'rejected' ? review['note'] : null,
          'reviewedAt': reviewed
              ? now.subtract(Duration(days: daysAgo)).toUtc().toIso8601String()
              : null,
          'submittedAt': status == 'missing'
              ? null
              : now.subtract(Duration(days: daysAgo + 2)).toUtc().toIso8601String(),
          'resubmitted': false,
        };
      }(),
  ];
  final Map<String, int> progress = <String, int>{
    'approved': 0,
    'rejected': 0,
    'waiting': 0,
    'missing': 0,
  };
  for (final Map<String, Object?> d in documents) {
    final String key = switch (d['status']) {
      'approved' => 'approved',
      'rejected' => 'rejected',
      'pending' => 'waiting',
      _ => 'missing',
    };
    progress[key] = progress[key]! + 1;
  }
  return <String, Object?>{
    'verificationStatus': account.verificationStatus.apiValue,
    'actionNeeded': progress['rejected']! + progress['missing']! > 0,
    'maxFileSizeMb': 5,
    'acceptedTypes': <String>['application/pdf', 'image/jpeg', 'image/png', 'image/webp'],
    'documents': documents,
    'progress': progress,
  };
}

/// [ProviderRepository] on the in-app [MockBackend] with the live rules.
///
/// The bookings are the shared store the client's mock reads too (user
/// decision 1, 2026-09-28): a request a client sends to one of Salle
/// Yasmine's services is on `verified.provider@eventor.test`'s P1 at once,
/// and whatever the provider does to it is what the client then sees. The
/// home follows the verification status; only a verified provider can
/// accept; decline and cancel need a reason of 1–60 characters, a new date
/// one of 1–200; only one proposal is open at a time; "All good" waits for
/// the event.
class MockProviderRepository implements ProviderRepository {
  MockProviderRepository(
    this._backend,
    this._lookups, {
    this._messaging,
    this._blockedDates,
    this._serviceRows,
  });

  final MockBackend _backend;
  final MockCatalogLookups _lookups;

  /// Where the unread counts come from, when given.
  final MockMessagingStore? _messaging;

  /// The provider's whole-day blocks (`YYYY-MM-DD`), when the availability
  /// mock is wired in — P4's calendar greys them out and a new date on one
  /// is refused. Without it, only bookings take days.
  final Set<String> Function(MockAccount provider)? _blockedDates;

  /// The provider's own services as `AppProviderServiceRowDto` rows, when
  /// the catalog mock (P6–P14) is wired in — so a service added or edited
  /// there shows on 21. Without it, the const catalog's services.
  final List<Map<String, Object?>> Function(MockAccount provider)? _serviceRows;

  late final MockProviderBookings _bookings = _lookups.providerBookings;

  Set<String> _blocked() {
    final Set<String> Function(MockAccount provider)? blocked = _blockedDates;
    return blocked == null ? const <String>{} : blocked(_backend.requireProvider());
  }

  @override
  Future<ProviderHome> home() async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final DateTime now = _backend.now;
    final VerificationStatus status = account.verificationStatus;
    final String state = account.blockedMessage != null
        ? 'blocked'
        : switch (status) {
            VerificationStatus.verified => 'verified',
            VerificationStatus.rejected => 'rejected',
            _ => 'pending',
          };
    final Map<String, Object?> documents = mockDocumentsJson(account, now);
    final bool verified = state == 'verified';

    final List<Map<String, Object?>> Function(MockAccount provider)? rows = _serviceRows;
    final List<Map<String, Object?>> services = rows != null
        ? rows(account)
        : _lookups.providerServices(account.businessName);
    // `requests` is empty while the profile is under review, as live.
    final List<Map<String, Object?>> requests =
        verified ? _bookings.tab('requests') : <Map<String, Object?>>[];
    final List<Map<String, Object?>> upcoming =
        verified ? _bookings.tab('upcoming') : <Map<String, Object?>>[];

    return ProviderHome.fromJson(<String, Object?>{
      'state': state,
      'businessName': account.businessName ?? account.fullName,
      'avatarUrl': null,
      'verificationStatus': status.apiValue,
      'verificationSteps': _steps(state, documents),
      'documents': verified ? null : documents,
      'acceptingBookings': account.acceptingBookings,
      'avgRating': '0.00',
      'ratingCount': 0,
      'completedBookingsCount': 0,
      'counts': <String, Object?>{
        'requests': requests.length,
        'upcoming': upcoming.length,
        'services': services.length,
        'unreadMessages': _messaging?.unreadConversations() ?? 0,
        'unreadNotifications': _messaging?.unreadNotifications() ?? 0,
      },
      'requests': requests.take(3).toList(),
      'upcoming': upcoming.take(3).toList(),
      'services': verified ? services.take(3).toList() : <Object?>[],
    });
  }

  @override
  Future<bool> setAcceptingBookings(bool accepting) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    account.acceptingBookings = accepting;
    await _backend.saveProvider();
    return accepting;
  }

  @override
  Future<ApiPage<BookingCard>> bookings({
    required ProviderBookingTab tab,
    int page = 1,
    int limit = 20,
  }) async {
    await _backend.delay();
    if (page < 1 || limit < 1 || limit > 100) {
      throw const ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.validationFailed,
        message: 'Some fields are invalid.',
      );
    }
    final List<BookingCard> all =
        _bookings.tab(tab.apiValue).map(BookingCard.fromJson).toList();
    final int start = (page - 1) * limit;
    return ApiPage<BookingCard>(
      items: start >= all.length
          ? <BookingCard>[]
          : all.sublist(start, (start + limit).clamp(0, all.length)),
      page: page,
      totalPages: (all.length / limit).ceil(),
      total: all.length,
    );
  }

  @override
  Future<ProviderBooking> booking(String bookingId) async {
    await _backend.delay();
    return ProviderBooking.fromJson(_bookings.detail(bookingId));
  }

  @override
  Future<ProviderBooking> accept(String bookingId) => _write(() => _bookings.accept(bookingId));

  @override
  Future<ProviderBooking> decline(String bookingId, {required String reason}) =>
      _write(() => _bookings.decline(bookingId, reason));

  @override
  Future<ProviderBooking> cancel(String bookingId, {required String reason}) =>
      _write(() => _bookings.cancel(bookingId, reason));

  @override
  Future<ProviderBooking> reschedule(
    String bookingId, {
    required DateTime date,
    required String reason,
    String? startTime,
    String? endTime,
  }) =>
      _write(
        () => _bookings.reschedule(
          bookingId,
          date: date,
          reason: reason,
          startTime: startTime,
          endTime: endTime,
          blockedDates: _blocked(),
        ),
      );

  @override
  Future<ProviderBooking> acceptReschedule(String bookingId, String rescheduleId) =>
      _write(() => _bookings.answerReschedule(bookingId, rescheduleId, 'accept'));

  @override
  Future<ProviderBooking> rejectReschedule(String bookingId, String rescheduleId) =>
      _write(() => _bookings.answerReschedule(bookingId, rescheduleId, 'reject'));

  @override
  Future<ProviderBooking> withdrawReschedule(String bookingId, String rescheduleId) =>
      _write(() => _bookings.answerReschedule(bookingId, rescheduleId, 'withdraw'));

  @override
  Future<ProviderBooking> checkIn(String bookingId) => _write(() => _bookings.checkIn(bookingId));

  @override
  Future<BookingDisputeSummary> openDispute(
    String bookingId, {
    required ProviderDisputeType type,
    required String description,
  }) async {
    await _backend.delay();
    return BookingDisputeSummary.fromJson(
      await _bookings.openDispute(bookingId, type.apiValue, description),
    );
  }

  @override
  Future<Invoice> invoice(String bookingId) async {
    await _backend.delay();
    return Invoice.fromJson(_bookings.invoice(bookingId));
  }

  @override
  Future<Uint8List> invoicePdf(String bookingId) async {
    await _backend.delay();
    return _bookings.invoicePdf(bookingId);
  }

  @override
  Future<ProviderCalendarMonth> availabilityMonth(DateTime month) async {
    await _backend.delay();
    return ProviderCalendarMonth.fromJson(
      _bookings.month(month, blockedDates: _blocked()),
    );
  }

  Future<ProviderBooking> _write(
    Future<Map<String, Object?>> Function() call,
  ) async {
    await _backend.delay();
    return ProviderBooking.fromJson(await call());
  }

  /// The checklist the API sends for each state.
  static List<Map<String, Object?>> _steps(
    String state,
    Map<String, Object?> documents,
  ) {
    final Map<String, Object?> progress =
        documents['progress']! as Map<String, Object?>;
    final bool allSent = progress['missing'] == 0;
    Map<String, Object?> step(String key, {required bool done, bool current = false}) =>
        <String, Object?>{'key': key, 'done': done, 'current': current};
    return switch (state) {
      'verified' => <Map<String, Object?>>[
          step('account_created', done: true),
          step('documents_submitted', done: true),
          step('under_review', done: true),
          step('approved', done: true),
        ],
      'rejected' => <Map<String, Object?>>[
          step('account_created', done: true),
          step('documents_submitted', done: true),
          step('under_review', done: true),
          step('approved', done: false, current: true),
        ],
      _ => <Map<String, Object?>>[
          step('account_created', done: true),
          step('documents_submitted', done: allSent, current: !allSent),
          step('under_review', done: false, current: allSent),
          step('approved', done: false),
        ],
    };
  }
}
