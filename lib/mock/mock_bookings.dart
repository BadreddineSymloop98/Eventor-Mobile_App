part of 'mock_catalog.dart';

/// Days from today to the seeded client's event — their bookings and their
/// budget share the date.
const int mockEventInDays = 21;

/// One day in eleven that shows as available is "taken by another client"
/// between loading the calendar and sending the request — B1b, on demand.
bool _takenMeanwhile(String id, DateTime day) =>
    (_MockCatalog._seed(id) + day.day * 7 + day.month * 13 + day.year) % 11 == 7;

/// The maps of a stored list, typed.
Iterable<Map<String, Object?>> _rows(Object? list) =>
    (list! as List<Object?>).cast<Map<String, Object?>>();

String _iso(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms).toUtc().toIso8601String();

DateTime _day(Object? apiDay) => DateTime.parse(apiDay! as String);

/// The stored booking records of the signed-in client, and how the live API
/// renders and changes them. A record keeps ids and English/Arabic pairs
/// only; each read renders it in the request's language, so switching
/// language re-labels every booking.
class _MockBookings {
  _MockBookings(this._catalog);

  final _MockCatalog _catalog;

  MockBackend get _backend => _catalog._backend;
  bool get _isArabic => _catalog._isArabic;

  // --------------------------------------------------------------- store

  List<Map<String, Object?>> _records() {
    final MockAccount account = _backend.requireSession();
    if (account.role != UserRole.client) {
      throw const ApiFailure(
        statusCode: 403,
        code: ApiErrorCode.forbiddenRole,
        message: 'Your account role cannot access this.',
      );
    }
    final List<Map<String, Object?>> records =
        _backend.clientBookings(_seed);
    records.forEach(_settle);
    return records;
  }

  /// The client's bookings as `AppBookingDetailDto`s — cards read the same
  /// map. Empty for anyone but a signed-in client.
  List<Map<String, Object?>> rendered() {
    final MockAccount? account = _backend.sessionAccount;
    if (account == null || account.role != UserRole.client) {
      return <Map<String, Object?>>[];
    }
    return _records().map(render).toList();
  }

  Map<String, Object?> _record(String id) {
    for (final Map<String, Object?> r in _records()) {
      if (r['id'] == id) return r;
    }
    throw const ApiFailure(
      statusCode: 404,
      code: ApiErrorCode.bookingNotFound,
      message: 'The booking was not found.',
    );
  }

  /// Whether the signed-in client already holds [day] with [serviceId] —
  /// their own request makes the provider's day busy, as live.
  bool heldByMe(String serviceId, DateTime day) {
    final MockAccount? account = _backend.sessionAccount;
    if (account == null || account.role != UserRole.client) return false;
    for (final Map<String, Object?> r in _backend.clientBookings(_seed)) {
      final String status = r['status']! as String;
      if (status != 'pending' && status != 'accepted') continue;
      final Map<String, Object?>? pack = _MockCatalog._packs[r['packId']];
      final bool books = r['serviceId'] == serviceId ||
          (pack != null &&
              (pack['items']! as List<Object?>).contains(serviceId));
      final DateTime held = _day(r['eventDate']);
      if (books &&
          held.year == day.year &&
          held.month == day.month &&
          held.day == day.day) {
        return true;
      }
    }
    return false;
  }

  /// What the server's jobs would have done by now: an accepted booking is
  /// completed 72 h after its event unless a dispute holds it.
  void _settle(Map<String, Object?> r) {
    if (r['status'] != 'accepted' || r['dispute'] != null) return;
    final DateTime closes = _day(r['eventDate']).add(const Duration(days: 4));
    if (_backend.now.isBefore(closes)) return;
    r['status'] = 'completed';
    r['completedAt'] = closes.millisecondsSinceEpoch;
    _timeline(r, 'completed', at: closes);
  }

  void _timeline(
    Map<String, Object?> r,
    String type, {
    String? by,
    String? reason,
    DateTime? at,
  }) {
    (r['timeline']! as List<Object?>).add(<String, Object?>{
      'type': type,
      'by': by,
      'reason': reason,
      'at': (at ?? _backend.now).millisecondsSinceEpoch,
    });
  }

  // --------------------------------------------------------------- seeds

  /// The seeded client's bookings: one per state the booking screens draw.
  /// Three sit on the seeded budget's lines; the rest cover B4a–B4d, B6a
  /// and B7. Other clients start with none.
  List<Map<String, Object?>> _seed(MockAccount account) {
    if (account.email != 'client@eventor.test') return <Map<String, Object?>>[];
    final DateTime now = _backend.now;
    final DateTime today = DateTime(now.year, now.month, now.day);
    DateTime inDays(int days) => DateTime(today.year, today.month, today.day + days);
    int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch;
    final String? commune = (mockCommunes[16] ?? const <Map<String, Object?>>[])
        .firstOrNull?['id'] as String?;

    Map<String, Object?> record({
      required String id,
      required String reference,
      required int service,
      required int inDaysFromToday,
      required String status,
      String? packId,
      int guests = 150,
      String startTime = '13:00',
      String? endTime = '23:00',
      Map<String, int> extras = const <String, int>{},
      Duration createdAgo = const Duration(days: 30),
    }) {
      final Map<String, Object?> s = mockCatalogServices[service];
      return <String, Object?>{
        'id': id,
        'reference': reference,
        'status': status,
        'serviceId': packId == null ? s['id'] : null,
        'packId': packId,
        'eventType': 'wedding',
        'eventDate': apiDate(inDays(inDaysFromToday)),
        'startTime': startTime,
        'endTime': endTime,
        'guests': guests,
        'wilayaCode': 16,
        'communeId': commune,
        'locationText': 'Salle Yasmine, Route de Chéraga',
        'clientNote': 'The ceremony starts at 15:00.',
        'extras': extras,
        'createdAt': ago(createdAgo),
        'timeline': <Object?>[
          <String, Object?>{'type': 'created', 'by': 'client', 'at': ago(createdAgo)},
        ],
        'reschedules': <Object?>[],
        'checkedIn': false,
        'otherCheckedIn': false,
      };
    }

    void accepted(Map<String, Object?> r, {Duration after = const Duration(hours: 2)}) {
      final int created = r['createdAt']! as int;
      final int at = created + after.inMilliseconds;
      (r['timeline']! as List<Object?>).add(
        <String, Object?>{'type': 'accepted', 'by': 'provider', 'at': at},
      );
      r['acceptedAt'] = at;
      r['invoiceNumber'] =
          'INV-${now.year}-${(r['reference']! as String).substring(4)}';
    }

    final Map<String, Object?> lumiere = record(
      id: 'mock-booking-1',
      reference: 'EVT-002041',
      service: 0,
      inDaysFromToday: mockEventInDays,
      status: 'accepted',
      extras: <String, int>{'${mockCatalogServices[0]['id']}-x1': 1},
    );
    accepted(lumiere);

    final Map<String, Object?> pending = record(
      id: 'mock-booking-2',
      reference: 'EVT-002050',
      service: 4,
      inDaysFromToday: 45,
      status: 'pending',
      guests: 120,
      createdAgo: const Duration(hours: 3),
    );

    final Map<String, Object?> proposal = record(
      id: 'mock-booking-3',
      reference: 'EVT-002031',
      service: 2,
      inDaysFromToday: mockEventInDays,
      status: 'accepted',
    );
    accepted(proposal);
    (proposal['reschedules']! as List<Object?>).add(<String, Object?>{
      'id': 'mock-reschedule-1',
      'status': 'pending',
      'oldDate': proposal['eventDate'],
      'newDate': apiDate(inDays(mockEventInDays + 7)),
      'newStartTime': '13:00',
      'newEndTime': '23:00',
      'reason':
          'A wedding I had booked first was moved to that day. Same price, same team — sorry for the change.',
      'by': 'provider',
      'createdAt': ago(const Duration(days: 1)),
    });

    final Map<String, Object?> decoration = record(
      id: 'mock-booking-4',
      reference: 'EVT-002044',
      service: 16,
      inDaysFromToday: mockEventInDays,
      status: 'accepted',
      startTime: '09:00',
      endTime: '13:00',
    );
    accepted(decoration);

    final Map<String, Object?> completed = record(
      id: 'mock-booking-5',
      reference: 'EVT-001987',
      service: 6,
      inDaysFromToday: -12,
      status: 'completed',
      createdAgo: const Duration(days: 60),
    );
    accepted(completed);
    final DateTime completedAt = inDays(-11);
    completed['completedAt'] = completedAt.millisecondsSinceEpoch;
    completed['checkedIn'] = true;
    completed['otherCheckedIn'] = true;
    (completed['timeline']! as List<Object?>).add(<String, Object?>{
      'type': 'completed',
      'by': 'client',
      'at': completedAt.millisecondsSinceEpoch,
    });

    final Map<String, Object?> cancelled = record(
      id: 'mock-booking-6',
      reference: 'EVT-002052',
      service: 11,
      inDaysFromToday: mockEventInDays,
      status: 'cancelled',
    );
    accepted(cancelled);
    cancelled['cancelReason'] = 'The venue changed, we moved the date.';
    cancelled['cancelledBy'] = 'client';
    (cancelled['timeline']! as List<Object?>).add(<String, Object?>{
      'type': 'cancelled',
      'by': 'client',
      'reason': cancelled['cancelReason'],
      'at': ago(const Duration(days: 20)),
    });

    final Map<String, Object?> declined = record(
      id: 'mock-booking-7',
      reference: 'EVT-002057',
      service: 8,
      inDaysFromToday: 30,
      status: 'declined',
      createdAgo: const Duration(days: 4),
    );
    declined['declineReason'] = 'Already booked for another wedding that day.';
    (declined['timeline']! as List<Object?>).add(<String, Object?>{
      'type': 'declined',
      'by': 'provider',
      'reason': declined['declineReason'],
      'at': ago(const Duration(days: 4)) + const Duration(hours: 4).inMilliseconds,
    });

    final Map<String, Object?> checkIn = record(
      id: 'mock-booking-8',
      reference: 'EVT-002019',
      service: 10,
      inDaysFromToday: -1,
      status: 'accepted',
    );
    accepted(checkIn);
    // The provider has already said "All good": the client's tap closes it.
    checkIn['otherCheckedIn'] = true;

    final Map<String, Object?> pack = record(
      id: 'mock-booking-9',
      reference: 'EVT-002060',
      service: 0,
      inDaysFromToday: 60,
      status: 'accepted',
      packId: mockCatalogPacks[1]['id']! as String,
    );
    accepted(pack);

    return <Map<String, Object?>>[
      lumiere,
      pending,
      proposal,
      decoration,
      completed,
      cancelled,
      declined,
      checkIn,
      pack,
    ];
  }

  // -------------------------------------------------------------- pricing

  /// The priced lines the live API would build: the service at its price
  /// type's quantity plus the extras, or a pack's services with the saving
  /// as a discount line.
  Map<String, Object?> _price({
    String? serviceId,
    String? packId,
    String? startTime,
    String? endTime,
    int? guests,
    Map<String, int> extras = const <String, int>{},
  }) {
    final List<Map<String, Object?>> lines = <Map<String, Object?>>[];
    void line(String kind, String en, String ar, int quantity, int unitCents) {
      lines.add(<String, Object?>{
        'id': '',
        'kind': kind,
        'label': _isArabic && ar.isNotEmpty ? ar : en,
        'quantity': quantity,
        'unitAmount': _money(unitCents),
        'amount': _money(unitCents * quantity),
      });
    }

    if (serviceId != null) {
      final Map<String, Object?> s = _MockCatalog._services[serviceId]!;
      final int quantity = switch (s['priceType']) {
        'per_hour' => _hours(startTime, endTime),
        'per_person' => guests == null || guests < 1 ? 1 : guests,
        _ => 1,
      };
      line(
        'service',
        s['titleEn']! as String,
        s['titleAr']! as String,
        quantity,
        _cents(s['basePrice']! as String),
      );
      for (final Object? e in s['extras']! as List<Object?>) {
        final Map<String, Object?> extra = e! as Map<String, Object?>;
        final int count = extras[extra['id']] ?? 0;
        if (count > 0) {
          line(
            'extra',
            extra['nameEn']! as String,
            extra['nameAr']! as String,
            count,
            _cents(extra['price']! as String),
          );
        }
      }
    } else {
      final Map<String, Object?> k = _MockCatalog._packs[packId]!;
      for (final Object? id in k['items']! as List<Object?>) {
        final Map<String, Object?> s = _MockCatalog._services[id]!;
        line(
          'pack_service',
          s['titleEn']! as String,
          s['titleAr']! as String,
          1,
          _cents(s['basePrice']! as String),
        );
      }
      // The pack's price is the contract: the discount is whatever brings
      // the items down to it.
      int items = 0;
      for (final Object? id in k['items']! as List<Object?>) {
        items += _cents(_MockCatalog._services[id]!['basePrice']! as String);
      }
      final int saving = items - _cents(k['price']! as String);
      if (saving > 0) {
        line('discount', 'Pack saving', 'توفير الباقة', 1, -saving);
      }
    }
    int subtotal = 0;
    int discount = 0;
    for (final Map<String, Object?> l in lines) {
      final int amount = _cents(l['amount']! as String);
      if (amount < 0) {
        discount -= amount;
      } else {
        subtotal += amount;
      }
    }
    return <String, Object?>{
      'lines': lines,
      'subtotal': _money(subtotal),
      'discountTotal': _money(discount),
      'total': _money(subtotal - discount),
    };
  }

  static int _hours(String? start, String? end) {
    int minutes(String hm) {
      final List<String> p = hm.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    if (start == null || end == null) return 1;
    int span = minutes(end) - minutes(start);
    if (span <= 0) span += 24 * 60;
    return (span / 60).ceil();
  }

  static String _money(int cents) {
    final String sign = cents < 0 ? '-' : '';
    final int abs = cents.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------ rendering

  Map<String, Object?> render(Map<String, Object?> r) {
    final String? serviceId = r['serviceId'] as String?;
    final String? packId = r['packId'] as String?;
    final Map<String, Object?>? service = _MockCatalog._services[serviceId];
    final Map<String, Object?>? pack = _MockCatalog._packs[packId];
    final String providerId =
        (service?['providerId'] ?? pack?['providerId'])! as String;
    final Map<String, Object?> provider = _MockCatalog._providers[providerId]!;
    final String business = provider['businessName']! as String;
    final String status = r['status']! as String;
    final bool contactOpen = status == 'accepted' || status == 'completed';
    final String titleEn =
        (service?['titleEn'] ?? pack?['nameEn'])! as String;
    final String titleAr =
        (service?['titleAr'] ?? pack?['nameAr'])! as String;
    final List<String> photos =
        _MockCatalog._files(service ?? pack!);
    final Map<String, Object?> price = _price(
      serviceId: serviceId,
      packId: packId,
      startTime: r['startTime'] as String?,
      endTime: r['endTime'] as String?,
      guests: r['guests'] as int?,
      extras: <String, int>{
        for (final MapEntry<String, Object?> e
            in (r['extras'] as Map<String, Object?>? ?? const <String, Object?>{})
                .entries)
          e.key: (e.value! as num).toInt(),
      },
    );
    final Map<String, Object?>? dispute = r['dispute'] as Map<String, Object?>?;
    final int? completedAt = r['completedAt'] as int?;
    final DateTime now = _backend.now;
    final bool reviewWindowOpen = status == 'completed' &&
        completedAt != null &&
        r['reviewId'] == null &&
        (dispute == null || dispute['status'] == 'resolved') &&
        !now.isBefore(
          DateTime.fromMillisecondsSinceEpoch(completedAt)
              .add(const Duration(hours: 24)),
        ) &&
        now.isBefore(
          DateTime.fromMillisecondsSinceEpoch(completedAt)
              .add(const Duration(days: 60)),
        );
    final String? invoiceNumber = r['invoiceNumber'] as String?;
    final MockAccount account = _backend.requireSession();

    String? communeName() {
      for (final Map<String, Object?> c
          in mockCommunes[r['wilayaCode']] ?? const <Map<String, Object?>>[]) {
        if (c['id'] == r['communeId']) {
          return (_isArabic ? c['nameAr'] : c['nameEn']) as String?;
        }
      }
      return null;
    }

    String? actor(Object? by) => switch (by) {
          'provider' => business,
          'client' => account.fullName,
          _ => null,
        };

    return <String, Object?>{
      'id': r['id'],
      'reference': r['reference'],
      'status': status,
      'disputeStatus': dispute == null
          ? 'none'
          : dispute['status'] == 'resolved' || dispute['status'] == 'closed'
              ? 'resolved'
              : 'open',
      'eventType': r['eventType'],
      'eventDate': r['eventDate'],
      'startTime': r['startTime'],
      'endTime': r['endTime'],
      'title': _isArabic ? titleAr : titleEn,
      'titleEn': titleEn,
      'titleAr': titleAr,
      'serviceId': serviceId,
      'packId': packId,
      'category': service == null ? null : _catalog._categoryRef(service['categoryId']),
      'coverUrl': photos.isEmpty ? null : _photoUrl(photos.first),
      'wilaya': _MockCatalog._wilayaRef((r['wilayaCode']! as num).toInt()),
      'guests': r['guests'],
      'total': price['total'],
      'counterparty': <String, Object?>{
        'id': providerId,
        'fullName': business,
        'avatarUrl': null,
        'businessName': business,
        'phone': contactOpen ? _phoneOf(providerId) : null,
        'email': null,
      },
      'conversationId': null,
      'allowedActions': _actions(r, reviewWindowOpen: reviewWindowOpen),
      'createdAt': _iso(r['createdAt']! as int),
      'locationText': r['locationText'],
      'communeName': communeName(),
      'clientNote': r['clientNote'],
      'lines': price['lines'],
      'subtotal': price['subtotal'],
      'discountTotal': price['discountTotal'],
      'feePercent': '8.00',
      'cancellationPolicy': service == null
          ? null
          : _isArabic
              ? service['cancellationAr']
              : service['cancellationEn'],
      'cancelReason': r['cancelReason'],
      'cancelledBy': r['cancelledBy'],
      'declineReason': r['declineReason'],
      'provider': _catalog.providerSummary(providerId),
      'timeline': <Map<String, Object?>>[
        for (final Map<String, Object?> e in _rows(r['timeline']))
          <String, Object?>{
            'type': e['type'],
            'toStatus': switch (e['type']) {
              'created' => 'pending',
              'accepted' || 'declined' || 'cancelled' || 'completed' => e['type'],
              _ => null,
            },
            'actorLabel': actor(e['by']),
            'reason': e['reason'],
            'at': _iso(e['at']! as int),
          },
      ],
      'reschedules': <Map<String, Object?>>[
        for (final Map<String, Object?> x in _rows(r['reschedules']))
          <String, Object?>{
            'id': x['id'],
            'status': x['status'],
            'oldDate': x['oldDate'],
            'newDate': x['newDate'],
            'newStartTime': x['newStartTime'],
            'newEndTime': x['newEndTime'],
            'reason': x['reason'],
            'proposedByRole': x['by'],
            'awaitingMe': x['status'] == 'pending' && x['by'] == 'provider',
            'createdAt': _iso(x['createdAt']! as int),
          },
      ],
      'invoice': invoiceNumber == null
          ? null
          : <String, Object?>{
              'id': 'mock-invoice-${r['id']}',
              'number': invoiceNumber,
              'version': 1,
              'total': price['total'],
              'voided': status == 'cancelled',
              'pdfPath': '/api/v1/app/bookings/${r['id']}/invoice.pdf',
              'issuedAt': _iso((r['acceptedAt'] ?? r['createdAt'])! as int),
            },
      'dispute': dispute == null
          ? null
          : <String, Object?>{
              'id': dispute['id'],
              'reference': dispute['reference'],
              'status': dispute['status'],
              'type': dispute['type'],
              'openedByMe': true,
              'createdAt': _iso(dispute['createdAt']! as int),
            },
      'checkedIn': r['checkedIn'] ?? false,
      'otherCheckedIn': r['otherCheckedIn'] ?? false,
      'reviewId': r['reviewId'],
      'reviewWindowOpen': reviewWindowOpen,
      'disputeWindowOpen': _disputeWindowOpen(r),
    };
  }

  /// A stable Algerian mobile number per provider — shown once accepted.
  static String _phoneOf(String providerId) {
    final int n = _MockCatalog._seed(providerId) % 100000000;
    return '+2137${n.toString().padLeft(8, '0')}';
  }

  bool _disputeWindowOpen(Map<String, Object?> r) {
    final String status = r['status']! as String;
    if (status != 'accepted' && status != 'completed') return false;
    final Map<String, Object?>? dispute = r['dispute'] as Map<String, Object?>?;
    if (dispute != null && dispute['status'] != 'resolved') return false;
    final DateTime event = _day(r['eventDate']);
    final DateTime now = _backend.now;
    return !now.isBefore(event) &&
        now.isBefore(event.add(const Duration(days: 4)));
  }

  /// `allowedActions` for the client, as the status rules give them.
  List<String> _actions(
    Map<String, Object?> r, {
    required bool reviewWindowOpen,
  }) {
    final String status = r['status']! as String;
    final DateTime now = _backend.now;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final bool passed = _day(r['eventDate']).isBefore(today);
    final bool proposalOpen = (r['reschedules']! as List<Object?>).any(
      (Object? x) => (x! as Map<String, Object?>)['status'] == 'pending',
    );
    final bool awaitingMe = _rows(r['reschedules']).any(
      (Map<String, Object?> x) =>
          x['status'] == 'pending' && x['by'] == 'provider',
    );
    return <String>[
      'message',
      if (status == 'pending') ...<String>['cancel', 'reschedule'],
      if (status == 'accepted' && !passed) ...<String>[
        'cancel',
        if (!proposalOpen) 'reschedule',
        if (awaitingMe) 'respond_reschedule',
      ],
      if (status == 'accepted' && passed && r['checkedIn'] != true && r['dispute'] == null)
        'check_in',
      if ((status == 'accepted' || status == 'completed') && r['invoiceNumber'] != null)
        'invoice',
      if (reviewWindowOpen) 'review',
      if (_disputeWindowOpen(r)) 'dispute',
    ];
  }

  // -------------------------------------------------------------- writes

  static ApiFailure _failure(int status, String code, String message) =>
      ApiFailure(statusCode: status, code: code, message: message);

  /// The checks `quote` and `create` share; a refused date is returned, not
  /// thrown, so the quote can answer with it.
  String? _dateRefusal(BookingRequest request, {required bool sending}) {
    final String? serviceId = request.serviceId;
    final String? packId = request.packId;
    final String providerId;
    if (serviceId != null) {
      final Map<String, Object?>? s = _MockCatalog._services[serviceId];
      if (s == null) throw _notFound(ApiErrorCode.serviceNotFound, 'Service');
      providerId = s['providerId']! as String;
    } else {
      final Map<String, Object?>? k = _MockCatalog._packs[packId];
      if (k == null) throw _notFound(ApiErrorCode.packNotFound, 'Pack');
      providerId = k['providerId']! as String;
    }
    if (_MockCatalog._providers[providerId]?['acceptingBookings'] != true) {
      return ApiErrorCode.providerNotAccepting;
    }
    final DateTime day = DateTime(
      request.eventDate.year,
      request.eventDate.month,
      request.eventDate.day,
    );
    if (day.isBefore(_catalog._firstBookable)) return ApiErrorCode.minNotice;
    final DayState state = serviceId != null
        ? _catalog._dayState(serviceId, day)
        : _catalog._packDayState(_MockCatalog._packs[packId]!, day);
    if (state != DayState.available) return ApiErrorCode.dateUnavailable;
    if (sending && _takenMeanwhile(serviceId ?? packId!, day)) {
      return ApiErrorCode.dateUnavailable;
    }
    return null;
  }

  void _checkExtras(BookingRequest request) {
    if (request.extras.isEmpty) return;
    final Map<String, Object?>? s = _MockCatalog._services[request.serviceId];
    final Set<Object?> known = <Object?>{
      for (final Object? e in (s?['extras'] as List<Object?>?) ?? const <Object?>[])
        (e! as Map<String, Object?>)['id'],
    };
    if (request.packId != null ||
        request.extras.keys.any((String id) => !known.contains(id))) {
      throw _failure(422, ApiErrorCode.bookingExtraInvalid,
          'Some extras do not belong to this service.');
    }
  }

  Map<String, Object?> quote(BookingRequest request) {
    _checkExtras(request);
    final String? refusal = _dateRefusal(request, sending: false);
    return <String, Object?>{
      ..._price(
        serviceId: request.serviceId,
        packId: request.packId,
        startTime: request.startTime,
        endTime: request.endTime,
        guests: request.guests,
        extras: request.extras,
      ),
      'feePercent': '8.00',
      'available': refusal == null,
      'unavailableReason': refusal,
      'firstBookableDate': apiDate(_catalog._firstBookable),
      'minNoticeDays': _MockCatalog.minNoticeDays,
    };
  }

  Future<Map<String, Object?>> create(BookingRequest request) async {
    final List<Map<String, Object?>> records = _records();
    _checkExtras(request);
    final String? communeId = request.communeId;
    if (communeId != null) {
      final bool known = (mockCommunes[request.wilayaCode] ??
              const <Map<String, Object?>>[])
          .any((Map<String, Object?> c) => c['id'] == communeId);
      if (!known) {
        throw _failure(422, ApiErrorCode.communeWilayaMismatch,
            'The commune is not in this wilaya.');
      }
    }
    switch (_dateRefusal(request, sending: true)) {
      case ApiErrorCode.providerNotAccepting:
        throw _failure(422, ApiErrorCode.providerNotAccepting,
            'The provider is not accepting bookings.');
      case ApiErrorCode.minNotice:
        throw _failure(422, ApiErrorCode.minNotice,
            'The event date must be on or after ${apiDate(_catalog._firstBookable)}.');
      case ApiErrorCode.dateUnavailable:
        throw _failure(409, ApiErrorCode.dateUnavailable,
            'The provider is not available on ${apiDate(request.eventDate)}.');
    }
    final int ms = _backend.now.millisecondsSinceEpoch;
    final Map<String, Object?> record = <String, Object?>{
      'id': 'mock-booking-$ms',
      'reference': 'EVT-${(ms ~/ 1000 % 1000000).toString().padLeft(6, '0')}',
      'status': 'pending',
      'serviceId': request.serviceId,
      'packId': request.packId,
      'eventType': request.eventType.apiValue,
      'eventDate': apiDate(request.eventDate),
      'startTime': request.startTime,
      'endTime': request.endTime,
      'guests': request.guests,
      'wilayaCode': request.wilayaCode,
      'communeId': communeId,
      'locationText': request.locationText?.trim().isEmpty ?? true
          ? null
          : request.locationText!.trim(),
      'clientNote': request.clientNote?.trim().isEmpty ?? true
          ? null
          : request.clientNote!.trim(),
      'extras': <String, int>{
        for (final MapEntry<String, int> e in request.extras.entries)
          if (e.value > 0) e.key: e.value,
      },
      'createdAt': ms,
      'timeline': <Object?>[
        <String, Object?>{'type': 'created', 'by': 'client', 'at': ms},
      ],
      'reschedules': <Object?>[],
      'checkedIn': false,
      'otherCheckedIn': false,
    };
    records.add(record);
    await _backend.saveClientBookings();
    return render(record);
  }

  Future<Map<String, Object?>> cancel(String id, String reason) async {
    final Map<String, Object?> r = _record(id);
    final String status = r['status']! as String;
    if (status != 'pending' && status != 'accepted') {
      throw _failure(409, ApiErrorCode.bookingInvalidTransition,
          'A booking cannot move from "$status" to "cancelled".');
    }
    _checkText(reason, max: 60);
    r['status'] = 'cancelled';
    r['cancelReason'] = reason.trim();
    r['cancelledBy'] = 'client';
    for (final Object? x in r['reschedules']! as List<Object?>) {
      final Map<String, Object?> row = x! as Map<String, Object?>;
      if (row['status'] == 'pending') row['status'] = 'cancelled';
    }
    _timeline(r, 'cancelled', by: 'client', reason: reason.trim());
    await _backend.saveClientBookings();
    return render(r);
  }

  Future<Map<String, Object?>> reschedule(
    String id, {
    required DateTime date,
    required String reason,
    String? startTime,
    String? endTime,
  }) async {
    final Map<String, Object?> r = _record(id);
    final String status = r['status']! as String;
    if (status != 'pending' && status != 'accepted') {
      throw _failure(409, ApiErrorCode.bookingNotEditable,
          'This action is not possible while the booking is $status.');
    }
    _checkText(reason, max: 200);
    final DateTime now = _backend.now;
    if (date.isBefore(DateTime(now.year, now.month, now.day))) {
      throw _failure(422, ApiErrorCode.bookingDatePast, 'The date is in the past.');
    }
    final List<Object?> proposals = r['reschedules']! as List<Object?>;
    if (proposals.any((Object? x) => (x! as Map<String, Object?>)['status'] == 'pending')) {
      throw _failure(409, ApiErrorCode.reschedulePendingExists,
          'A new date is already waiting for confirmation. Cancel it first.');
    }
    final String? serviceId = r['serviceId'] as String?;
    final DayState state = serviceId != null
        ? _catalog._dayState(serviceId, date)
        : _catalog._packDayState(_MockCatalog._packs[r['packId']]!, date);
    if (state != DayState.available) {
      throw _failure(409, ApiErrorCode.dateUnavailable,
          'The provider is not available on ${apiDate(date)}.');
    }
    if (status == 'pending') {
      // Nothing is agreed yet: the request simply moves.
      r['eventDate'] = apiDate(date);
      r['startTime'] = startTime ?? r['startTime'];
      r['endTime'] = startTime == null ? r['endTime'] : endTime;
      _timeline(r, 'rescheduled', by: 'client', reason: reason.trim());
    } else {
      proposals.add(<String, Object?>{
        'id': 'mock-reschedule-${now.millisecondsSinceEpoch}',
        'status': 'pending',
        'oldDate': r['eventDate'],
        'newDate': apiDate(date),
        'newStartTime': startTime,
        'newEndTime': endTime,
        'reason': reason.trim(),
        'by': 'client',
        'createdAt': now.millisecondsSinceEpoch,
      });
    }
    await _backend.saveClientBookings();
    return render(r);
  }

  Future<Map<String, Object?>> answerReschedule(
    String id,
    String rescheduleId, {
    required String answer,
  }) async {
    final Map<String, Object?> r = _record(id);
    Map<String, Object?>? row;
    for (final Map<String, Object?> x in _rows(r['reschedules'])) {
      if (x['id'] == rescheduleId) row = x;
    }
    if (row == null) {
      throw _failure(404, ApiErrorCode.rescheduleNotFound,
          'The reschedule proposal was not found.');
    }
    if (row['status'] != 'pending') {
      throw _failure(409, ApiErrorCode.rescheduleNotPending,
          'This reschedule proposal is already ${row['status']}.');
    }
    final bool mine = row['by'] == 'client';
    if (mine == (answer != 'withdraw')) {
      throw _failure(403, ApiErrorCode.notOwner, 'You do not own this item.');
    }
    switch (answer) {
      case 'accept':
        row['status'] = 'accepted';
        r['eventDate'] = row['newDate'];
        if (row['newStartTime'] != null) {
          r['startTime'] = row['newStartTime'];
          r['endTime'] = row['newEndTime'];
        }
        _timeline(r, 'rescheduled', by: 'client');
      case 'reject':
        row['status'] = 'rejected';
      case 'withdraw':
        row['status'] = 'cancelled';
    }
    await _backend.saveClientBookings();
    return render(r);
  }

  Future<Map<String, Object?>> checkIn(String id) async {
    final Map<String, Object?> r = _record(id);
    if (r['dispute'] != null) {
      throw _failure(409, ApiErrorCode.checkInDisputed,
          'A problem is already open on this booking.');
    }
    if (r['status'] != 'accepted' || r['checkedIn'] == true) {
      throw _failure(409, ApiErrorCode.checkInNotAllowed,
          'This booking cannot be confirmed in its current state.');
    }
    final DateTime now = _backend.now;
    if (!_day(r['eventDate']).isBefore(DateTime(now.year, now.month, now.day))) {
      throw _failure(422, ApiErrorCode.checkInTooEarly,
          'You can confirm once the event has taken place.');
    }
    r['checkedIn'] = true;
    _timeline(r, 'checked_in', by: 'client');
    if (r['otherCheckedIn'] == true) {
      // Both sides said "All good": it completes at once.
      r['status'] = 'completed';
      r['completedAt'] = now.millisecondsSinceEpoch;
      _timeline(r, 'completed', by: 'client');
    }
    await _backend.saveClientBookings();
    return render(r);
  }

  Map<String, Object?> invoice(String id) {
    final Map<String, Object?> r = _record(id);
    final String? number = r['invoiceNumber'] as String?;
    if (number == null) {
      throw _failure(404, ApiErrorCode.invoiceNotFound, 'This booking has no invoice.');
    }
    final Map<String, Object?> detail = render(r);
    final Map<String, Object?> party =
        detail['counterparty']! as Map<String, Object?>;
    final MockAccount account = _backend.requireSession();
    final int total = _cents(detail['total']! as String);
    final int fee = (total * 8 / 100).round();
    return <String, Object?>{
      'id': 'mock-invoice-$id',
      'bookingId': id,
      'bookingReference': r['reference'],
      'number': number,
      'version': 1,
      'issuedAt': _iso((r['acceptedAt'] ?? r['createdAt'])! as int),
      'currency': 'DZD',
      'issuer': const <String, Object?>{
        'name': 'Eventor (Symloop SARL)',
        'address': 'Cité 1er Novembre, Bab Ezzouar, Alger',
        'nif': '001216099999999',
        'rc': '16/00-1234567B21',
        'email': 'billing@eventor.dz',
        'phone': '+213 23 00 00 00',
      },
      'client': <String, Object?>{
        'id': account.id,
        'name': account.fullName,
        'businessName': null,
        'email': account.email,
        'phone': account.phone,
      },
      'provider': <String, Object?>{
        'id': party['id'],
        'name': party['fullName'],
        'businessName': party['businessName'],
        'email': null,
        'phone': party['phone'],
      },
      'titleEn': detail['titleEn'],
      'titleAr': detail['titleAr'],
      'eventDate': r['eventDate'],
      'eventType': r['eventType'],
      'lines': detail['lines'],
      'subtotal': detail['subtotal'],
      'discountTotal': detail['discountTotal'],
      'total': detail['total'],
      'feePercent': '8.00',
      'feeAmount': _money(fee),
      'providerAmount': _money(total - fee),
      'pdfReady': true,
      'sentToClientAt': null,
      'versions': const <int>[1],
    };
  }

  /// A one-page PDF of the invoice — enough for the share sheet to have a
  /// real file to hand on.
  Uint8List invoicePdf(String id) {
    final Map<String, Object?> inv = invoice(id);
    final List<String> text = <String>[
      'Eventor - Invoice ${inv['number']}',
      'Booking ${inv['bookingReference']} - ${inv['eventDate']}',
      '${inv['titleEn']}',
      for (final Map<String, Object?> l in _rows(inv['lines']))
        '${l['label']}  x${l['quantity']}  ${l['amount']} DZD',
      'Total: ${inv['total']} DZD - paid in cash to the provider',
    ];
    return _pdf(text);
  }

  static Uint8List _pdf(List<String> lines) {
    // Latin-1 only: a PDF's base fonts cannot draw anything else.
    String clean(String s) => String.fromCharCodes(
          s.runes.map((int c) => c < 256 ? c : 63),
        ).replaceAll('\\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');
    final StringBuffer content = StringBuffer('BT /F1 12 Tf 50 780 Td 16 TL\n');
    for (final String line in lines) {
      content.write('(${clean(line)}) Tj T*\n');
    }
    content.write('ET');
    final String stream = content.toString();
    final List<String> objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
          '/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      '<< /Length ${latin1.encode(stream).length} >>\nstream\n$stream\nendstream',
    ];
    final StringBuffer pdf = StringBuffer('%PDF-1.4\n');
    final List<int> offsets = <int>[];
    for (int i = 0; i < objects.length; i++) {
      offsets.add(latin1.encode(pdf.toString()).length);
      pdf.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
    }
    final int xref = latin1.encode(pdf.toString()).length;
    pdf.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
    for (final int offset in offsets) {
      pdf.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    pdf.write('trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
        'startxref\n$xref\n%%EOF');
    return Uint8List.fromList(latin1.encode(pdf.toString()));
  }

  Future<void> review(String id, int rating, String comment) async {
    final Map<String, Object?> r = _record(id);
    if (r['reviewId'] != null) {
      throw _failure(409, ApiErrorCode.reviewExists,
          'You have already reviewed this booking.');
    }
    if (r['status'] != 'completed') {
      throw _failure(422, ApiErrorCode.reviewNotAllowed,
          'Only the client of a completed booking can leave a review.');
    }
    final List<Object?> actions = render(r)['allowedActions']! as List<Object?>;
    if (!actions.contains('review')) {
      throw _failure(422, ApiErrorCode.reviewWindowClosed,
          'The review window for this booking is closed.');
    }
    if (rating < 1 || rating > 5) throw _invalid('rating');
    final int length = comment.trim().length;
    if (length < 10 || length > 2000) throw _invalid('comment');
    r['reviewId'] = 'mock-review-${_backend.now.millisecondsSinceEpoch}';
    await _backend.saveClientBookings();
  }

  Future<Map<String, Object?>> openDispute(
    String id,
    DisputeType type,
    String description,
  ) async {
    final Map<String, Object?> r = _record(id);
    final Map<String, Object?>? existing = r['dispute'] as Map<String, Object?>?;
    if (existing != null && existing['status'] != 'resolved') {
      throw _failure(409, ApiErrorCode.disputeAlreadyOpen,
          'This booking already has an open dispute (${existing['reference']}).');
    }
    final String status = r['status']! as String;
    if (status != 'accepted' && status != 'completed' && status != 'cancelled') {
      throw _failure(422, ApiErrorCode.bookingNotDisputable,
          'A dispute can only be opened on an accepted, completed or cancelled booking.');
    }
    if (!_disputeWindowOpen(r)) {
      throw _failure(422, ApiErrorCode.disputeWindowClosed,
          'The dispute window for this booking is closed.');
    }
    final int length = description.trim().length;
    if (length < 30 || length > 5000) throw _invalid('description');
    final int ms = _backend.now.millisecondsSinceEpoch;
    final Map<String, Object?> dispute = <String, Object?>{
      'id': 'mock-dispute-$ms',
      'reference': 'DSP-${(ms ~/ 1000 % 1000000).toString().padLeft(6, '0')}',
      'status': 'open',
      'type': type.apiValue,
      'createdAt': ms,
    };
    r['dispute'] = dispute;
    _timeline(r, 'dispute_opened', by: 'client');
    await _backend.saveClientBookings();
    return <String, Object?>{
      'id': dispute['id'],
      'reference': dispute['reference'],
      'status': 'open',
      'conversationId': null,
    };
  }

  static void _checkText(String value, {required int max}) {
    final String text = value.trim();
    if (text.isEmpty || text.length > max) throw _invalid('reason');
  }

  static ApiFailure _invalid(String field) => ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.validationFailed,
        message: 'Some fields are invalid.',
        fieldErrors: <FieldError>[
          FieldError(field: field, code: 'INVALID', message: 'Invalid value.'),
        ],
      );
}

/// [BookingsRepository] on the [MockBackend], with the live API's rules:
/// the four tabs, the status transitions, the reschedule turn-taking, the
/// check-in, the review and dispute windows, and the same error codes.
class MockBookingsRepository implements BookingsRepository {
  MockBookingsRepository(
    this._backend, {
    required String Function() languageCode,
  }) : _bookings = _MockBookings(_MockCatalog(_backend, languageCode));

  final MockBackend _backend;
  final _MockBookings _bookings;

  @override
  Future<ApiPage<BookingCard>> list({
    required BookingTab tab,
    int page = 1,
    int limit = 20,
  }) async {
    await _backend.delay();
    final DateTime now = _backend.now;
    final DateTime today = DateTime(now.year, now.month, now.day);
    bool inTab(BookingCard b) {
      final bool ahead = !b.eventDate.isBefore(today);
      return switch (tab) {
        BookingTab.upcoming => b.status == 'accepted' && ahead,
        BookingTab.pending => b.status == 'pending',
        BookingTab.past =>
          b.status == 'completed' || (b.status == 'accepted' && !ahead),
        BookingTab.cancelled =>
          b.status == 'cancelled' || b.status == 'declined',
      };
    }

    final List<BookingCard> found = _bookings
        .rendered()
        .map(BookingCard.fromJson)
        .where(inTab)
        .toList()
      ..sort(
        (BookingCard a, BookingCard b) =>
            tab == BookingTab.past || tab == BookingTab.cancelled
                ? b.eventDate.compareTo(a.eventDate)
                : a.eventDate.compareTo(b.eventDate),
      );
    return _page(found, page, limit);
  }

  @override
  Future<BookingDetail> detail(String id) async {
    await _backend.delay();
    return BookingDetail.fromJson(_bookings.render(_bookings._record(id)));
  }

  @override
  Future<BookingQuote> quote(BookingRequest request) async {
    await _backend.delay();
    _backend.requireSession();
    return BookingQuote.fromJson(_bookings.quote(request));
  }

  @override
  Future<BookingDetail> create(BookingRequest request) async {
    await _backend.delay();
    return BookingDetail.fromJson(await _bookings.create(request));
  }

  @override
  Future<BookingDetail> cancel(String id, {required String reason}) async {
    await _backend.delay();
    return BookingDetail.fromJson(await _bookings.cancel(id, reason));
  }

  @override
  Future<BookingDetail> reschedule(
    String id, {
    required DateTime date,
    required String reason,
    String? startTime,
    String? endTime,
  }) async {
    await _backend.delay();
    return BookingDetail.fromJson(
      await _bookings.reschedule(
        id,
        date: date,
        reason: reason,
        startTime: startTime,
        endTime: endTime,
      ),
    );
  }

  @override
  Future<BookingDetail> acceptReschedule(String id, String rescheduleId) =>
      _answer(id, rescheduleId, 'accept');

  @override
  Future<BookingDetail> rejectReschedule(String id, String rescheduleId) =>
      _answer(id, rescheduleId, 'reject');

  @override
  Future<BookingDetail> withdrawReschedule(String id, String rescheduleId) =>
      _answer(id, rescheduleId, 'withdraw');

  Future<BookingDetail> _answer(String id, String rescheduleId, String answer) async {
    await _backend.delay();
    return BookingDetail.fromJson(
      await _bookings.answerReschedule(id, rescheduleId, answer: answer),
    );
  }

  @override
  Future<BookingDetail> checkIn(String id) async {
    await _backend.delay();
    return BookingDetail.fromJson(await _bookings.checkIn(id));
  }

  @override
  Future<Invoice> invoice(String id) async {
    await _backend.delay();
    return Invoice.fromJson(_bookings.invoice(id));
  }

  @override
  Future<Uint8List> invoicePdf(String id) async {
    await _backend.delay();
    return _bookings.invoicePdf(id);
  }

  @override
  Future<void> review(
    String id, {
    required int rating,
    required String comment,
  }) async {
    await _backend.delay();
    await _bookings.review(id, rating, comment);
  }

  @override
  Future<BookingDisputeSummary> openDispute(
    String id, {
    required DisputeType type,
    required String description,
  }) async {
    await _backend.delay();
    return BookingDisputeSummary.fromJson(
      await _bookings.openDispute(id, type, description),
    );
  }
}
