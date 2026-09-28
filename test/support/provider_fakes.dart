import 'dart:async';
import 'dart:typed_data';

import 'package:eventor/core/bookings/models/booking_card.dart';
import 'package:eventor/core/bookings/models/booking_detail.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/network/api_page.dart';
import 'package:eventor/core/provider/provider_repository.dart';

/// A document row as `/app/me/documents` sends it.
Map<String, Object?> documentJson(
  String type,
  String status, {
  String? reasonLabel,
  String? note,
}) =>
    <String, Object?>{
      'id': status == 'missing' ? null : 'doc-$type',
      'type': type,
      'label': type,
      'status': status,
      'fileUrl': null,
      'rejectReason': status == 'rejected' ? 'name_mismatch' : null,
      'rejectReasonLabel': reasonLabel,
      'rejectNote': note,
      'reviewedAt': status == 'approved' || status == 'rejected'
          ? '2026-03-05T10:00:00.000Z'
          : null,
      'submittedAt': status == 'missing' ? null : '2026-03-03T10:00:00.000Z',
      'resubmitted': false,
    };

/// The documents payload, one status per type in the API's order: national
/// ID, register, tax card.
Map<String, Object?> documentsJson(
  List<String> statuses, {
  String verificationStatus = 'pending',
}) {
  const List<String> types = <String>[
    'national_id',
    'commercial_register_or_artisan_card',
    'tax_card',
  ];
  return <String, Object?>{
    'verificationStatus': verificationStatus,
    'actionNeeded': statuses.any((String s) => s == 'missing' || s == 'rejected'),
    'maxFileSizeMb': 5,
    'acceptedTypes': <String>['application/pdf', 'image/jpeg'],
    'documents': <Map<String, Object?>>[
      for (int i = 0; i < 3; i++)
        documentJson(
          types[i],
          statuses[i],
          reasonLabel: statuses[i] == 'rejected' ? 'Details do not match the account' : null,
          note: statuses[i] == 'rejected' ? 'Send a card in the same name.' : null,
        ),
    ],
    'progress': <String, int>{},
  };
}

/// A request or booking on the provider's side.
Map<String, Object?> providerBookingJson({
  String id = 'req-1',
  String client = 'Nadia Kaci',
  String status = 'pending',
  String eventType = 'wedding',
  String eventDate = '2026-03-14',
  String createdAt = '2026-03-03T10:00:00.000Z',
  List<String>? allowedActions,
}) =>
    <String, Object?>{
      'id': id,
      'reference': 'EVT-2026-0142',
      'status': status,
      'disputeStatus': 'none',
      'eventType': eventType,
      'eventDate': eventDate,
      'startTime': '13:00',
      'endTime': '23:00',
      'title': 'Wedding photo & video coverage',
      'titleEn': 'Wedding photo & video coverage',
      'titleAr': 'تغطية زفاف',
      'serviceId': 'svc-1',
      'packId': null,
      'coverUrl': null,
      'wilaya': null,
      'guests': 150,
      'total': '71000.00',
      'counterparty': <String, Object?>{
        'id': 'client-1',
        'fullName': client,
        'avatarUrl': null,
        'businessName': null,
        'phone': null,
        'email': null,
      },
      'conversationId': null,
      'allowedActions': allowedActions ??
          (status == 'pending'
              ? <String>['accept', 'decline', 'message']
              : <String>['message']),
      'createdAt': createdAt,
    };

/// `GET /app/provider/home` for [state].
Map<String, Object?> providerHomeJson({
  String state = 'verified',
  bool acceptingBookings = true,
  List<Map<String, Object?>>? requests,
  List<Map<String, Object?>>? upcoming,
  List<String> documents = const <String>['missing', 'missing', 'missing'],
}) {
  final bool verified = state == 'verified';
  Map<String, Object?> step(String key, bool done, bool current) =>
      <String, Object?>{'key': key, 'done': done, 'current': current};
  final List<Map<String, Object?>> requestRows = requests ??
      (verified
          ? <Map<String, Object?>>[
              providerBookingJson(),
              providerBookingJson(id: 'req-2', client: 'Yacine Meddour', eventType: 'engagement'),
            ]
          : <Map<String, Object?>>[]);
  final List<Map<String, Object?>> upcomingRows = upcoming ??
      (verified
          ? <Map<String, Object?>>[
              providerBookingJson(id: 'up-1', client: 'Lila Hamadi', status: 'accepted'),
            ]
          : <Map<String, Object?>>[]);
  return <String, Object?>{
    'state': state,
    'businessName': 'Studio Lumière',
    'avatarUrl': null,
    'verificationStatus': verified ? 'verified' : state,
    'verificationSteps': <Map<String, Object?>>[
      step('account_created', true, false),
      step('documents_submitted', verified || state == 'rejected', !verified && state != 'rejected'),
      step('under_review', verified || state == 'rejected', false),
      step('approved', verified, state == 'rejected'),
    ],
    'documents': verified
        ? null
        : documentsJson(documents, verificationStatus: state),
    'acceptingBookings': acceptingBookings,
    'avgRating': '0.00',
    'ratingCount': 0,
    'completedBookingsCount': 0,
    'counts': <String, Object?>{
      'requests': requestRows.length,
      'upcoming': upcomingRows.length,
      'services': verified ? 1 : 0,
      'unreadMessages': 2,
      'unreadNotifications': 1,
    },
    'requests': requestRows,
    'upcoming': upcomingRows,
    'services': verified
        ? <Map<String, Object?>>[
            <String, Object?>{
              'id': 'svc-1',
              'title': 'Wedding photography',
              'titleEn': 'Wedding photography',
              'titleAr': 'تصوير الأعراس',
              'status': 'draft',
              'visibleInApp': false,
              'basePrice': '45000.00',
              'avgRating': '0.00',
              'ratingCount': 0,
              'bookingsCount': 0,
              'photosCount': 0,
              'coverUrl': null,
              'wilayas': <Object?>[],
            },
          ]
        : <Object?>[],
  };
}

/// P2's `AppBookingDetailDto` — [providerBookingJson] plus the detail's own
/// fields. [phone] is the client's, shown once accepted.
Map<String, Object?> providerBookingDetailJson({
  String id = 'req-1',
  String client = 'Nadia Kaci',
  String status = 'pending',
  String eventDate = '2026-03-14',
  String createdAt = '2026-03-03T10:00:00.000Z',
  List<String>? allowedActions,
  String? phone,
  String? cancelledBy,
  String? cancelReason,
  String? declineReason,
  bool checkedIn = false,
  bool otherCheckedIn = false,
  List<Map<String, Object?>> reschedules = const <Map<String, Object?>>[],
  List<Map<String, Object?>>? timeline,
}) {
  final Map<String, Object?> card = providerBookingJson(
    id: id,
    client: client,
    status: status,
    eventDate: eventDate,
    createdAt: createdAt,
    allowedActions: allowedActions,
  );
  return <String, Object?>{
    ...card,
    'counterparty': <String, Object?>{
      ...(card['counterparty']! as Map<String, Object?>),
      'phone': phone,
      'email': phone == null ? null : 'client@example.dz',
    },
    'locationText': 'Route de Chéraga',
    'communeName': 'Hydra',
    'clientNote': 'The hall is quite dark in the evening.',
    'lines': <Map<String, Object?>>[
      <String, Object?>{
        'id': 'l1',
        'kind': 'service',
        'label': 'Wedding photo & video coverage',
        'quantity': 1,
        'unitAmount': '71000.00',
        'amount': '71000.00',
      },
    ],
    'subtotal': '71000.00',
    'discountTotal': '0.00',
    'feePercent': '8.00',
    'cancellationPolicy': 'Cancel at least 7 days before the event.',
    'cancelReason': cancelReason,
    'cancelledBy': cancelledBy,
    'declineReason': declineReason,
    'provider': null,
    'timeline': timeline ??
        <Map<String, Object?>>[
          <String, Object?>{'type': 'created', 'toStatus': 'pending', 'actorLabel': client, 'reason': null, 'at': createdAt},
        ],
    'reschedules': reschedules,
    'invoice': null,
    'dispute': null,
    'checkedIn': checkedIn,
    'otherCheckedIn': otherCheckedIn,
    'reviewId': null,
    'reviewWindowOpen': false,
    'disputeWindowOpen': false,
  };
}

/// A reschedule row — the client's by default, waiting for the provider.
Map<String, Object?> providerRescheduleJson({
  String id = 'rs-1',
  String by = 'client',
  bool awaitingMe = true,
  String oldDate = '2026-03-14',
  String newDate = '2026-03-21',
}) =>
    <String, Object?>{
      'id': id,
      'status': 'pending',
      'oldDate': oldDate,
      'newDate': newDate,
      'newStartTime': '13:00',
      'newEndTime': '23:00',
      'reason': 'The hall had a problem with our date.',
      'proposedByRole': by,
      'awaitingMe': awaitingMe,
      'createdAt': '2026-03-06T11:02:00.000Z',
    };

/// `GET /app/provider/availability` for March 2026: the 7th booked by
/// another request, the 9th blocked, the 14th this booking's own.
Map<String, Object?> providerMonthJson({String ownBooking = 'req-1', int maxEventsPerDay = 1}) =>
    <String, Object?>{
      'providerId': 'prov-1',
      'month': '2026-03',
      'maxEventsPerDay': maxEventsPerDay,
      'days': <Map<String, Object?>>[
        for (int d = 1; d <= 31; d++)
          <String, Object?>{
            'date': '2026-03-${d.toString().padLeft(2, '0')}',
            'status': switch (d) {
              7 => 'booked',
              9 => 'blocked',
              14 => 'held',
              _ => 'free',
            },
            'items': <Map<String, Object?>>[
              if (d == 7 || d == 14)
                <String, Object?>{
                  'id': null,
                  'kind': d == 7 ? 'booked' : 'held',
                  'date': '2026-03-$d',
                  'startTime': null,
                  'endTime': null,
                  'service': null,
                  'booking': <String, Object?>{
                    'id': d == 7 ? 'other' : ownBooking,
                    'reference': 'EVT-1',
                    'status': 'accepted',
                  },
                  'note': null,
                  'removable': false,
                },
            ],
          },
      ],
    };

/// [ProviderRepository] answering a scripted home, scripted lists and
/// scripted bookings — each write changes them as the server would.
class FakeProviderRepository implements ProviderRepository {
  FakeProviderRepository({
    Map<String, Object?>? home,
    List<Map<String, Object?>> bookings = const <Map<String, Object?>>[],
  })  : homeJson = home ?? providerHomeJson(state: 'pending'),
        details = <String, Map<String, Object?>>{
          for (final Map<String, Object?> b in bookings) b['id']! as String: b,
        };

  /// What [home] answers — a new [ProviderHome] parsed from it each time.
  Map<String, Object?> homeJson;

  /// P2's bookings by id — what [booking] answers and the writes change.
  /// The lists ([bookings]) are made from them: pending → requests,
  /// accepted → upcoming, completed → past.
  final Map<String, Map<String, Object?>> details;

  /// What [availabilityMonth] answers.
  Map<String, Object?> monthJson = providerMonthJson();

  /// `home`, `list:<tab>:<page>`, `booking:<id>`, `accept:<id>`,
  /// `decline:<id>:<reason>`, `cancel:<id>:<reason>`,
  /// `reschedule:<id>:<date>:<start>-<end>:<reason>`,
  /// `acceptReschedule:<id>:<rid>` (and reject / withdraw), `checkIn:<id>`,
  /// `dispute:<id>:<type>`, `month:<yyyy-mm>`, `accepting:<bool>`.
  final List<String> calls = <String>[];

  /// Thrown by the next call only.
  Failure? failNext;

  /// When set, calls wait on it — for asserting the in-flight state.
  Completer<void>? gate;

  Future<void> _enter(String call) async {
    calls.add(call);
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
    final Failure? failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
  }

  List<Map<String, Object?>> get _requests =>
      (homeJson['requests']! as List<Object?>).cast<Map<String, Object?>>();

  @override
  Future<ProviderHome> home() async {
    await _enter('home');
    return ProviderHome.fromJson(homeJson);
  }

  @override
  Future<bool> setAcceptingBookings(bool accepting) async {
    await _enter('accepting:$accepting');
    homeJson = <String, Object?>{...homeJson, 'acceptingBookings': accepting};
    return accepting;
  }

  @override
  Future<ApiPage<BookingCard>> bookings({
    required ProviderBookingTab tab,
    int page = 1,
    int limit = 20,
  }) async {
    await _enter('list:${tab.name}:$page');
    final String status = switch (tab) {
      ProviderBookingTab.requests => 'pending',
      ProviderBookingTab.upcoming => 'accepted',
      ProviderBookingTab.past => 'completed',
    };
    final List<BookingCard> all = <BookingCard>[
      for (final Map<String, Object?> b in details.values)
        if (b['status'] == status) BookingCard.fromJson(b),
    ];
    final int start = (page - 1) * limit;
    return ApiPage<BookingCard>(
      items: start >= all.length ? <BookingCard>[] : all.sublist(start, (start + limit).clamp(0, all.length)),
      page: page,
      totalPages: (all.length / limit).ceil(),
      total: all.length,
    );
  }

  @override
  Future<ProviderBooking> booking(String bookingId) async {
    await _enter('booking:$bookingId');
    return ProviderBooking.fromJson(_detail(bookingId));
  }

  Map<String, Object?> _detail(String id) {
    final Map<String, Object?>? found = details[id];
    if (found != null) return found;
    // A request only the home lists: its detail, made on first use.
    for (final Map<String, Object?> row in _requests) {
      if (row['id'] != id) continue;
      final Map<String, Object?> party = row['counterparty']! as Map<String, Object?>;
      return details[id] = providerBookingDetailJson(id: id, client: party['fullName']! as String);
    }
    throw const ApiFailure(statusCode: 404, code: ApiErrorCode.bookingNotFound, message: 'The booking was not found.');
  }

  /// [id] with [changes], stored and parsed.
  ProviderBooking _update(String id, Map<String, Object?> changes) {
    final Map<String, Object?> updated = <String, Object?>{..._detail(id), ...changes};
    details[id] = updated;
    return ProviderBooking.fromJson(updated);
  }

  @override
  Future<ProviderBooking> accept(String bookingId) async {
    await _enter('accept:$bookingId');
    if (_requests.any((Map<String, Object?> r) => r['id'] == bookingId)) _move(bookingId, to: 'accepted');
    return _update(bookingId, <String, Object?>{
      'status': 'accepted',
      'allowedActions': <String>['message', 'cancel', 'reschedule'],
    });
  }

  @override
  Future<ProviderBooking> decline(String bookingId, {required String reason}) async {
    await _enter('decline:$bookingId:$reason');
    if (_requests.any((Map<String, Object?> r) => r['id'] == bookingId)) _move(bookingId, to: 'declined');
    return _update(bookingId, <String, Object?>{
      'status': 'declined',
      'declineReason': reason,
      'allowedActions': <String>['message'],
    });
  }

  @override
  Future<ProviderBooking> cancel(String bookingId, {required String reason}) async {
    await _enter('cancel:$bookingId:$reason');
    return _update(bookingId, <String, Object?>{
      'status': 'cancelled',
      'cancelledBy': 'provider',
      'cancelReason': reason,
      'allowedActions': <String>['message'],
    });
  }

  @override
  Future<ProviderBooking> reschedule(
    String bookingId, {
    required DateTime date,
    required String reason,
    String? startTime,
    String? endTime,
  }) async {
    final String day =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _enter('reschedule:$bookingId:$day:$startTime-$endTime:$reason');
    final Map<String, Object?> current = _detail(bookingId);
    if (current['status'] == 'pending') {
      return _update(bookingId, <String, Object?>{'eventDate': day, 'startTime': startTime, 'endTime': endTime});
    }
    return _update(bookingId, <String, Object?>{
      'reschedules': <Object?>[
        providerRescheduleJson(id: 'rs-mine', by: 'provider', awaitingMe: false, newDate: day),
      ],
      'allowedActions': <String>['message', 'cancel'],
    });
  }

  @override
  Future<ProviderBooking> acceptReschedule(String bookingId, String rescheduleId) async {
    await _enter('acceptReschedule:$bookingId:$rescheduleId');
    final Map<String, Object?> row = _pendingRow(bookingId);
    return _update(bookingId, <String, Object?>{
      'eventDate': row['newDate'],
      'reschedules': <Object?>[<String, Object?>{...row, 'status': 'accepted', 'awaitingMe': false}],
      'allowedActions': <String>['message', 'cancel', 'reschedule'],
    });
  }

  @override
  Future<ProviderBooking> rejectReschedule(String bookingId, String rescheduleId) async {
    await _enter('rejectReschedule:$bookingId:$rescheduleId');
    final Map<String, Object?> row = _pendingRow(bookingId);
    return _update(bookingId, <String, Object?>{
      'reschedules': <Object?>[<String, Object?>{...row, 'status': 'rejected', 'awaitingMe': false}],
      'allowedActions': <String>['message', 'cancel', 'reschedule'],
    });
  }

  @override
  Future<ProviderBooking> withdrawReschedule(String bookingId, String rescheduleId) async {
    await _enter('withdrawReschedule:$bookingId:$rescheduleId');
    final Map<String, Object?> row = _pendingRow(bookingId);
    return _update(bookingId, <String, Object?>{
      'reschedules': <Object?>[<String, Object?>{...row, 'status': 'cancelled'}],
      'allowedActions': <String>['message', 'cancel', 'reschedule'],
    });
  }

  Map<String, Object?> _pendingRow(String bookingId) =>
      ((_detail(bookingId)['reschedules']! as List<Object?>).cast<Map<String, Object?>>())
          .firstWhere((Map<String, Object?> r) => r['status'] == 'pending');

  @override
  Future<ProviderBooking> checkIn(String bookingId) async {
    await _enter('checkIn:$bookingId');
    final bool other = _detail(bookingId)['otherCheckedIn'] == true;
    return _update(bookingId, <String, Object?>{
      'checkedIn': true,
      if (other) 'status': 'completed',
      'allowedActions': <String>['message'],
    });
  }

  @override
  Future<BookingDisputeSummary> openDispute(
    String bookingId, {
    required ProviderDisputeType type,
    required String description,
  }) async {
    await _enter('dispute:$bookingId:${type.apiValue}');
    final Map<String, Object?> dispute = <String, Object?>{
      'id': 'd-1',
      'reference': 'DSP-000012',
      'status': 'open',
      'type': type.apiValue,
      'openedByMe': true,
      'createdAt': '2026-03-15T10:00:00.000Z',
    };
    _update(bookingId, <String, Object?>{'dispute': dispute, 'disputeStatus': 'open'});
    return BookingDisputeSummary.fromJson(dispute);
  }

  @override
  Future<Invoice> invoice(String bookingId) async {
    await _enter('invoice:$bookingId');
    throw const ApiFailure(statusCode: 404, code: ApiErrorCode.invoiceNotFound, message: 'No invoice.');
  }

  @override
  Future<Uint8List> invoicePdf(String bookingId) async {
    await _enter('invoicePdf:$bookingId');
    return Uint8List(0);
  }

  @override
  Future<ProviderCalendarMonth> availabilityMonth(DateTime month) async {
    await _enter('month:${month.year}-${month.month.toString().padLeft(2, '0')}');
    return ProviderCalendarMonth.fromJson(monthJson);
  }

  /// Takes the request off the list; an accepted one joins the upcoming.
  void _move(String id, {required String to}) {
    final List<Map<String, Object?>> requests = _requests;
    final Map<String, Object?> row =
        requests.firstWhere((Map<String, Object?> r) => r['id'] == id);
    homeJson = <String, Object?>{
      ...homeJson,
      'requests': requests.where((Map<String, Object?> r) => r['id'] != id).toList(),
      if (to == 'accepted')
        'upcoming': <Object?>[
          <String, Object?>{...row, 'status': 'accepted', 'allowedActions': <String>['message']},
          ...(homeJson['upcoming']! as List<Object?>),
        ],
    };
  }
}
