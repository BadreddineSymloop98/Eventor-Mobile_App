import '../core/budget/budget_repository.dart' show apiDate;
import '../core/errors/failure.dart';
import '../core/models/account.dart';
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

/// [ProviderRepository] on the in-app [MockBackend] with the live rules:
/// the home follows the verification status, only a verified provider can
/// accept, a decline needs a reason of at most 60 characters, and only a
/// pending request can be answered.
class MockProviderRepository implements ProviderRepository {
  MockProviderRepository(this._backend, this._lookups, {this._messaging});

  final MockBackend _backend;
  final MockCatalogLookups _lookups;

  /// Where the unread counts come from, when given.
  final MockMessagingStore? _messaging;

  static const int _maxReason = 60;

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

    final List<Map<String, Object?>> services =
        _lookups.providerServices(account.businessName);
    final List<Map<String, Object?>> bookings =
        verified ? _bookings(account) : <Map<String, Object?>>[];
    final String today = apiDate(now);
    final List<Map<String, Object?>> requests = bookings
        .where((Map<String, Object?> b) => b['status'] == 'pending')
        .toList()
      ..sort(
        (Map<String, Object?> a, Map<String, Object?> b) =>
            (b['createdAt']! as String).compareTo(a['createdAt']! as String),
      );
    final List<Map<String, Object?>> upcoming = bookings
        .where(
          (Map<String, Object?> b) =>
              b['status'] == 'accepted' &&
              (b['eventDate']! as String).compareTo(today) >= 0,
        )
        .toList()
      ..sort(
        (Map<String, Object?> a, Map<String, Object?> b) =>
            (a['eventDate']! as String).compareTo(b['eventDate']! as String),
      );

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
  Future<void> accept(String bookingId) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    if (account.verificationStatus != VerificationStatus.verified) {
      throw const ApiFailure(
        statusCode: 422,
        code: ApiErrorCode.providerNotVerified,
        message:
            'Your profile is still being reviewed. You can publish and accept bookings once it is approved.',
      );
    }
    _pending(bookingId, to: 'accepted')
      ..['status'] = 'accepted'
      ..['allowedActions'] = <String>['message', 'cancel'];
    await _backend.saveProvider();
  }

  @override
  Future<void> decline(String bookingId, {required String reason}) async {
    await _backend.delay();
    _backend.requireProvider();
    final String text = reason.trim();
    if (text.isEmpty || text.length > _maxReason) {
      throw const ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.validationFailed,
        message: 'Some fields are invalid.',
        fieldErrors: <FieldError>[
          FieldError(field: 'reason', code: 'INVALID', message: 'Invalid reason.'),
        ],
      );
    }
    _pending(bookingId, to: 'declined')
      ..['status'] = 'declined'
      ..['allowedActions'] = <String>[]
      ..['declineReason'] = text;
    await _backend.saveProvider();
  }

  /// The provider's pending request [id], or the API's refusal.
  Map<String, Object?> _pending(String id, {required String to}) {
    for (final Map<String, Object?> booking
        in _bookings(_backend.requireProvider())) {
      if (booking['id'] != id) continue;
      if (booking['status'] != 'pending') {
        throw ApiFailure(
          statusCode: 409,
          code: ApiErrorCode.bookingInvalidTransition,
          message: 'A booking cannot move from "${booking['status']}" to "$to".',
        );
      }
      return booking;
    }
    throw const ApiFailure(
      statusCode: 404,
      code: ApiErrorCode.bookingNotFound,
      message: 'The booking was not found.',
    );
  }

  /// The provider's bookings, seeded as 21 draws them the first time.
  List<Map<String, Object?>> _bookings(MockAccount account) =>
      _backend.providerBookings(
        () => _seedBookings(
          account,
          _lookups.providerServices(account.businessName),
          _backend.now,
          category: _lookups.category(account.categoryId),
        ),
      );

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

  /// 21 as drawn: two requests waiting for an answer, two bookings ahead.
  static List<Map<String, Object?>> _seedBookings(
    MockAccount account,
    List<Map<String, Object?>> services,
    DateTime now, {
    Map<String, Object?>? category,
  }) {
    Map<String, Object?> booking({
      required int n,
      required String client,
      required String eventType,
      required int inDays,
      required String status,
      required Duration requestedAgo,
    }) {
      final Map<String, Object?> service =
          services.isEmpty ? const <String, Object?>{} : services[n % services.length];
      final DateTime date = DateTime(now.year, now.month, now.day + inDays);
      return <String, Object?>{
        'id': 'mock-request-${account.id}-$n',
        'reference': 'EVT-2026-${(140 + n).toString().padLeft(4, '0')}',
        'status': status,
        'disputeStatus': 'none',
        'eventType': eventType,
        'eventDate': apiDate(date),
        'startTime': '13:00',
        'endTime': '23:00',
        'title': service['titleEn'] ?? account.businessName,
        'titleEn': service['titleEn'] ?? account.businessName,
        'titleAr': service['titleAr'] ?? account.businessName,
        'serviceId': service['id'],
        'packId': null,
        // The provider's own category — every mock service is in it.
        'category': category,
        'coverUrl': null,
        'wilaya': null,
        'guests': 150,
        'total': service['basePrice'] ?? '0.00',
        'counterparty': <String, Object?>{
          'id': 'mock-client-$n',
          'fullName': client,
          'avatarUrl': null,
          'businessName': null,
          'phone': null,
          'email': null,
        },
        'conversationId': null,
        'allowedActions': status == 'pending'
            ? <String>['accept', 'decline', 'message']
            : <String>['message', 'cancel'],
        'createdAt': now.subtract(requestedAgo).toUtc().toIso8601String(),
      };
    }

    return <Map<String, Object?>>[
      booking(
        n: 1,
        client: 'Nadia Kaci',
        eventType: 'wedding',
        inDays: 18,
        status: 'pending',
        requestedAgo: const Duration(hours: 1),
      ),
      booking(
        n: 2,
        client: 'Yacine Meddour',
        eventType: 'engagement',
        inDays: 24,
        status: 'pending',
        requestedAgo: const Duration(hours: 36),
      ),
      booking(
        n: 3,
        client: 'Lila Hamadi',
        eventType: 'engagement',
        inDays: 25,
        status: 'accepted',
        requestedAgo: const Duration(days: 6),
      ),
      booking(
        n: 4,
        client: 'Sofiane Brahimi',
        eventType: 'wedding',
        inDays: 33,
        status: 'accepted',
        requestedAgo: const Duration(days: 9),
      ),
    ];
  }
}
