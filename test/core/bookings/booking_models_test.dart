import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/catalog/models/pack.dart' show EventType;
import 'package:flutter_test/flutter_test.dart';

import '../../support/booking_fakes.dart';

void main() {
  group('BookingDetail', () {
    test('reads the card, the lines and the timeline', () {
      final BookingDetail booking = BookingDetail.fromJson(bookingJson());

      expect(booking.card.reference, 'EVT-002041');
      expect(booking.card.providerName, 'Studio Lumière');
      expect(booking.card.wilaya?.code, 16);
      expect(booking.card.guests, 150);
      expect(booking.card.serviceId, 's-1');
      expect(booking.lines, hasLength(2));
      expect(booking.lines.last.kind, BookingLineKind.extra);
      expect(booking.lines.last.quantity, 2);
      expect(booking.timeline.map((TimelineEntry e) => e.type), <TimelineEntryType>[
        TimelineEntryType.created,
        TimelineEntryType.accepted,
      ]);
      expect(booking.providerPhone, '+213770551288');
      expect(booking.invoice?.number, 'INV-2026-0142');
      expect(booking.communeName, 'Hydra');
      expect(booking.isPack, isFalse);
    });

    test('knows every allowed action, and ignores one it does not', () {
      final BookingDetail booking = BookingDetail.fromJson(
        bookingJson(allowedActions: <String>['check_in', 'respond_reschedule', 'teleport']),
      );

      expect(booking.can(BookingAction.checkIn), isTrue);
      expect(booking.can(BookingAction.respondReschedule), isTrue);
      expect(booking.card.allowedActions, hasLength(2));
    });

    test('tells a proposal waiting on the client from its own', () {
      final BookingDetail theirs = BookingDetail.fromJson(
        bookingJson(reschedules: <Map<String, Object?>>[proposalJson()]),
      );
      final BookingDetail mine = BookingDetail.fromJson(
        bookingJson(reschedules: <Map<String, Object?>>[proposalJson(awaitingMe: false)]),
      );

      expect(theirs.proposalForMe?.newDate, DateTime(2026, 3, 21));
      expect(theirs.proposalForMe?.reason, startsWith('A wedding'));
      expect(theirs.myPendingProposal, isNull);
      expect(mine.proposalForMe, isNull);
      expect(mine.myPendingProposal?.proposedByClient, isTrue);
    });

    test('drops a timeline entry of a type it does not know', () {
      final BookingDetail booking = BookingDetail.fromJson(
        bookingJson(
          timeline: <Map<String, Object?>>[
            <String, Object?>{'type': 'created', 'at': '2026-03-03T13:20:00.000Z'},
            <String, Object?>{'type': 'moon_landing', 'at': '2026-03-04T13:20:00.000Z'},
          ],
        ),
      );

      expect(booking.timeline, hasLength(1));
    });

    test('a pack booking has no category and is a pack', () {
      final BookingDetail booking = BookingDetail.fromJson(
        bookingJson(serviceId: null, packId: 'k-1')
          ..['lines'] = <Map<String, Object?>>[
            <String, Object?>{
              'id': '',
              'kind': 'pack_service',
              'label': 'Photo',
              'quantity': 1,
              'unitAmount': '45000.00',
              'amount': '45000.00',
            },
          ],
      );

      expect(booking.card.category, isNull);
      expect(booking.card.packId, 'k-1');
      expect(booking.isPack, isTrue);
    });
  });

  group('BookingQuote', () {
    test('reads a refused day as an answer, not an error', () {
      final BookingQuote quote = BookingQuote.fromJson(<String, Object?>{
        'lines': <Object?>[],
        'subtotal': '45000.00',
        'discountTotal': '0.00',
        'total': '45000.00',
        'feePercent': '8.00',
        'available': false,
        'unavailableReason': 'MIN_NOTICE',
        'firstBookableDate': '2026-03-05',
        'minNoticeDays': 2,
      });

      expect(quote.available, isFalse);
      expect(quote.refusal, QuoteRefusal.minNotice);
      expect(quote.firstBookableDate, DateTime(2026, 3, 5));
    });
  });

  group('Invoice', () {
    test('names Eventor as the issuer and the provider apart', () {
      final Invoice invoice = Invoice.fromJson(invoiceJson());

      expect(invoice.issuer.name, 'Eventor (Symloop SARL)');
      expect(invoice.issuer.nif, '001216099999999');
      expect(invoice.provider.displayName, 'Studio Lumière');
      expect(invoice.client.displayName, 'Amina Benali');
      expect(invoice.eventType, EventType.wedding);
      expect(invoice.pdfReady, isTrue);
    });
  });

  group('BookingRequest', () {
    test('sends only the extras picked, and trims the free text', () {
      final BookingRequest request = BookingRequest(
        serviceId: 's-1',
        eventDate: DateTime(2026, 3, 14),
        startTime: '13:00',
        endTime: '23:00',
        guests: 150,
        extras: const <String, int>{'x-1': 2, 'x-2': 0},
        wilayaCode: 16,
        communeId: 'com-1',
        locationText: '  Salle Yasmine  ',
        eventType: EventType.wedding,
        clientNote: '   ',
      );

      final Map<String, Object?> json = request.toJson();

      expect(json['eventDate'], '2026-03-14');
      expect(json['extras'], <Map<String, Object?>>[
        <String, Object?>{'extraId': 'x-1', 'quantity': 2},
      ]);
      expect(json['locationText'], 'Salle Yasmine');
      expect(json.containsKey('clientNote'), isFalse);
      expect(json.containsKey('packId'), isFalse);
      expect(json['eventType'], 'wedding');
    });

    test('a pack never sends extras, and the quote leaves out the place', () {
      final BookingRequest request = BookingRequest(
        packId: 'k-1',
        eventDate: DateTime(2026, 3, 14),
        extras: const <String, int>{'x-1': 1},
        wilayaCode: 16,
        eventType: EventType.wedding,
      );

      expect(request.toJson().containsKey('extras'), isFalse);
      expect(request.toQuoteJson().containsKey('wilayaCode'), isFalse);
      expect(request.toQuoteJson()['packId'], 'k-1');
    });
  });
}
