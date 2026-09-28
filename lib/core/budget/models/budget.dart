import '../../catalog/models/catalog_ref.dart';
import '../../catalog/models/json_read.dart';
import '../../formatting/money_format.dart';

/// The client's one budget — screen 18. Amounts are the API's strings,
/// `"400000.00"`, and stay strings: the server does the sums.
class Budget {
  const Budget({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.totalAmount,
    required this.plannedTotal,
    required this.spentTotal,
    required this.remaining,
    required this.spentPercent,
    required this.itemsCount,
    required this.bookedCount,
    required this.items,
  });

  factory Budget.fromJson(Map<String, Object?> json) => Budget(
        id: json['id']! as String,
        title: readString(json, 'title'),
        eventDate: readDateOrNull(json, 'eventDate'),
        totalAmount: readString(json, 'totalAmount'),
        plannedTotal: readString(json, 'plannedTotal'),
        spentTotal: readString(json, 'spentTotal'),
        remaining: readString(json, 'remaining'),
        spentPercent: readNum(json, 'spentPercent'),
        itemsCount: readInt(json, 'itemsCount'),
        bookedCount: readInt(json, 'bookedCount'),
        // The server's order is `position`; sorted here too so a mock or a
        // future change cannot shuffle the list.
        items: readList(json, 'items', BudgetItem.fromJson)
          ..sort((BudgetItem a, BudgetItem b) => a.position.compareTo(b.position)),
      );

  final String id;
  final String title;
  final DateTime? eventDate;

  /// The plan — "of 400 000 DA planned".
  final String totalAmount;

  /// What the lines add up to — "380 000 DA allocated across 6 lines".
  final String plannedTotal;
  final String spentTotal;

  /// [totalAmount] − [spentTotal]; negative once over budget (18g).
  final String remaining;

  /// 0–100, and above 100 when over budget.
  final num spentPercent;
  final int itemsCount;

  /// Lines linked to a booking — "3 of 6".
  final int bookedCount;
  final List<BudgetItem> items;

  bool get isOverBudget => amountCents(remaining) < 0;

  /// The lines promise more than the total — visible before any of it is
  /// spent.
  bool get isOverAllocated => amountCents(plannedTotal) > amountCents(totalAmount);
}

/// One expense line.
class BudgetItem {
  const BudgetItem({
    required this.id,
    required this.category,
    required this.label,
    required this.plannedAmount,
    required this.spentAmount,
    required this.bookingId,
    required this.bookingReference,
    required this.providerName,
    required this.position,
  });

  factory BudgetItem.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? category = readObject(json, 'category');
    return BudgetItem(
      id: json['id']! as String,
      category: category == null ? null : CategoryRef.fromJson(category),
      label: readString(json, 'label'),
      plannedAmount: readString(json, 'plannedAmount'),
      spentAmount: readString(json, 'spentAmount'),
      bookingId: readStringOrNull(json, 'bookingId'),
      bookingReference: readStringOrNull(json, 'bookingReference'),
      providerName: readStringOrNull(json, 'providerName'),
      position: readInt(json, 'position'),
    );
  }

  final String id;
  final CategoryRef? category;
  final String label;
  final String plannedAmount;

  /// Typed by the client — linking a booking does not fill it.
  final String spentAmount;
  final String? bookingId;
  final String? bookingReference;

  /// The linked booking's provider; `null` reads "Not booked yet".
  final String? providerName;
  final int position;

  bool get isBooked => bookingId != null;
}
