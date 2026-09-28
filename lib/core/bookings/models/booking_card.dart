import '../../catalog/models/catalog_ref.dart';
import '../../catalog/models/json_read.dart';
import '../../catalog/models/pack.dart' show EventType;
import '../../models/account.dart' show Wilaya;

/// One of the client Bookings tab's four lists — the API's `tab`.
enum BookingTab {
  /// Accepted, with the event still ahead.
  upcoming,

  /// Waiting for the provider.
  pending,

  /// Completed, or accepted with the event behind us.
  past,

  /// Cancelled and declined.
  cancelled;

  String get apiValue => name;
}

/// What the server allows on a booking right now — `allowedActions`. A
/// value this build does not know is ignored.
enum BookingAction {
  accept('accept'),
  decline('decline'),
  message('message'),
  cancel('cancel'),
  complete('complete'),
  reschedule('reschedule'),
  respondReschedule('respond_reschedule'),
  checkIn('check_in'),
  review('review'),
  dispute('dispute'),
  invoice('invoice');

  const BookingAction(this.apiValue);

  final String apiValue;

  static BookingAction? fromApi(String value) {
    for (final BookingAction action in values) {
      if (action.apiValue == value) return action;
    }
    return null;
  }
}

/// A booking as the lists show it — the API's `AppBookingCardDto`, trimmed
/// to what the app reads. The same card serves both sides: for a client the
/// counterparty is the provider, for a provider it is the client.
class BookingCard {
  const BookingCard({
    required this.id,
    required this.reference,
    required this.status,
    required this.eventDate,
    required this.title,
    required this.providerName,
    this.counterpartyName = '',
    this.category,
    this.eventType,
    this.startTime,
    this.endTime,
    this.total = '0.00',
    this.allowedActions = const <BookingAction>{},
    this.createdAt,
    this.wilaya,
    this.guests,
    this.coverUrl,
    this.serviceId,
    this.packId,
  });

  factory BookingCard.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> party =
        readObject(json, 'counterparty') ?? const <String, Object?>{};
    final String fullName = readString(party, 'fullName');
    // A provider's business name when it has one — what the client knows
    // them by — or their own name.
    final String business = readString(party, 'businessName');
    final Map<String, Object?>? category = readObject(json, 'category');
    return BookingCard(
      id: json['id']! as String,
      reference: readString(json, 'reference'),
      status: readString(json, 'status'),
      eventDate: readDate(json, 'eventDate'),
      title: LocalizedText.read(json, 'title'),
      providerName: business.isNotEmpty ? business : fullName,
      counterpartyName: fullName,
      category: category == null ? null : CategoryRef.fromJson(category),
      eventType: json['eventType'] == null
          ? null
          : EventType.fromApi(json['eventType'] as String?),
      startTime: readStringOrNull(json, 'startTime'),
      endTime: readStringOrNull(json, 'endTime'),
      total: readString(json, 'total'),
      allowedActions: <BookingAction>{
        for (final String action in readStrings(json, 'allowedActions'))
          ?BookingAction.fromApi(action),
      },
      createdAt: readDateOrNull(json, 'createdAt'),
      wilaya: readObject(json, 'wilaya') == null
          ? null
          : Wilaya.fromJson(readObject(json, 'wilaya')!),
      guests: readIntOrNull(json, 'guests'),
      coverUrl: readStringOrNull(json, 'coverUrl'),
      serviceId: readStringOrNull(json, 'serviceId'),
      packId: readStringOrNull(json, 'packId'),
    );
  }

  final String id;

  /// `EVT-000123`.
  final String reference;

  /// `pending | accepted | declined | cancelled | completed`.
  final String status;

  /// Local midnight; Algiers time on the server.
  final DateTime eventDate;

  /// The service's or the pack's name.
  final LocalizedText title;

  /// The provider as a client knows them — business name first.
  final String providerName;

  /// The other side's own name — the client, on a provider's screens.
  final String counterpartyName;

  /// The booked service's category; `null` for a pack booking (since
  /// 2026-09-27).
  final CategoryRef? category;
  final EventType? eventType;

  /// `"18:00"`, or `null` for a whole-day booking.
  final String? startTime;
  final String? endTime;

  /// The API's money string.
  final String total;
  final Set<BookingAction> allowedActions;

  /// When the request was made — the reply deadline counts from it.
  final DateTime? createdAt;

  /// Where the event is, when the client said.
  final Wilaya? wilaya;
  final int? guests;
  final String? coverUrl;

  /// What was booked — one of the two.
  final String? serviceId;
  final String? packId;

  bool can(BookingAction action) => allowedActions.contains(action);
}
