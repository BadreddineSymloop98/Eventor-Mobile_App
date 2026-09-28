import 'dart:async';
import 'dart:typed_data';

import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/network/api_page.dart';

/// An `AppBookingDetailDto` as the live API sends it, with the parts a test
/// cares about overridable.
Map<String, Object?> bookingJson({
  String id = 'b-1',
  String status = 'accepted',
  String eventDate = '2026-03-14',
  String? startTime = '13:00',
  String? endTime = '23:00',
  List<String> allowedActions = const <String>['message', 'cancel', 'reschedule', 'invoice'],
  List<Map<String, Object?>> reschedules = const <Map<String, Object?>>[],
  List<Map<String, Object?>>? timeline,
  String? phone = '+213770551288',
  String? cancelReason,
  String? cancelledBy,
  String? declineReason,
  String? serviceId = 's-1',
  String? packId,
  Map<String, Object?>? dispute,
  bool checkedIn = false,
  bool otherCheckedIn = false,
}) =>
    <String, Object?>{
      'id': id,
      'reference': 'EVT-002041',
      'status': status,
      'disputeStatus': dispute == null ? 'none' : 'open',
      'eventType': 'wedding',
      'eventDate': eventDate,
      'startTime': startTime,
      'endTime': endTime,
      'title': 'Wedding photo & video coverage',
      'titleEn': 'Wedding photo & video coverage',
      'titleAr': 'تغطية زفاف',
      'serviceId': serviceId,
      'packId': packId,
      'category': packId != null
          ? null
          : <String, Object?>{
              'id': 'cat-photo',
              'slug': 'photography',
              'name': 'Photography',
              'nameEn': 'Photography',
              'nameAr': 'التصوير',
              'icon': 'camera',
            },
      'coverUrl': null,
      'wilaya': <String, Object?>{'code': 16, 'name': 'Alger', 'nameEn': 'Alger', 'nameAr': 'الجزائر'},
      'guests': 150,
      'total': '71000.00',
      'counterparty': <String, Object?>{
        'id': 'p-lumiere',
        'fullName': 'Studio Lumière',
        'avatarUrl': null,
        'businessName': 'Studio Lumière',
        'phone': phone,
        'email': null,
      },
      'conversationId': null,
      'allowedActions': allowedActions,
      'createdAt': '2026-03-03T13:20:00.000Z',
      'locationText': 'Salle Yasmine, Route de Chéraga',
      'communeName': 'Hydra',
      'clientNote': 'The ceremony starts at 15:00.',
      'lines': <Map<String, Object?>>[
        <String, Object?>{
          'id': 'l-1',
          'kind': 'service',
          'label': 'Wedding photo & video coverage',
          'quantity': 1,
          'unitAmount': '45000.00',
          'amount': '45000.00',
        },
        <String, Object?>{
          'id': 'l-2',
          'kind': 'extra',
          'label': 'Extra hour',
          'quantity': 2,
          'unitAmount': '4000.00',
          'amount': '8000.00',
        },
      ],
      'subtotal': '71000.00',
      'discountTotal': '0.00',
      'feePercent': '8.00',
      'cancellationPolicy': 'Cancel at least 7 days before the event.',
      'cancelReason': cancelReason,
      'cancelledBy': cancelledBy,
      'declineReason': declineReason,
      'provider': <String, Object?>{
        'id': 'p-lumiere',
        'businessName': 'Studio Lumière',
        'category': null,
        'avatarUrl': null,
        'verified': true,
        'avgRating': '4.80',
        'ratingCount': 32,
        'completedBookingsCount': 48,
        'yearsActive': 6,
        'avgReplyMinutes': 120,
        'replyTime': '2 h',
        'acceptingBookings': true,
      },
      'timeline': timeline ??
          <Map<String, Object?>>[
            <String, Object?>{'type': 'created', 'toStatus': 'pending', 'actorLabel': 'Amina B.', 'reason': null, 'at': '2026-03-03T13:20:00.000Z'},
            <String, Object?>{'type': 'accepted', 'toStatus': 'accepted', 'actorLabel': 'Studio Lumière', 'reason': null, 'at': '2026-03-03T15:05:00.000Z'},
          ],
      'reschedules': reschedules,
      'invoice': <String, Object?>{
        'id': 'inv-1',
        'number': 'INV-2026-0142',
        'version': 1,
        'total': '71000.00',
        'voided': status == 'cancelled',
        'pdfPath': '/api/v1/app/bookings/$id/invoice.pdf',
        'issuedAt': '2026-03-03T15:05:00.000Z',
      },
      'dispute': dispute,
      'checkedIn': checkedIn,
      'otherCheckedIn': otherCheckedIn,
      'reviewId': null,
      'reviewWindowOpen': false,
      'disputeWindowOpen': false,
    };

BookingDetail testBooking({
  String status = 'accepted',
  List<String> allowedActions = const <String>['message', 'cancel', 'reschedule', 'invoice'],
  List<Map<String, Object?>> reschedules = const <Map<String, Object?>>[],
  String? packId,
}) =>
    BookingDetail.fromJson(
      bookingJson(
        status: status,
        allowedActions: allowedActions,
        reschedules: reschedules,
        packId: packId,
        serviceId: packId == null ? 's-1' : null,
      ),
    );

/// A provider's proposal waiting on the client — B6a.
Map<String, Object?> proposalJson({bool awaitingMe = true}) => <String, Object?>{
      'id': 'r-1',
      'status': 'pending',
      'oldDate': '2026-03-14',
      'newDate': '2026-03-21',
      'newStartTime': '13:00',
      'newEndTime': '23:00',
      'reason': 'A wedding I had booked first was moved to the 14th.',
      'proposedByRole': awaitingMe ? 'provider' : 'client',
      'awaitingMe': awaitingMe,
      'createdAt': '2026-03-06T10:02:00.000Z',
    };

Map<String, Object?> invoiceJson() => <String, Object?>{
      'id': 'inv-1',
      'bookingId': 'b-1',
      'bookingReference': 'EVT-002041',
      'number': 'INV-2026-0142',
      'version': 1,
      'issuedAt': '2026-03-03T15:05:00.000Z',
      'currency': 'DZD',
      'issuer': <String, Object?>{
        'name': 'Eventor (Symloop SARL)',
        'address': 'Cité 1er Novembre, Bab Ezzouar, Alger',
        'nif': '001216099999999',
        'rc': '16/00-1234567B21',
        'email': 'billing@eventor.dz',
        'phone': '+213 23 00 00 00',
      },
      'client': <String, Object?>{'id': 'c-1', 'name': 'Amina Benali', 'businessName': null, 'email': null, 'phone': '+213661247890'},
      'provider': <String, Object?>{'id': 'p-lumiere', 'name': 'Yasmine K.', 'businessName': 'Studio Lumière', 'email': null, 'phone': '+213770551288'},
      'titleEn': 'Wedding photo & video coverage',
      'titleAr': 'تغطية زفاف',
      'eventDate': '2026-03-14',
      'eventType': 'wedding',
      'lines': <Map<String, Object?>>[
        <String, Object?>{'kind': 'service', 'label': 'Wedding photo & video coverage', 'quantity': 1, 'unitAmount': '45000.00', 'amount': '45000.00'},
      ],
      'subtotal': '71000.00',
      'discountTotal': '0.00',
      'total': '71000.00',
      'feePercent': '10.00',
      'feeAmount': '7100.00',
      'providerAmount': '63900.00',
      'pdfReady': true,
      'sentToClientAt': null,
      'versions': <int>[1],
    };

/// [BookingsRepository] with scripted answers: [booking] is what `detail`
/// and every write return unless [afterWrite] is set.
class ScriptedBookingsRepository implements BookingsRepository {
  final Map<BookingTab, List<BookingCard>> tabs = <BookingTab, List<BookingCard>>{};

  /// `list:upcoming:1`, `detail:b-1`, `quote`, `create`, `cancel:b-1:reason`…
  final List<String> calls = <String>[];

  /// Thrown by the next call only.
  Failure? failNext;

  /// Calls wait on it while set.
  Completer<void>? gate;

  BookingDetail booking = testBooking();
  BookingDetail? afterWrite;
  BookingQuote quoteResult = const BookingQuote(
    lines: <BookingLine>[],
    subtotal: '45000.00',
    discountTotal: '0.00',
    total: '45000.00',
    available: true,
    firstBookableDate: null,
  );
  final List<BookingRequest> quoted = <BookingRequest>[];
  final List<BookingRequest> created = <BookingRequest>[];
  Invoice invoiceResult = Invoice.fromJson(invoiceJson());
  Uint8List pdfBytes = Uint8List.fromList(<int>[37, 80, 68, 70]);

  /// Pages per tab, [pageSize] each.
  int pageSize = 20;

  Future<T> _enter<T>(String call, T Function() answer) async {
    calls.add(call);
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
    final Failure? failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
    return answer();
  }

  BookingDetail _written() => afterWrite ?? booking;

  @override
  Future<ApiPage<BookingCard>> list({
    required BookingTab tab,
    int page = 1,
    int limit = 20,
  }) =>
      _enter('list:${tab.apiValue}:$page', () {
        final List<BookingCard> all = tabs[tab] ?? <BookingCard>[];
        final int start = (page - 1) * pageSize;
        return ApiPage<BookingCard>(
          items: start >= all.length
              ? <BookingCard>[]
              : all.sublist(start, (start + pageSize).clamp(0, all.length)),
          page: page,
          totalPages: (all.length / pageSize).ceil(),
          total: all.length,
        );
      });

  @override
  Future<BookingDetail> detail(String id) => _enter('detail:$id', () => booking);

  @override
  Future<BookingQuote> quote(BookingRequest request) => _enter('quote', () {
        quoted.add(request);
        return quoteResult;
      });

  @override
  Future<BookingDetail> create(BookingRequest request) => _enter('create', () {
        created.add(request);
        return _written();
      });

  @override
  Future<BookingDetail> cancel(String id, {required String reason}) =>
      _enter('cancel:$id:$reason', _written);

  @override
  Future<BookingDetail> reschedule(
    String id, {
    required DateTime date,
    required String reason,
    String? startTime,
    String? endTime,
  }) =>
      _enter('reschedule:$id:${date.year}-${date.month}-${date.day}:$reason', _written);

  @override
  Future<BookingDetail> acceptReschedule(String id, String rescheduleId) =>
      _enter('accept:$rescheduleId', _written);

  @override
  Future<BookingDetail> rejectReschedule(String id, String rescheduleId) =>
      _enter('reject:$rescheduleId', _written);

  @override
  Future<BookingDetail> withdrawReschedule(String id, String rescheduleId) =>
      _enter('withdraw:$rescheduleId', _written);

  @override
  Future<BookingDetail> checkIn(String id) => _enter('checkIn:$id', _written);

  @override
  Future<Invoice> invoice(String id) => _enter('invoice:$id', () => invoiceResult);

  @override
  Future<Uint8List> invoicePdf(String id) => _enter('pdf:$id', () => pdfBytes);

  @override
  Future<void> review(String id, {required int rating, required String comment}) =>
      _enter('review:$id:$rating', () {});

  @override
  Future<BookingDisputeSummary> openDispute(
    String id, {
    required DisputeType type,
    required String description,
  }) =>
      _enter(
        'dispute:$id:${type.apiValue}',
        () => const BookingDisputeSummary(
          id: 'd-1',
          reference: 'DSP-000012',
          status: 'open',
          conversationId: null,
        ),
      );
}
