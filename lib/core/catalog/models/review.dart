import 'json_read.dart';

class Review {
  const Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.redacted,
    required this.createdAt,
    this.authorAvatarUrl,
    this.reply,
  });

  factory Review.fromJson(Map<String, Object?> json) => Review(
        id: json['id']! as String,
        authorName: readString(json, 'authorName'),
        authorAvatarUrl: readStringOrNull(json, 'authorAvatarUrl'),
        rating: readInt(json, 'rating'),
        comment: readString(json, 'comment'),
        redacted: readBool(json, 'redacted'),
        reply: readStringOrNull(json, 'reply'),
        createdAt: readDate(json, 'createdAt'),
      );

  final String id;

  /// First name and initial — "Yasmine K."
  final String authorName;
  final String? authorAvatarUrl;

  /// 1 to 5.
  final int rating;

  /// Already redacted by the server when [redacted] is set.
  final String comment;
  final bool redacted;

  /// The provider's published answer.
  final String? reply;
  final DateTime createdAt;
}

/// One bar of a rating breakdown — the API always sends all five, 5 to 1.
class RatingBucket {
  const RatingBucket({
    required this.stars,
    required this.count,
    required this.percent,
  });

  factory RatingBucket.fromJson(Map<String, Object?> json) => RatingBucket(
        stars: readInt(json, 'stars'),
        count: readInt(json, 'count'),
        percent: readNum(json, 'percent'),
      );

  final int stars;
  final int count;
  final num percent;
}
