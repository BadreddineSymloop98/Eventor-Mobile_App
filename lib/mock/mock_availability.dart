import '../core/availability/availability_repository.dart';
import '../core/budget/budget_repository.dart' show apiDate;
import '../core/errors/failure.dart';
import 'mock_backend.dart';
import 'mock_calendar_booking.dart';
import 'mock_catalog.dart';

/// A service's two titles, for the `service` of a block.
typedef MockServiceTitle = ({String en, String ar});

/// [AvailabilityRepository] over the mock backend: the provider's own blocks
/// in the `availabilityBlocks` store (per account email), and the shared
/// bookings — a pending request holds its day, an accepted booking takes it.
///
/// It keeps the live API's rules: blocks only for today or later
/// (`AVAILABILITY_DATE_PAST`), times both or neither, a service must be the
/// provider's own (`AVAILABILITY_SERVICE_INVALID`), a note of at most 255,
/// and only the blocks the provider added can be removed.
class MockAvailabilityRepository implements AvailabilityRepository {
  MockAvailabilityRepository(
    this._backend, {
    required this._bookings,
    required this._serviceIdsOf,
    this._serviceTitleOf,
  });

  static const String _storeName = 'availabilityBlocks';

  /// The store's id counter, beside the per-email lists — no email starts
  /// with `#`.
  static const String _nextIdKey = '#nextId';

  /// The seeded account whose calendar is drawn on P15.
  static const String seededProviderEmail = 'verified.provider@eventor.test';

  /// The live API's `maxEventsPerDay` for a one-event-a-day venue.
  static const int _maxEventsPerDay = 1;

  static final RegExp _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  final MockBackend _backend;
  final MockCalendarBookings _bookings;
  final Set<String> Function(MockAccount provider) _serviceIdsOf;
  final MockServiceTitle? Function(MockAccount provider, String serviceId)? _serviceTitleOf;

  @override
  Future<AvailabilityMonth> month(DateTime month) async {
    await _backend.delay();
    final MockAccount provider = _backend.requireProvider();
    final DateTime first = DateTime(month.year, month.month);
    final int length = DateTime(first.year, first.month + 1, 0).day;
    final List<Map<String, Object?>> blocks = _blocksOf(provider);
    final List<MockCalendarBooking> bookings = _bookings(provider);

    final List<Map<String, Object?>> days = <Map<String, Object?>>[];
    for (int d = 1; d <= length; d++) {
      final String date = apiDate(DateTime(first.year, first.month, d));
      final List<Map<String, Object?>> items = <Map<String, Object?>>[
        for (final MockCalendarBooking booking in bookings)
          if (booking.date == date) _bookingItem(booking),
        for (final Map<String, Object?> block in blocks)
          if (block['date'] == date) _blockItem(provider, block),
      ]..sort(_byTime);
      days.add(<String, Object?>{
        'date': date,
        'status': _status(items),
        'items': items,
      });
    }

    return AvailabilityMonth.fromJson(<String, Object?>{
      'providerId': provider.id,
      'month': apiMonth(first),
      'maxEventsPerDay': _maxEventsPerDay,
      'days': days,
    });
  }

  @override
  Future<ProviderDayItem> block(BlockRequest request) async {
    await _backend.delay();
    final MockAccount provider = _backend.requireProvider();

    // The body is validated before anything is looked up, as on the server.
    final String? start = request.startTime;
    final String? end = request.endTime;
    final String? note = request.note?.trim();
    final List<FieldError> invalid = <FieldError>[
      if (start != null && !_time.hasMatch(start))
        const FieldError(field: 'startTime', code: 'MATCHES', message: 'startTime must be HH:mm.'),
      if (end != null && !_time.hasMatch(end))
        const FieldError(field: 'endTime', code: 'MATCHES', message: 'endTime must be HH:mm.'),
      if ((start == null) != (end == null))
        FieldError(
          field: start == null ? 'startTime' : 'endTime',
          code: 'BOTH_OR_NEITHER',
          message: 'Send startTime and endTime together, or neither.',
        ),
      // An end equal to the start is not a slot.
      if (start != null && start == end)
        const FieldError(field: 'endTime', code: 'NOT_EQUAL', message: 'endTime must differ from startTime.'),
      if (note != null && note.length > BlockRequest.maxNote)
        const FieldError(field: 'note', code: 'MAX_LENGTH', message: 'note must be at most 255 characters.'),
    ];
    if (invalid.isNotEmpty) {
      throw ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.validationFailed,
        message: 'Some fields are invalid.',
        fieldErrors: invalid,
      );
    }

    final DateTime now = _backend.now;
    final DateTime day = DateTime(request.date.year, request.date.month, request.date.day);
    if (day.isBefore(DateTime(now.year, now.month, now.day))) {
      throw const ApiFailure(
        statusCode: 422,
        code: ApiErrorCode.availabilityDatePast,
        message: 'The date is in the past.',
      );
    }
    final String? serviceId = request.serviceId;
    if (serviceId != null && !_serviceIdsOf(provider).contains(serviceId)) {
      throw const ApiFailure(
        statusCode: 422,
        code: ApiErrorCode.availabilityServiceInvalid,
        message: 'The service does not belong to this provider.',
      );
    }

    final Map<String, Object?> block = <String, Object?>{
      'id': _nextId(),
      'date': apiDate(day),
      'startTime': start,
      'endTime': end,
      'serviceId': serviceId,
      'note': note == null || note.isEmpty ? null : note,
    };
    _blocksOf(provider).add(block);
    await _backend.saveStores();
    return ProviderDayItem.fromJson(_blockItem(provider, block));
  }

  @override
  Future<void> unblock(String id) async {
    await _backend.delay();
    final MockAccount provider = _backend.requireProvider();
    final List<Map<String, Object?>> own = _blocksOf(provider);
    final int index = own.indexWhere((Map<String, Object?> b) => b['id'] == id);
    if (index >= 0) {
      _rawBlocksOf(provider).remove(own[index]);
      await _backend.saveStores();
      return;
    }
    if (_bookings(provider).any((MockCalendarBooking b) => _bookingRowId(b) == id)) {
      throw const ApiFailure(
        statusCode: 409,
        code: ApiErrorCode.availabilityBlockNotRemovable,
        message: 'Only manual blocks can be removed; this day is held or booked by a booking.',
      );
    }
    final Map<String, Object?> store = _store();
    for (final MapEntry<String, Object?> entry in store.entries) {
      final Object? rows = entry.value;
      if (entry.key == provider.email || rows is! List<Object?>) continue;
      if (rows.whereType<Map<String, Object?>>().any((Map<String, Object?> b) => b['id'] == id)) {
        throw const ApiFailure(
          statusCode: 403,
          code: ApiErrorCode.notOwner,
          message: 'You do not own this item.',
        );
      }
    }
    throw const ApiFailure(
      statusCode: 404,
      code: ApiErrorCode.availabilityBlockNotFound,
      message: 'The availability block was not found.',
    );
  }

  // ------------------------------------------------------------- storage

  Map<String, Object?> _store() => _backend.store(_storeName, () => <String, Object?>{});

  /// The provider's stored list itself, seeded the first time — changed in
  /// place, then saved.
  List<Object?> _rawBlocksOf(MockAccount provider) =>
      _store().putIfAbsent(provider.email, () => _seed(provider))! as List<Object?>;

  List<Map<String, Object?>> _blocksOf(MockAccount provider) =>
      _rawBlocksOf(provider).whereType<Map<String, Object?>>().toList();

  /// The days [provider] blocked outright — whole day, every service — as
  /// `YYYY-MM-DD`. The booking mock greys them out on P4 and refuses a new
  /// date on one, as the live server would.
  Set<String> wholeDayBlocksOf(MockAccount provider) => <String>{
        for (final Map<String, Object?> block in _blocksOf(provider))
          if (block['startTime'] == null && block['serviceId'] == null)
            block['date']! as String,
      };

  String _nextId() {
    final Map<String, Object?> store = _store();
    final int next = (store[_nextIdKey] as num?)?.toInt() ?? 100;
    store[_nextIdKey] = next + 1;
    return 'mock-block-$next';
  }

  /// P15 as drawn for the seeded provider: a whole day blocked in a couple
  /// of days, and a time slot on one service next month, with a note.
  /// Everyone else starts with an empty calendar.
  List<Object?> _seed(MockAccount provider) {
    if (provider.email != seededProviderEmail) return <Object?>[];
    final DateTime now = _backend.now;
    final List<String> services = _catalogServiceIds(provider);
    return <Object?>[
      <String, Object?>{
        'id': 'mock-block-1',
        'date': apiDate(DateTime(now.year, now.month, now.day + 2)),
        'startTime': null,
        'endTime': null,
        'serviceId': null,
        'note': null,
      },
      <String, Object?>{
        'id': 'mock-block-2',
        'date': apiDate(DateTime(now.year, now.month + 1, 10)),
        'startTime': '14:00',
        'endTime': '18:00',
        'serviceId': services.isEmpty ? null : services.first,
        'note': 'Family wedding',
      },
    ];
  }

  // ------------------------------------------------------------ rendering

  /// A stored block as `AvailabilityBlockDto`.
  Map<String, Object?> _blockItem(MockAccount provider, Map<String, Object?> block) {
    final String? serviceId = block['serviceId'] as String?;
    return <String, Object?>{
      'id': block['id'],
      'kind': 'blocked',
      'date': block['date'],
      'startTime': block['startTime'],
      'endTime': block['endTime'],
      'service': serviceId == null ? null : _serviceRef(provider, serviceId),
      'booking': null,
      'note': block['note'],
      'removable': true,
    };
  }

  /// A live booking as the row that holds (`held`) or takes (`booked`) its
  /// day. The API's booking ref carries no client name.
  Map<String, Object?> _bookingItem(MockCalendarBooking booking) {
    final String? serviceId = booking.serviceId;
    return <String, Object?>{
      'id': _bookingRowId(booking),
      'kind': booking.isAccepted ? 'booked' : 'held',
      'date': booking.date,
      'startTime': booking.startTime,
      'endTime': booking.endTime,
      'service': serviceId == null
          ? null
          : <String, Object?>{
              'id': serviceId,
              'titleEn': booking.titleEn ?? '',
              'titleAr': booking.titleAr ?? booking.titleEn ?? '',
            },
      'booking': <String, Object?>{
        'id': booking.id,
        'reference': booking.reference,
        'status': booking.isAccepted ? 'accepted' : 'pending',
      },
      'note': null,
      'removable': false,
    };
  }

  static String _bookingRowId(MockCalendarBooking booking) => 'mock-slot-${booking.id}';

  Map<String, Object?> _serviceRef(MockAccount provider, String serviceId) {
    final MockServiceTitle? title =
        _serviceTitleOf?.call(provider, serviceId) ?? _catalogTitle(provider, serviceId);
    return <String, Object?>{
      'id': serviceId,
      'titleEn': title?.en ?? '',
      'titleAr': title?.ar ?? title?.en ?? '',
    };
  }

  /// The const catalog's services for the provider — the same ids the
  /// services mock seeds, so a block's title reads without it.
  List<Map<String, Object?>> _catalogServices(MockAccount provider) =>
      MockCatalogLookups(_backend, languageCode: () => 'en').providerServices(provider.businessName);

  List<String> _catalogServiceIds(MockAccount provider) => <String>[
        for (final Map<String, Object?> s in _catalogServices(provider))
          if (s['id'] case final String id) id,
      ];

  MockServiceTitle? _catalogTitle(MockAccount provider, String serviceId) {
    for (final Map<String, Object?> s in _catalogServices(provider)) {
      if (s['id'] == serviceId) {
        return (en: s['titleEn'] as String? ?? '', ar: s['titleAr'] as String? ?? '');
      }
    }
    return null;
  }

  /// Whole-day rows first, then by start time.
  static int _byTime(Map<String, Object?> a, Map<String, Object?> b) {
    final String first = a['startTime'] as String? ?? '';
    final String second = b['startTime'] as String? ?? '';
    return first.compareTo(second);
  }

  /// The server's precedence: booked > held > blocked (whole day, every
  /// service) > partial (a time range or one service) > free.
  static String _status(List<Map<String, Object?>> items) {
    bool has(String kind) => items.any((Map<String, Object?> i) => i['kind'] == kind);
    if (has('booked')) return 'booked';
    if (has('held')) return 'held';
    final Iterable<Map<String, Object?>> blocks =
        items.where((Map<String, Object?> i) => i['kind'] == 'blocked');
    if (blocks.any((Map<String, Object?> b) => b['startTime'] == null && b['service'] == null)) {
      return 'blocked';
    }
    return blocks.isEmpty ? 'free' : 'partial';
  }
}
