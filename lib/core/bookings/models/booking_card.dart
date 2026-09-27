import '../../catalog/models/json_read.dart';

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

/// A row of the client's bookings — the API's `AppBookingCardDto`, trimmed to
/// what the app reads so far.
///
/// Only the budget's "Link a booking" (18h) uses it today; the Bookings tab
/// will grow it rather than add a second model.
class BookingCard {
  const BookingCard({
    required this.id,
    required this.reference,
    required this.status,
    required this.eventDate,
    required this.title,
    required this.providerName,
  });

  factory BookingCard.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> party =
        readObject(json, 'counterparty') ?? const <String, Object?>{};
    // A provider's business name when it has one — what the client knows
    // them by — or their own name.
    final String business = readString(party, 'businessName');
    return BookingCard(
      id: json['id']! as String,
      reference: readString(json, 'reference'),
      status: readString(json, 'status'),
      eventDate: readDate(json, 'eventDate'),
      title: LocalizedText.read(json, 'title'),
      providerName:
          business.isNotEmpty ? business : readString(party, 'fullName'),
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
  final String providerName;
}
