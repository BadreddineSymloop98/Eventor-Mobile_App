import 'mock_backend.dart';

/// A booking as the provider's availability calendar needs it (`P15`,
/// `P15c`): the shared booking store's rows, seen by the availability mock
/// without depending on how that store keeps them.
///
/// A pending request holds its day (`held`); an accepted booking takes it
/// (`booked`). Declined, cancelled and completed bookings are not listed.
class MockCalendarBooking {
  const MockCalendarBooking({
    required this.id,
    required this.reference,
    required this.clientName,
    required this.date,
    required this.isAccepted,
    this.startTime,
    this.endTime,
    this.serviceId,
    this.packId,
    this.titleEn,
    this.titleAr,
  });

  final String id;

  /// `EVT-2026-0142`.
  final String reference;
  final String clientName;

  /// The event day, `YYYY-MM-DD`.
  final String date;

  /// `true` once accepted (`booked`), `false` while pending (`held`).
  final bool isAccepted;

  /// `HH:mm`, or `null` for the whole day.
  final String? startTime;
  final String? endTime;

  /// The service booked; `null` for a pack.
  final String? serviceId;

  /// The pack booked; `null` for a service.
  final String? packId;
  final String? titleEn;
  final String? titleAr;
}

/// The live (pending or accepted) bookings made to [provider].
typedef MockCalendarBookings = List<MockCalendarBooking> Function(MockAccount provider);
