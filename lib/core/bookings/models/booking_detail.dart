import '../../models/account.dart' show Wilaya;
import '../../catalog/models/json_read.dart';
import '../../catalog/models/pack.dart' show EventType;
import '../../catalog/models/provider.dart';
import 'booking_card.dart';

/// What a priced line is — the API's `lines[].kind`.
enum BookingLineKind {
  service,
  extra,
  packService,
  discount,
  adjustment;

  static BookingLineKind fromApi(String? value) => switch (value) {
        'extra' => extra,
        'pack_service' => packService,
        'discount' => discount,
        'adjustment' => adjustment,
        _ => service,
      };
}

/// One priced line of a quote, a booking or an invoice.
class BookingLine {
  const BookingLine({
    required this.kind,
    required this.label,
    required this.quantity,
    required this.unitAmount,
    required this.amount,
  });

  factory BookingLine.fromJson(Map<String, Object?> json) => BookingLine(
        kind: BookingLineKind.fromApi(json['kind'] as String?),
        label: readString(json, 'label'),
        quantity: readInt(json, 'quantity'),
        unitAmount: readString(json, 'unitAmount'),
        amount: readString(json, 'amount'),
      );

  final BookingLineKind kind;

  /// Already in the caller's language.
  final String label;
  final int quantity;
  final String unitAmount;

  /// Negative on a [BookingLineKind.discount] line.
  final String amount;
}

/// A step of B4's timeline — the API's `timeline[]`.
enum TimelineEntryType {
  created,
  pending,
  accepted,
  declined,
  cancelled,
  completed,
  rescheduled,
  checkedIn,
  disputeOpened;

  static TimelineEntryType? fromApi(String? value) => switch (value) {
        'created' => created,
        'pending' => pending,
        'accepted' => accepted,
        'declined' => declined,
        'cancelled' => cancelled,
        'completed' => completed,
        'rescheduled' => rescheduled,
        'checked_in' => checkedIn,
        'dispute_opened' => disputeOpened,
        _ => null,
      };
}

class TimelineEntry {
  const TimelineEntry({
    required this.type,
    required this.at,
    this.actorLabel,
    this.reason,
  });

  final TimelineEntryType type;
  final DateTime at;

  /// "Yasmine K." — who moved it, when the server says.
  final String? actorLabel;
  final String? reason;
}

/// Where a reschedule proposal stands.
enum RescheduleStatus {
  pending,
  accepted,
  rejected,
  cancelled;

  static RescheduleStatus fromApi(String? value) => switch (value) {
        'accepted' => accepted,
        'rejected' => rejected,
        'cancelled' => cancelled,
        _ => pending,
      };
}

/// One proposal to move the event — B6 sends one, B6a answers one.
class Reschedule {
  const Reschedule({
    required this.id,
    required this.status,
    required this.oldDate,
    required this.newDate,
    required this.reason,
    required this.proposedByClient,
    required this.awaitingMe,
    this.newStartTime,
    this.newEndTime,
    this.createdAt,
  });

  factory Reschedule.fromJson(Map<String, Object?> json) => Reschedule(
        id: json['id']! as String,
        status: RescheduleStatus.fromApi(json['status'] as String?),
        oldDate: readDate(json, 'oldDate'),
        newDate: readDate(json, 'newDate'),
        newStartTime: readStringOrNull(json, 'newStartTime'),
        newEndTime: readStringOrNull(json, 'newEndTime'),
        // Typed `object` in the spec but a string in every example.
        reason: json['reason'] is String ? json['reason']! as String : '',
        proposedByClient: json['proposedByRole'] == 'client',
        awaitingMe: readBool(json, 'awaitingMe'),
        createdAt: readDateOrNull(json, 'createdAt'),
      );

  final String id;
  final RescheduleStatus status;
  final DateTime oldDate;
  final DateTime newDate;
  final String? newStartTime;
  final String? newEndTime;
  final String reason;
  final bool proposedByClient;

  /// It is this caller's turn to accept or refuse it — B6a.
  final bool awaitingMe;

  /// When it was proposed.
  final DateTime? createdAt;

  bool get isPending => status == RescheduleStatus.pending;
}

/// The invoice as the detail summarises it — issued on acceptance.
class InvoiceSummary {
  const InvoiceSummary({
    required this.number,
    required this.total,
    required this.voided,
  });

  factory InvoiceSummary.fromJson(Map<String, Object?> json) => InvoiceSummary(
        number: readString(json, 'number'),
        total: readString(json, 'total'),
        voided: readBool(json, 'voided'),
      );

  final String number;
  final String total;
  final bool voided;
}

/// The booking's dispute, when it has one.
class BookingDisputeSummary {
  const BookingDisputeSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.conversationId,
  });

  factory BookingDisputeSummary.fromJson(Map<String, Object?> json) =>
      BookingDisputeSummary(
        id: json['id']! as String,
        reference: readString(json, 'reference'),
        status: readString(json, 'status'),
        conversationId: readStringOrNull(json, 'conversationId'),
      );

  final String id;

  /// `DSP-000012`.
  final String reference;

  /// `open | in_review | resolved | closed`.
  final String status;
  final String? conversationId;

  bool get isOpen => status == 'open' || status == 'in_review';
}

/// B4 and its variants — the API's `AppBookingDetailDto`, as the client
/// reads it.
class BookingDetail {
  const BookingDetail({
    required this.card,
    required this.lines,
    required this.subtotal,
    required this.discountTotal,
    required this.timeline,
    required this.reschedules,
    this.eventTypeValue,
    this.wilaya,
    this.guests,
    this.locationText,
    this.communeName,
    this.clientNote,
    this.cancellationPolicy,
    this.cancelReason,
    this.cancelledByClient = false,
    this.declineReason,
    this.provider,
    this.providerPhone,
    this.conversationId,
    this.invoice,
    this.dispute,
    this.checkedIn = false,
    this.otherCheckedIn = false,
    this.reviewId,
    this.reviewWindowOpen = false,
    this.disputeWindowOpen = false,
  });

  factory BookingDetail.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? wilaya = readObject(json, 'wilaya');
    final Map<String, Object?>? provider = readObject(json, 'provider');
    final Map<String, Object?>? invoice = readObject(json, 'invoice');
    final Map<String, Object?>? dispute = readObject(json, 'dispute');
    final Map<String, Object?> party =
        readObject(json, 'counterparty') ?? const <String, Object?>{};
    return BookingDetail(
      card: BookingCard.fromJson(json),
      eventTypeValue: readStringOrNull(json, 'eventType'),
      wilaya: wilaya == null ? null : Wilaya.fromJson(wilaya),
      guests: readIntOrNull(json, 'guests'),
      locationText: readStringOrNull(json, 'locationText'),
      communeName: readStringOrNull(json, 'communeName'),
      clientNote: readStringOrNull(json, 'clientNote'),
      lines: readList(json, 'lines', BookingLine.fromJson),
      subtotal: readString(json, 'subtotal'),
      discountTotal: readString(json, 'discountTotal'),
      cancellationPolicy: readStringOrNull(json, 'cancellationPolicy'),
      cancelReason: readStringOrNull(json, 'cancelReason'),
      cancelledByClient: json['cancelledBy'] == 'client',
      declineReason: readStringOrNull(json, 'declineReason'),
      provider: provider == null ? null : ProviderSummary.fromJson(provider),
      providerPhone: readStringOrNull(party, 'phone'),
      conversationId: readStringOrNull(json, 'conversationId'),
      timeline: <TimelineEntry>[
        for (final Map<String, Object?> e
            in readList(json, 'timeline', (Map<String, Object?> e) => e))
          if (TimelineEntryType.fromApi(e['type'] as String?)
              case final TimelineEntryType type)
            TimelineEntry(
              type: type,
              at: readDateOrNull(e, 'at') ?? DateTime(1970),
              actorLabel: readStringOrNull(e, 'actorLabel'),
              reason: readStringOrNull(e, 'reason'),
            ),
      ],
      reschedules: readList(json, 'reschedules', Reschedule.fromJson),
      invoice: invoice == null ? null : InvoiceSummary.fromJson(invoice),
      dispute: dispute == null ? null : BookingDisputeSummary.fromJson(dispute),
      checkedIn: readBool(json, 'checkedIn'),
      otherCheckedIn: readBool(json, 'otherCheckedIn'),
      reviewId: readStringOrNull(json, 'reviewId'),
      reviewWindowOpen: readBool(json, 'reviewWindowOpen'),
      disputeWindowOpen: readBool(json, 'disputeWindowOpen'),
    );
  }

  /// Everything the list card carries: id, reference, status, date, times,
  /// title, category, total, provider name, allowed actions.
  final BookingCard card;
  final String? eventTypeValue;
  final Wilaya? wilaya;
  final int? guests;
  final String? locationText;
  final String? communeName;
  final String? clientNote;
  final List<BookingLine> lines;
  final String subtotal;
  final String discountTotal;

  /// The provider's own words — shown, never enforced (payment is cash).
  final String? cancellationPolicy;
  final String? cancelReason;
  final bool cancelledByClient;
  final String? declineReason;

  /// `null` on a pack whose provider was deleted.
  final ProviderSummary? provider;

  /// Only once the booking is accepted.
  final String? providerPhone;
  final String? conversationId;

  /// Oldest first.
  final List<TimelineEntry> timeline;
  final List<Reschedule> reschedules;
  final InvoiceSummary? invoice;
  final BookingDisputeSummary? dispute;

  /// This client tapped "All good" after the event.
  final bool checkedIn;

  /// The provider did.
  final bool otherCheckedIn;
  final String? reviewId;
  final bool reviewWindowOpen;
  final bool disputeWindowOpen;

  String get id => card.id;
  String get status => card.status;
  EventType? get eventType => card.eventType;
  bool get isPack => card.category == null && lines.any(
        (BookingLine l) => l.kind == BookingLineKind.packService,
      );
  bool can(BookingAction action) => card.can(action);

  /// The proposal waiting on this client — B6a.
  Reschedule? get proposalForMe {
    for (final Reschedule r in reschedules) {
      if (r.isPending && r.awaitingMe) return r;
    }
    return null;
  }

  /// This client's own proposal, still unanswered.
  Reschedule? get myPendingProposal {
    for (final Reschedule r in reschedules) {
      if (r.isPending && !r.awaitingMe) return r;
    }
    return null;
  }
}

/// Why a quote refuses its date — `unavailableReason`.
enum QuoteRefusal {
  dateUnavailable,
  minNotice,
  providerNotAccepting;

  static QuoteRefusal? fromApi(String? value) => switch (value) {
        'DATE_UNAVAILABLE' => dateUnavailable,
        'MIN_NOTICE' => minNotice,
        'PROVIDER_NOT_ACCEPTING' => providerNotAccepting,
        _ => null,
      };
}

/// `POST /app/bookings/quote` — the price and whether the date can be booked,
/// before anything is written.
class BookingQuote {
  const BookingQuote({
    required this.lines,
    required this.subtotal,
    required this.discountTotal,
    required this.total,
    required this.available,
    required this.firstBookableDate,
    this.refusal,
  });

  factory BookingQuote.fromJson(Map<String, Object?> json) => BookingQuote(
        lines: readList(json, 'lines', BookingLine.fromJson),
        subtotal: readString(json, 'subtotal'),
        discountTotal: readString(json, 'discountTotal'),
        total: readString(json, 'total'),
        available: json['available'] as bool? ?? true,
        refusal: QuoteRefusal.fromApi(json['unavailableReason'] as String?),
        firstBookableDate: readDateOrNull(json, 'firstBookableDate'),
      );

  final List<BookingLine> lines;
  final String subtotal;
  final String discountTotal;
  final String total;
  final bool available;
  final QuoteRefusal? refusal;
  final DateTime? firstBookableDate;
}

/// A party on the invoice.
class InvoiceParty {
  const InvoiceParty({
    required this.name,
    this.businessName,
    this.email,
    this.phone,
  });

  factory InvoiceParty.fromJson(Map<String, Object?> json) => InvoiceParty(
        name: readString(json, 'name'),
        businessName: readStringOrNull(json, 'businessName'),
        email: readStringOrNull(json, 'email'),
        phone: readStringOrNull(json, 'phone'),
      );

  final String name;
  final String? businessName;
  final String? email;
  final String? phone;

  String get displayName =>
      businessName != null && businessName!.isNotEmpty ? businessName! : name;
}

/// Who issues the invoice — Eventor, with its legal identifiers.
class InvoiceIssuer {
  const InvoiceIssuer({
    required this.name,
    required this.address,
    required this.nif,
    required this.rc,
    required this.email,
    required this.phone,
  });

  factory InvoiceIssuer.fromJson(Map<String, Object?> json) => InvoiceIssuer(
        name: readString(json, 'name'),
        address: readString(json, 'address'),
        nif: readString(json, 'nif'),
        rc: readString(json, 'rc'),
        email: readString(json, 'email'),
        phone: readString(json, 'phone'),
      );

  final String name;
  final String address;

  /// Tax id (numéro d'identification fiscale).
  final String nif;

  /// Trade register number.
  final String rc;
  final String email;
  final String phone;
}

/// B8 — `GET /app/bookings/{id}/invoice`.
class Invoice {
  const Invoice({
    required this.number,
    required this.bookingReference,
    required this.issuedAt,
    required this.issuer,
    required this.client,
    required this.provider,
    required this.title,
    required this.eventDate,
    required this.lines,
    required this.subtotal,
    required this.discountTotal,
    required this.total,
    required this.pdfReady,
    this.eventType,
  });

  factory Invoice.fromJson(Map<String, Object?> json) => Invoice(
        number: readString(json, 'number'),
        bookingReference: readString(json, 'bookingReference'),
        issuedAt: readDateOrNull(json, 'issuedAt') ?? DateTime(1970),
        issuer: InvoiceIssuer.fromJson(
          readObject(json, 'issuer') ?? const <String, Object?>{},
        ),
        client: InvoiceParty.fromJson(
          readObject(json, 'client') ?? const <String, Object?>{},
        ),
        provider: InvoiceParty.fromJson(
          readObject(json, 'provider') ?? const <String, Object?>{},
        ),
        title: LocalizedText.read(json, 'title'),
        eventDate: readDate(json, 'eventDate'),
        eventType: json['eventType'] == null
            ? null
            : EventType.fromApi(json['eventType'] as String?),
        lines: readList(json, 'lines', BookingLine.fromJson),
        subtotal: readString(json, 'subtotal'),
        discountTotal: readString(json, 'discountTotal'),
        total: readString(json, 'total'),
        pdfReady: readBool(json, 'pdfReady'),
      );

  /// `INV-2026-0318`.
  final String number;
  final String bookingReference;
  final DateTime issuedAt;
  final InvoiceIssuer issuer;
  final InvoiceParty client;
  final InvoiceParty provider;
  final LocalizedText title;
  final DateTime eventDate;
  final EventType? eventType;
  final List<BookingLine> lines;
  final String subtotal;
  final String discountTotal;
  final String total;

  /// The PDF can be downloaded — Share / Download.
  final bool pdfReady;
}
