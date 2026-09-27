import '../../models/account.dart';
import 'catalog_ref.dart';
import 'json_read.dart';
import 'pack.dart';
import 'review.dart';
import 'service.dart';

/// A provider as embedded in every service and pack — the card's "by …".
class ProviderSummary {
  const ProviderSummary({
    required this.id,
    required this.businessName,
    required this.verified,
    required this.avgRating,
    required this.ratingCount,
    required this.completedBookingsCount,
    required this.acceptingBookings,
    this.category,
    this.avatarUrl,
    this.yearsActive,
    this.replyTime,
  });

  factory ProviderSummary.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? category = readObject(json, 'category');
    return ProviderSummary(
      id: json['id']! as String,
      businessName: readString(json, 'businessName'),
      category: category == null ? null : CategoryRef.fromJson(category),
      avatarUrl: readStringOrNull(json, 'avatarUrl'),
      verified: readBool(json, 'verified'),
      avgRating: readString(json, 'avgRating'),
      ratingCount: readInt(json, 'ratingCount'),
      completedBookingsCount: readInt(json, 'completedBookingsCount'),
      yearsActive: readIntOrNull(json, 'yearsActive'),
      replyTime: readStringOrNull(json, 'replyTime'),
      // A provider that says nothing is taking bookings: hiding the booking
      // button on a missing field would be the worse failure.
      acceptingBookings: json['acceptingBookings'] as bool? ?? true,
    );
  }

  final String id;
  final String businessName;
  final CategoryRef? category;
  final String? avatarUrl;

  /// The "Verified provider" badge.
  final bool verified;

  /// `"4.80"`; `"0.00"` with no reviews — see [isRated].
  final String avgRating;
  final int ratingCount;
  final int completedBookingsCount;

  /// Years in business, not years on Eventor — the live value is 15 for an
  /// account created this year.
  final int? yearsActive;

  /// `"2 h"` — "Usually replies in 2 h". `null` until the server has enough
  /// history to say.
  final String? replyTime;

  /// `false` when the provider paused new bookings. Their services stay
  /// listed; only the booking button goes.
  final bool acceptingBookings;

  /// Whether anyone has reviewed them — an unrated provider shows "New", not
  /// zero stars.
  bool get isRated => ratingCount > 0;
}

/// One line of "What we checked".
class ProviderCheck {
  const ProviderCheck({
    required this.code,
    required this.title,
    required this.detail,
    required this.passed,
  });

  factory ProviderCheck.fromJson(Map<String, Object?> json) => ProviderCheck(
        code: readString(json, 'code'),
        title: readString(json, 'title'),
        detail: readString(json, 'detail'),
        passed: readBool(json, 'passed'),
      );

  /// `identity`, `registration`, `reply_time` live.
  final String code;

  /// Translated by the server, in the language of the request.
  final String title;
  final String detail;
  final bool passed;
}

/// Screen 13.
class ProviderDetail extends ProviderSummary {
  const ProviderDetail({
    required super.id,
    required super.businessName,
    required super.verified,
    required super.avgRating,
    required super.ratingCount,
    required super.completedBookingsCount,
    required super.acceptingBookings,
    required this.languagesSpoken,
    required this.wilayas,
    required this.checks,
    required this.servicesCount,
    required this.services,
    required this.packs,
    required this.ratingBreakdown,
    required this.recentReviews,
    required this.memberSince,
    super.category,
    super.avatarUrl,
    super.yearsActive,
    super.replyTime,
    this.bio,
  });

  factory ProviderDetail.fromJson(Map<String, Object?> json) {
    final ProviderSummary summary = ProviderSummary.fromJson(json);
    return ProviderDetail(
      id: summary.id,
      businessName: summary.businessName,
      category: summary.category,
      avatarUrl: summary.avatarUrl,
      verified: summary.verified,
      avgRating: summary.avgRating,
      ratingCount: summary.ratingCount,
      completedBookingsCount: summary.completedBookingsCount,
      yearsActive: summary.yearsActive,
      replyTime: summary.replyTime,
      acceptingBookings: summary.acceptingBookings,
      bio: LocalizedText.readOrNull(json, 'bio'),
      languagesSpoken: readStrings(json, 'languagesSpoken'),
      wilayas: readList(json, 'wilayas', Wilaya.fromJson),
      checks: readList(json, 'checks', ProviderCheck.fromJson),
      servicesCount: readInt(json, 'servicesCount'),
      services: readList(json, 'services', ServiceCard.fromJson),
      packs: readList(json, 'packs', PackCard.fromJson),
      ratingBreakdown: readList(json, 'ratingBreakdown', RatingBucket.fromJson),
      recentReviews: readList(json, 'recentReviews', Review.fromJson),
      memberSince: readDate(json, 'memberSince'),
    );
  }

  final LocalizedText? bio;

  /// Language codes — `["ar", "fr", "en"]`.
  final List<String> languagesSpoken;
  final List<Wilaya> wilayas;
  final List<ProviderCheck> checks;

  /// All their visible services; [services] holds at most ten of them.
  final int servicesCount;
  final List<ServiceCard> services;
  final List<PackCard> packs;
  final List<RatingBucket> ratingBreakdown;
  final List<Review> recentReviews;
  final DateTime memberSince;

  /// The profile lists at most ten services and nothing lists the rest.
  bool get hasMoreServices => services.length < servicesCount;
}
