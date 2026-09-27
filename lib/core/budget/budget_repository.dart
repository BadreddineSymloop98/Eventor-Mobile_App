import '../errors/failure.dart';
import '../network/api_client.dart';
import 'models/budget.dart';

export 'models/budget.dart';

/// The budget's header — what 18a creates and 18f replaces.
class BudgetPlan {
  const BudgetPlan({
    required this.title,
    required this.eventDate,
    required this.totalAmount,
  });

  final String title;
  final DateTime? eventDate;

  /// The API's money string, `"400000.00"`.
  final String totalAmount;

  Map<String, Object?> toJson() => <String, Object?>{
        'title': title,
        'eventDate': eventDate == null ? null : apiDate(eventDate!),
        'totalAmount': totalAmount,
      };
}

/// An expense line as 18d / 18b submit it.
class BudgetItemInput {
  const BudgetItemInput({
    required this.categoryId,
    required this.label,
    required this.plannedAmount,
    required this.spentAmount,
    required this.bookingId,
  });

  final String? categoryId;
  final String label;
  final String plannedAmount;
  final String spentAmount;
  final String? bookingId;

  Map<String, Object?> toJson() => <String, Object?>{
        'categoryId': categoryId,
        'label': label,
        'plannedAmount': plannedAmount,
        'spentAmount': spentAmount,
        'bookingId': bookingId,
      };

  /// Only what differs from [item] — the PATCH the API asks for. A cleared
  /// category or booking goes out as an explicit `null`.
  Map<String, Object?> changesFrom(BudgetItem item) => <String, Object?>{
        if (categoryId != item.category?.id) 'categoryId': categoryId,
        if (label != item.label) 'label': label,
        if (plannedAmount != item.plannedAmount) 'plannedAmount': plannedAmount,
        if (spentAmount != item.spentAmount) 'spentAmount': spentAmount,
        if (bookingId != item.bookingId) 'bookingId': bookingId,
      };
}

/// `2026-03-14` — the API's date, from a local day.
String apiDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// The client's one budget and its lines. Every write answers with the whole
/// budget recomputed, so the screen never adds anything up itself.
abstract interface class BudgetRepository {
  /// `null` until the client has created one.
  Future<Budget?> get();

  /// Creates the budget the first time, replaces its header after.
  Future<Budget> save(BudgetPlan plan);

  /// Throws `BUDGET_ITEM_LIMIT` when the budget is full — see [itemLimit].
  Future<Budget> addItem(BudgetItemInput input);

  /// Sends only what changed from [item]. Unchanged, it does not call.
  Future<Budget> updateItem(BudgetItem item, BudgetItemInput input);

  Future<Budget> deleteItem(String id);

  /// Deletes the budget and its lines; linked bookings are not touched. A
  /// budget that is already gone counts as deleted.
  ///
  /// Not on the live API yet (backend issues, item 15): until it is, this
  /// throws `ROUTE_NOT_FOUND`.
  Future<void> delete();

  /// How many lines a budget may hold, once the server has said — it only
  /// does when an add is refused. `null` until then.
  int? get itemLimit;
}

/// Learns the line limit from a refused add. Shared by the live and mock
/// repositories so both learn it the same way.
mixin BudgetItemLimitMemory {
  int? _itemLimit;
  int _lastItemsCount = 0;

  int? get itemLimit => _itemLimit;

  /// Every budget that comes back passes through here, so a refusal can be
  /// dated against the latest count.
  Budget remember(Budget budget) {
    _lastItemsCount = budget.itemsCount;
    return budget;
  }

  /// Runs [add]; a `BUDGET_ITEM_LIMIT` records the limit before it is
  /// rethrown. The server's `{max}` when it sends one, else the count it
  /// refused at.
  Future<Budget> learningLimit(Future<Budget> Function() add) async {
    try {
      return remember(await add());
    } on ApiFailure catch (failure) {
      if (failure.code == ApiErrorCode.budgetItemLimit) {
        final Object? max = failure.details?['max'];
        _itemLimit = max is num ? max.toInt() : _lastItemsCount;
      }
      rethrow;
    }
  }
}

/// [BudgetRepository] against the live API.
class ApiBudgetRepository with BudgetItemLimitMemory implements BudgetRepository {
  ApiBudgetRepository(this._api);

  final ApiClient _api;
  static const String _path = '/app/me/budget';

  @override
  Future<Budget?> get() async {
    try {
      return remember(_parse(await _api.get(_path)));
    } on ApiFailure catch (failure) {
      if (failure.code == ApiErrorCode.budgetNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<Budget> save(BudgetPlan plan) async =>
      remember(_parse(await _api.put(_path, body: plan.toJson())));

  @override
  Future<Budget> addItem(BudgetItemInput input) => learningLimit(
        () async => _parse(await _api.post('$_path/items', body: input.toJson())),
      );

  @override
  Future<Budget> updateItem(BudgetItem item, BudgetItemInput input) async {
    final Map<String, Object?> changes = input.changesFrom(item);
    if (changes.isEmpty) {
      final Budget? current = await get();
      if (current != null) return current;
    }
    return remember(
      _parse(await _api.patch('$_path/items/${item.id}', body: changes)),
    );
  }

  @override
  Future<Budget> deleteItem(String id) async =>
      remember(_parse(await _api.delete('$_path/items/$id')));

  @override
  Future<void> delete() async {
    try {
      await _api.delete(_path);
    } on ApiFailure catch (failure) {
      if (failure.code != ApiErrorCode.budgetNotFound) rethrow;
    }
  }

  static Budget _parse(Object? data) =>
      Budget.fromJson(data! as Map<String, Object?>);
}
