import '../../models/account.dart';
import 'catalog_ref.dart';
import 'json_read.dart';
import 'pack.dart';
import 'service.dart';

/// Everything screen 11 shows, from one call.
class HomeFeed {
  const HomeFeed({
    required this.fullName,
    required this.unreadNotifications,
    required this.unreadConversations,
    required this.categories,
    required this.upcomingBookings,
    required this.budget,
    required this.packs,
    required this.nearbyServices,
    this.avatarUrl,
    this.wilaya,
  });

  factory HomeFeed.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? wilaya = readObject(json, 'wilaya');
    return HomeFeed(
      fullName: readString(json, 'fullName'),
      avatarUrl: readStringOrNull(json, 'avatarUrl'),
      wilaya: wilaya == null ? null : Wilaya.fromJson(wilaya),
      unreadNotifications: readInt(json, 'unreadNotifications'),
      unreadConversations: readInt(json, 'unreadConversations'),
      categories: readList(json, 'categories', CategoryWithCount.fromJson)
        ..sort(
          (CategoryWithCount a, CategoryWithCount b) =>
              a.position.compareTo(b.position),
        ),
      upcomingBookings:
          readList(json, 'upcomingBookings', UpcomingBooking.fromJson),
      budget: BudgetSummary.fromJson(
        readObject(json, 'budget') ?? const <String, Object?>{},
      ),
      packs: readList(json, 'packs', PackCard.fromJson),
      nearbyServices: readList(json, 'nearbyServices', ServiceCard.fromJson),
    );
  }

  final String fullName;
  final String? avatarUrl;

  /// The city on the header pill; `null` when the client never chose one, and
  /// then [nearbyServices] covers every wilaya.
  final Wilaya? wilaya;
  final int unreadNotifications;
  final int unreadConversations;
  final List<CategoryWithCount> categories;

  /// The next two.
  final List<UpcomingBooking> upcomingBookings;
  final BudgetSummary budget;

  /// Best saving first.
  final List<PackCard> packs;

  /// Best rated first, in [wilaya].
  final List<ServiceCard> nearbyServices;
}

class UpcomingBooking {
  const UpcomingBooking({
    required this.id,
    required this.reference,
    required this.providerName,
    required this.eventDate,
    required this.status,
    this.title,
    this.category,
    this.startTime,
  });

  factory UpcomingBooking.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? category = readObject(json, 'category');
    return UpcomingBooking(
      id: json['id']! as String,
      reference: readString(json, 'reference'),
      providerName: readString(json, 'providerName'),
      title: readStringOrNull(json, 'title'),
      category: category == null ? null : CategoryRef.fromJson(category),
      eventDate: readDate(json, 'eventDate'),
      startTime: readStringOrNull(json, 'startTime'),
      status: readString(json, 'status'),
    );
  }

  final String id;

  /// `EVT-000123`.
  final String reference;
  final String providerName;
  final String? title;
  final CategoryRef? category;
  final DateTime eventDate;

  /// `"13:00"`.
  final String? startTime;

  /// `pending | accepted | declined | cancelled | completed`.
  final String status;
}

/// The budget card on Home — or, with [exists] false, the invitation to
/// create one (11c).
class BudgetSummary {
  const BudgetSummary({
    required this.exists,
    required this.spentTotal,
    required this.totalAmount,
    required this.spentPercent,
    required this.bookedCount,
    required this.itemsCount,
  });

  factory BudgetSummary.fromJson(Map<String, Object?> json) => BudgetSummary(
        exists: readBool(json, 'exists'),
        spentTotal: readString(json, 'spentTotal'),
        totalAmount: readString(json, 'totalAmount'),
        spentPercent: readNum(json, 'spentPercent'),
        bookedCount: readInt(json, 'bookedCount'),
        itemsCount: readInt(json, 'itemsCount'),
      );

  final bool exists;
  final String spentTotal;
  final String totalAmount;

  /// 0–100, and above 100 when over budget.
  final num spentPercent;
  final int bookedCount;
  final int itemsCount;
}
