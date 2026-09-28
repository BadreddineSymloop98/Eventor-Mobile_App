import '../../catalog/models/json_read.dart';

/// What a day on the provider's calendar (P15) holds, as the legend words
/// it. The server ranks them `booked > held > blocked > partial > free`: a
/// day shows the strongest thing on it.
enum ProviderDayStatus {
  /// Nothing on it — clients can book it.
  free,

  /// Blocked for part of the day, or for one service only.
  partial,

  /// Blocked all day for every service.
  blocked,

  /// A pending request holds it until the provider answers.
  held,

  /// An accepted booking takes it.
  booked;

  static ProviderDayStatus fromApi(String? value) => switch (value) {
        'partial' => partial,
        'blocked' => blocked,
        'held' => held,
        'booked' => booked,
        _ => free,
      };

  /// The status the server would give a day holding [items] — so a removal
  /// can show at once, before the month reloads.
  static ProviderDayStatus of(List<ProviderDayItem> items) {
    if (items.any((ProviderDayItem i) => i.kind == ProviderDayItemKind.booked)) return booked;
    if (items.any((ProviderDayItem i) => i.kind == ProviderDayItemKind.held)) return held;
    final Iterable<ProviderDayItem> blocks =
        items.where((ProviderDayItem i) => i.kind == ProviderDayItemKind.blocked);
    if (blocks.any((ProviderDayItem i) => i.blocksEverything)) return blocked;
    return blocks.isEmpty ? free : partial;
  }
}

/// One thing on a day: a block the provider added, or a booking.
enum ProviderDayItemKind {
  blocked,
  held,
  booked;

  static ProviderDayItemKind fromApi(String? value) => switch (value) {
        'held' => held,
        'booked' => booked,
        _ => blocked,
      };
}

/// The service a block or a booking is about — `AvailabilityServiceRefDto`.
class DayService {
  const DayService({required this.id, required this.title});

  factory DayService.fromJson(Map<String, Object?> json) => DayService(
        id: readString(json, 'id'),
        title: LocalizedText.read(json, 'title'),
      );

  final String id;
  final LocalizedText title;
}

/// The booking behind a held or booked day — `AvailabilityBookingRefDto`.
class DayBooking {
  const DayBooking({
    required this.id,
    required this.reference,
    required this.status,
    this.clientName,
  });

  factory DayBooking.fromJson(Map<String, Object?> json) => DayBooking(
        id: readString(json, 'id'),
        reference: readString(json, 'reference'),
        status: readString(json, 'status'),
        // Not in the contract yet (backend ask): read when the server
        // starts sending it, so P15c can name the client without a release.
        clientName: readStringOrNull(json, 'clientName'),
      );

  final String id;

  /// `EVT-2026-0142`.
  final String reference;

  /// The booking's own status — `pending`, `accepted`.
  final String status;
  final String? clientName;
}

/// A row of P15c's "What is on this day" — `AvailabilityBlockDto`.
class ProviderDayItem {
  const ProviderDayItem({
    required this.id,
    required this.kind,
    required this.date,
    required this.removable,
    this.startTime,
    this.endTime,
    this.service,
    this.booking,
    this.note,
  });

  factory ProviderDayItem.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? service = readObject(json, 'service');
    final Map<String, Object?>? booking = readObject(json, 'booking');
    return ProviderDayItem(
      id: readStringOrNull(json, 'id'),
      kind: ProviderDayItemKind.fromApi(json['kind'] as String?),
      date: readDate(json, 'date'),
      startTime: readStringOrNull(json, 'startTime'),
      endTime: readStringOrNull(json, 'endTime'),
      service: service == null ? null : DayService.fromJson(service),
      booking: booking == null ? null : DayBooking.fromJson(booking),
      note: readStringOrNull(json, 'note'),
      removable: readBool(json, 'removable'),
    );
  }

  /// `null` for a booking without an availability row of its own.
  final String? id;
  final ProviderDayItemKind kind;

  /// Local midnight.
  final DateTime date;

  /// `HH:mm`, or `null` for the whole day.
  final String? startTime;
  final String? endTime;

  /// `null` when the block covers every service.
  final DayService? service;
  final DayBooking? booking;

  /// The provider's private note on a block.
  final String? note;

  /// Only blocks the provider added can be removed.
  final bool removable;

  bool get isWholeDay => startTime == null;
  bool get isBooking => kind != ProviderDayItemKind.blocked;

  /// A whole-day block on every service — nothing else can be booked.
  bool get blocksEverything =>
      kind == ProviderDayItemKind.blocked && isWholeDay && service == null;

  /// The block as it was asked for — what Undo sends again after a removal.
  BlockRequest get asRequest => BlockRequest(
        date: date,
        startTime: startTime,
        endTime: endTime,
        serviceId: service?.id,
        note: note,
      );
}

/// One day of the month and everything on it — `AvailabilityDayDto`.
class ProviderDay {
  const ProviderDay({
    required this.date,
    required this.status,
    this.items = const <ProviderDayItem>[],
  });

  factory ProviderDay.fromJson(Map<String, Object?> json) => ProviderDay(
        date: readDate(json, 'date'),
        status: ProviderDayStatus.fromApi(json['status'] as String?),
        items: readList(json, 'items', ProviderDayItem.fromJson),
      );

  /// A day the server did not list — free.
  factory ProviderDay.empty(DateTime date) => ProviderDay(
        date: DateTime(date.year, date.month, date.day),
        status: ProviderDayStatus.free,
      );

  /// Local midnight.
  final DateTime date;
  final ProviderDayStatus status;
  final List<ProviderDayItem> items;

  /// This day with [items] instead, its status worked out again.
  ProviderDay withItems(List<ProviderDayItem> items) => ProviderDay(
        date: date,
        status: ProviderDayStatus.of(items),
        items: items,
      );
}

/// A month of the provider's calendar — `AvailabilityMonthDto`.
class AvailabilityMonth {
  AvailabilityMonth({
    required this.month,
    required this.maxEventsPerDay,
    required List<ProviderDay> days,
    this.providerId = '',
  }) : _days = <int, ProviderDay>{
          for (final ProviderDay day in days) _key(day.date): day,
        };

  AvailabilityMonth._(this.providerId, this.month, this.maxEventsPerDay, this._days);

  factory AvailabilityMonth.fromJson(Map<String, Object?> json) {
    final String month = readString(json, 'month');
    final List<ProviderDay> days = readList(json, 'days', ProviderDay.fromJson);
    return AvailabilityMonth(
      providerId: readString(json, 'providerId'),
      month: _parseMonth(month) ??
          (days.isEmpty ? DateTime(1970) : DateTime(days.first.date.year, days.first.date.month)),
      // At least one: a provider with no services yet still takes a booking
      // a day once they have one.
      maxEventsPerDay: readInt(json, 'maxEventsPerDay') < 1 ? 1 : readInt(json, 'maxEventsPerDay'),
      days: days,
    );
  }

  final String providerId;

  /// The first of the month, local midnight.
  final DateTime month;

  /// The most events a day can take — the highest among the services.
  final int maxEventsPerDay;
  final Map<int, ProviderDay> _days;

  static int _key(DateTime day) => day.year * 10000 + day.month * 100 + day.day;

  static DateTime? _parseMonth(String value) {
    final List<String> parts = value.split('-');
    if (parts.length != 2) return null;
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    return year == null || month == null ? null : DateTime(year, month);
  }

  /// [day]'s entry; a day the server left out is free.
  ProviderDay dayOf(DateTime day) => _days[_key(day)] ?? ProviderDay.empty(day);

  /// This month with [day] replaced — a removal shown before the reload.
  AvailabilityMonth withDay(ProviderDay day) => AvailabilityMonth._(
        providerId,
        month,
        maxEventsPerDay,
        <int, ProviderDay>{..._days, _key(day.date): day},
      );
}

/// A block to add — `AppCreateBlockDto`. No times blocks the whole day; no
/// service blocks every service.
class BlockRequest {
  const BlockRequest({
    required this.date,
    this.startTime,
    this.endTime,
    this.serviceId,
    this.note,
  });

  /// The API's cap on the note.
  static const int maxNote = 255;

  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String? serviceId;
  final String? note;

  bool get isWholeDay => startTime == null;

  Map<String, Object?> toJson() {
    final String? text = note?.trim();
    return <String, Object?>{
      'date': _apiDate(date),
      // Both or neither, as the API asks.
      if (startTime != null && endTime != null) ...<String, Object?>{
        'startTime': startTime,
        'endTime': endTime,
      },
      'serviceId': ?serviceId,
      if (text != null && text.isNotEmpty) 'note': text,
    };
  }
}

/// `2026-03-14`. The budget's `apiDate`, kept here so the calendar does not
/// reach into the budget module.
String _apiDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// `2026-03` — the month query.
String apiMonth(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
