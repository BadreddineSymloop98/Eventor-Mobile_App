import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
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

/// [ProviderRepository] answering a scripted home.
class FakeProviderRepository implements ProviderRepository {
  FakeProviderRepository({Map<String, Object?>? home})
      : homeJson = home ??
            providerHomeJson(state: 'pending');

  /// What [home] answers — a new [ProviderHome] parsed from it each time.
  Map<String, Object?> homeJson;

  /// `home`, `accept:<id>`, `decline:<id>:<reason>`, `accepting:<bool>`.
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
  Future<void> accept(String bookingId) async {
    await _enter('accept:$bookingId');
    _move(bookingId, to: 'accepted');
  }

  @override
  Future<void> decline(String bookingId, {required String reason}) async {
    await _enter('decline:$bookingId:$reason');
    _move(bookingId, to: 'declined');
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
