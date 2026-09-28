import '../../../features/auth/data/documents_repository.dart';
import '../../bookings/models/booking_card.dart';
import '../../catalog/models/json_read.dart';
import '../../catalog/models/price_type.dart';

/// Which home a provider sees — the API's `state`.
enum ProviderHomeState {
  /// 21: the full home.
  verified,

  /// 21a: documents missing or in review.
  pending,

  /// 21b: at least one document was refused.
  rejected,

  /// 21c: the account was blocked by an admin — services hidden, chats
  /// read-only, no request can be answered.
  blocked;

  static ProviderHomeState fromApi(String? value) => switch (value) {
        'verified' => verified,
        'rejected' => rejected,
        'blocked' => blocked,
        _ => pending,
      };
}

/// One step of 21a/21b's "Profile under review" checklist.
enum VerificationStepKey {
  accountCreated,
  documentsSubmitted,
  underReview,
  approved;

  static VerificationStepKey? fromApi(String? value) => switch (value) {
        'account_created' => accountCreated,
        'documents_submitted' => documentsSubmitted,
        'under_review' => underReview,
        'approved' => approved,
        _ => null,
      };
}

class VerificationStep {
  const VerificationStep({
    required this.key,
    required this.done,
    required this.current,
  });

  final VerificationStepKey key;
  final bool done;

  /// The step the review is on now; at most one is.
  final bool current;
}

/// The three counters under 21's header.
class ProviderCounts {
  const ProviderCounts({
    this.requests = 0,
    this.upcoming = 0,
    this.services = 0,
    this.unreadMessages = 0,
    this.unreadNotifications = 0,
  });

  factory ProviderCounts.fromJson(Map<String, Object?> json) => ProviderCounts(
        requests: readInt(json, 'requests'),
        upcoming: readInt(json, 'upcoming'),
        services: readInt(json, 'services'),
        unreadMessages: readInt(json, 'unreadMessages'),
        unreadNotifications: readInt(json, 'unreadNotifications'),
      );

  final int requests;
  final int upcoming;
  final int services;
  final int unreadMessages;
  final int unreadNotifications;
}

/// Where one of the provider's services stands — `draft|published|hidden`.
enum ProviderServiceStatus {
  draft,
  published,
  hidden;

  static ProviderServiceStatus fromApi(String? value) => switch (value) {
        'published' => published,
        'hidden' => hidden,
        _ => draft,
      };
}

/// A row of 21's "Your services".
class ProviderServiceRow {
  const ProviderServiceRow({
    required this.id,
    required this.title,
    required this.status,
    required this.basePrice,
    required this.coverUrl,
    this.priceType = PriceType.perEvent,
  });

  factory ProviderServiceRow.fromJson(Map<String, Object?> json) =>
      ProviderServiceRow(
        id: json['id']! as String,
        title: LocalizedText.read(json, 'title'),
        status: ProviderServiceStatus.fromApi(json['status'] as String?),
        basePrice: readString(json, 'basePrice'),
        coverUrl: readStringOrNull(json, 'coverUrl'),
        priceType: PriceType.fromApi(json['priceType'] as String?),
      );

  final String id;
  final LocalizedText title;
  final ProviderServiceStatus status;

  /// The API's money string.
  final String basePrice;
  final String? coverUrl;

  /// The row's unit — "per day" (since 2026-09-27).
  final PriceType priceType;
}

/// Screens 21, 21a and 21b from one `GET /app/provider/home`.
class ProviderHome {
  const ProviderHome({
    required this.state,
    required this.businessName,
    required this.steps,
    required this.documents,
    required this.acceptingBookings,
    required this.counts,
    required this.requests,
    required this.upcoming,
    required this.services,
  });

  factory ProviderHome.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? documents = readObject(json, 'documents');
    return ProviderHome(
      state: ProviderHomeState.fromApi(json['state'] as String?),
      businessName: readString(json, 'businessName'),
      steps: <VerificationStep>[
        for (final Map<String, Object?> step
            in readList(json, 'verificationSteps', (Map<String, Object?> s) => s))
          if (VerificationStepKey.fromApi(step['key'] as String?)
              case final VerificationStepKey key)
            VerificationStep(
              key: key,
              done: readBool(step, 'done'),
              current: readBool(step, 'current'),
            ),
      ],
      documents:
          documents == null ? null : ProviderDocuments.fromJson(documents),
      acceptingBookings: readBool(json, 'acceptingBookings'),
      counts: ProviderCounts.fromJson(
        readObject(json, 'counts') ?? const <String, Object?>{},
      ),
      requests: readList(json, 'requests', BookingCard.fromJson),
      upcoming: readList(json, 'upcoming', BookingCard.fromJson),
      services: readList(json, 'services', ProviderServiceRow.fromJson),
    );
  }

  final ProviderHomeState state;
  final String businessName;
  final List<VerificationStep> steps;

  /// Only while the account is not verified.
  final ProviderDocuments? documents;
  final bool acceptingBookings;
  final ProviderCounts counts;

  /// Pending requests, newest first.
  final List<BookingCard> requests;

  /// The next accepted bookings.
  final List<BookingCard> upcoming;
  final List<ProviderServiceRow> services;

  bool get isVerified => state == ProviderHomeState.verified;
  bool get isBlocked => state == ProviderHomeState.blocked;

  ProviderHome copyWith({bool? acceptingBookings}) => ProviderHome(
        state: state,
        businessName: businessName,
        steps: steps,
        documents: documents,
        acceptingBookings: acceptingBookings ?? this.acceptingBookings,
        counts: counts,
        requests: requests,
        upcoming: upcoming,
        services: services,
      );
}
