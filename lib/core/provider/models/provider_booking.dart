import '../../bookings/models/booking_card.dart';
import '../../bookings/models/booking_detail.dart';
import '../../catalog/models/json_read.dart';

/// One of the provider Requests tab's three lists — the API's `tab`. Not the
/// client's [BookingTab]: the provider cannot list declined or cancelled
/// bookings at all (P2c / P2d are reached from links only).
enum ProviderBookingTab {
  /// Everything still pending — P1.
  requests,

  /// Accepted, from today on.
  upcoming,

  /// Completed, and accepted ones whose event has gone by.
  past;

  String get apiValue => name;
}

/// Who cancelled a booking — the API's `cancelledBy`. [BookingDetail] only
/// knows "the client or not"; P2d words the provider's own cancellation and
/// an admin's differently.
enum CancelledBy {
  client,
  provider,
  admin;

  static CancelledBy? fromApi(String? value) => switch (value) {
        'client' => client,
        'provider' => provider,
        'admin' => admin,
        _ => null,
      };
}

/// What went wrong, from the provider's side — the dispute `type`s that can
/// be about a client. The client's own list (`DisputeType`) is about a
/// provider who did not come or did not deliver.
enum ProviderDisputeType {
  clientNoShow('client_no_show'),
  priceDisagreement('price_disagreement'),
  cancellationDisagreement('cancellation_disagreement'),
  damageOrSafety('damage_or_safety'),
  behaviour('behaviour'),
  other('other');

  const ProviderDisputeType(this.apiValue);

  final String apiValue;
}

/// The client on a provider's booking — the `counterparty`. Phone and email
/// stay `null` until the booking is accepted (status-rules §10).
class BookingClient {
  const BookingClient({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.email,
  });

  factory BookingClient.fromJson(Map<String, Object?> json) => BookingClient(
        id: readString(json, 'id'),
        fullName: readString(json, 'fullName'),
        avatarUrl: readStringOrNull(json, 'avatarUrl'),
        phone: readStringOrNull(json, 'phone'),
        email: readStringOrNull(json, 'email'),
      );

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final String? email;

  /// Something to reach them on — P2a's phone row.
  bool get hasContact => phone != null || email != null;
}

/// P2 and its variants — `GET /app/provider/bookings/{id}`.
///
/// The same `AppBookingDetailDto` the client reads, so it *is* a
/// [BookingDetail] (P4 and P5 take one), plus the few fields only the
/// provider's screens read: who the client is, and who cancelled.
class ProviderBooking extends BookingDetail {
  ProviderBooking._(
    BookingDetail detail, {
    required this.client,
    this.cancelledBy,
  }) : super(
          card: detail.card,
          lines: detail.lines,
          subtotal: detail.subtotal,
          discountTotal: detail.discountTotal,
          timeline: detail.timeline,
          reschedules: detail.reschedules,
          eventTypeValue: detail.eventTypeValue,
          wilaya: detail.wilaya,
          guests: detail.guests,
          locationText: detail.locationText,
          communeName: detail.communeName,
          clientNote: detail.clientNote,
          cancellationPolicy: detail.cancellationPolicy,
          cancelReason: detail.cancelReason,
          cancelledByClient: detail.cancelledByClient,
          declineReason: detail.declineReason,
          provider: detail.provider,
          providerPhone: detail.providerPhone,
          conversationId: detail.conversationId,
          invoice: detail.invoice,
          dispute: detail.dispute,
          checkedIn: detail.checkedIn,
          otherCheckedIn: detail.otherCheckedIn,
          reviewId: detail.reviewId,
          reviewWindowOpen: detail.reviewWindowOpen,
          disputeWindowOpen: detail.disputeWindowOpen,
        );

  factory ProviderBooking.fromJson(Map<String, Object?> json) => ProviderBooking._(
        BookingDetail.fromJson(json),
        client: BookingClient.fromJson(
          readObject(json, 'counterparty') ?? const <String, Object?>{},
        ),
        cancelledBy: CancelledBy.fromApi(json['cancelledBy'] as String?),
      );

  final BookingClient client;
  final CancelledBy? cancelledBy;

  /// The client's own name, as P2 writes it everywhere.
  String get clientName => client.fullName;

  /// It was accepted at some point — a cancelled booking that had been
  /// accepted is a "Booking", one cancelled while pending stays a "Request".
  bool get wasAccepted =>
      status == 'accepted' ||
      status == 'completed' ||
      timeline.any((TimelineEntry e) => e.type == TimelineEntryType.accepted);

  /// The last time [type] happened, from the timeline.
  DateTime? lastAt(TimelineEntryType type) {
    DateTime? found;
    for (final TimelineEntry entry in timeline) {
      if (entry.type == type) found = entry.at;
    }
    return found;
  }
}

/// Whole hours left to answer [request] — "Reply within 47 h" — never below
/// zero; `null` when the server did not say when it was made. Rounded up:
/// 46 h 10 min still leaves "47 h" to answer in. Shared by 21 and P1/P2.
int? replyHoursLeft(
  BookingCard request, {
  required int deadlineHours,
  required DateTime now,
}) {
  final DateTime? made = request.createdAt;
  if (made == null) return null;
  final Duration left = made.add(Duration(hours: deadlineHours)).difference(now);
  if (left.isNegative) return 0;
  return (left.inMinutes / 60).ceil();
}

/// What is on one day of the provider's own calendar — the API's
/// `AvailabilityDayDto.status`: `booked > held > blocked > partial > free`.
enum ProviderDayStatus {
  free,

  /// Blocked for part of the day, or for one service.
  partial,

  /// Blocked by the provider for the whole day.
  blocked,

  /// A pending request holds it.
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
}

/// One day of [ProviderCalendarMonth] — only what P4 needs to tell a free
/// day from a full one. The availability screen (P15) reads its own,
/// richer model.
class ProviderCalendarDay {
  const ProviderCalendarDay({
    required this.date,
    required this.status,
    this.bookingIds = const <String>{},
  });

  factory ProviderCalendarDay.fromJson(Map<String, Object?> json) {
    final Set<String> bookings = <String>{};
    for (final Map<String, Object?> item
        in readList(json, 'items', (Map<String, Object?> i) => i)) {
      final String kind = readString(item, 'kind');
      final Map<String, Object?>? booking = readObject(item, 'booking');
      if ((kind == 'booked' || kind == 'held') && booking != null) {
        bookings.add(readString(booking, 'id'));
      }
    }
    return ProviderCalendarDay(
      date: readDate(json, 'date'),
      status: ProviderDayStatus.fromApi(json['status'] as String?),
      bookingIds: bookings,
    );
  }

  /// Local midnight.
  final DateTime date;
  final ProviderDayStatus status;

  /// The bookings and requests on it.
  final Set<String> bookingIds;
}

/// `GET /app/provider/availability?month=` as P4 reads it — which days the
/// provider is free to move a booking to.
class ProviderCalendarMonth {
  ProviderCalendarMonth({
    required this.month,
    required this.maxEventsPerDay,
    required List<ProviderCalendarDay> days,
  }) : _byDay = <int, ProviderCalendarDay>{
          for (final ProviderCalendarDay day in days) _key(day.date): day,
        };

  factory ProviderCalendarMonth.fromJson(Map<String, Object?> json) =>
      ProviderCalendarMonth(
        month: readString(json, 'month'),
        maxEventsPerDay: readIntOrNull(json, 'maxEventsPerDay') ?? 1,
        days: readList(json, 'days', ProviderCalendarDay.fromJson),
      );

  /// `"2026-11"`.
  final String month;

  /// The highest capacity among the provider's services.
  final int maxEventsPerDay;
  final Map<int, ProviderCalendarDay> _byDay;

  /// [day]'s entry, or `null` when the server did not list it.
  ProviderCalendarDay? dayOf(DateTime day) => _byDay[_key(day)];

  static int _key(DateTime day) => day.year * 10000 + day.month * 100 + day.day;
}
